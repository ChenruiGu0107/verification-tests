#!/usr/bin/env ruby
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")

"""
Utility to execute simple CucuShift workflow test over a polarion server.
"""

require 'thread'
require 'commander'

require 'common'
require 'polarion/polarion'

module CucuShift
  module Polarion
    class CucuWorkflow
      include Commander::Methods
      include Common::Helper

      COMMAND_NAME = File.basename(__FILE__)
      TEST_RUN_TEMPLATE = "auto-test-run-poc-template"

      def initialize
        always_trace!
      end

      def run
        program :name, 'Polarion Workflow tester'
        program :version, '0.0.1'
        program :description, 'Tool to validate CucuShift automation workflow'

        #Commander::Runner.instance.default_command(:gui)
        default_command :help

        #global_option('-s', '--service KEY', 'service name to look for in configuration')

        command :"generate-test-data" do |c|
          c.syntax = "#{COMMAND_NAME} generate-test-data [options]"
          c.description = 'generate test cases and test run template in project'
          c.option('-p', '--project PROJECT', "the project to create them in")
          c.option('-c', '--count COUNT', "the number of test cases to generate")
          c.option('--case-name-prefix PREFIX', "string to use as prefix for new test case names")
          c.option('-m', '--matching MATCHING', "target number of test cases to match by the test run template")
          c.option('--tag-num TAG_NUM', "max number of tags used in total")
          c.option('-t', '--case-tags CASE_TAGS', "how many tags should each test case have")
          c.action do |args, options|
            puts options.tag_num
            @project = options.project
            count_cases = Integer(options.count) rescue 100
            count_matching = Integer(options.matching) rescue 42
            count_tags = Integer(options.case_tags) rescue 12
            total_tags = Integer(options.tag_num) rescue 97

            # will overwrite existing template if it was already created
            create_test_run_template

            # will fail if case already exists
            count_cases.times do |i|
              case rand(count_cases)
              when 1..count_matching
                tags = generate_random_matching_tags(count_tags, total_tags)
              else
                tags = generate_random_tags(count_tags, total_tags)
              end

              tc = create_test_case("Auto generated for PoC - #{i}", tags: tags)
              logger.error("Failed to create case ##{i}: #{tc.fault}") if tc.fault
            end
          end
        end

        command :"execute-tests" do |c|
          c.syntax = "#{COMMAND_NAME} execute-tests [options]"
          c.description = 'simulates test case execution'
          c.option('-p', '--project PROJECT', "the project to create them in")
          c.option('-c', '--count COUNT', "the number of concurrent executors")
          c.option('--test-template TEMPLATE', "the template to create run")
          c.option('--test-run-name NAME', "the name or created test run")
          c.action do |args, options|
            @project = options.project
            count_executors = Integer(options.count) rescue 5
            say "using #{count_executors} executors"

            # create new testrun
            tr_uri = create_test_run(options.test_run_name, options.test_run_template)
            say "Created Test Run: #{tr_uri}"
            work_queue = Queue.new
            executors = []
            finished_executors = []
            failed_executors = []
            timeout = 5 * 24 * 60 * 60 # 5 days
            stats = {}

            executor_proc = proc {
              executor!(
                async_client,
                tr_uri,
                work_queue,
              )
            }
            count_executors.times { |i|
              executors << Thread.new(&executor_proc)
              # we have plenty of time before this variable is used
              executors[-1].thread_variable_set(:num, i)
            }

            # use executor_proc.call if you want to pry inside it
            finished = wait_for(timeout, stats: stats) do
              say "executors: #{executors.size} running, #{finished_executors.size} finished, #{failed_executors.size} failed"
              executors.delete_if do |thread|
                begin
                  finished_executors << thread if thread.join(5)
                rescue
                  failed_executors << thread
                end
              end
              executors.empty?
            end

            say "finished with executors: #{executors.size} running, #{finished_executors.size} finished, #{failed_executors.size} failed"

            say "ERRORS below:" unless failed_executors.empty?
            failed_executors.each do |t|
              begin
                t.join
              rescue => e
                say exception_to_string(e)
              end
            end

            unless finished
              executors.each { |t| t.terminate }
              raise "we didn't finish within timeout"
            end

            # TODO: summarize results based on work_queue
            # TODO: verify end state of all test records
          end
        end

        run!
      end

      # @param worklog [Queue] to log useful metrics
      def executor!(client, tr_uri, worklog)
        tr = nil
        records = nil
        tr_hash = nil

        get_run = proc do
          tr = client.test.get_test_run_by_uri(uri: tr_uri)
          if tr.fault || !testrun_exists?(tr)
            puts tr.body.to_xml
            raise "error getting TestRun #{tr_uri}"
          end
          tr_hash = tr.body_hash
          records = tr_hash["getTestRunByUriReturn"]["records"]["TestRecord"]
        end

        get_run.call
        tr_id = tr_uri.sub(/^.+}/, "")
        pr_uri = tr_hash["getTestRunByUriReturn"]["projectURI"]
        pr_id = pr_uri.sub(/^.+}/, "")

        # get required fields for cases in the run
        sql = sql_get_workitems_from_run(tr_id, pr_id)
        cases = client.tracker.query_work_items_by_sql(sql_query: sql, fields: ["id", "customFields.caseautomation", "customFields.automation_script"])
        work_items = cases.body_hash["queryWorkItemsBySQLReturn"]

        if records.size != work_items.size
          raise "count of test records is #{records.size} but found #{work_items.size} workitems"
        end

        # while we find unreserved case, reserve them and mark them complete
        while rec_idx = records.find_index {|r| r["duration"].nil?}
          rec = records[rec_idx]
          tc_uri = rec["testCaseURI"]
          tc_id = tc_uri.sub(/^.+}/, "")
          unless work_items.find {|c| c["id"] == tc_id}
            raise "cannot find case data: #{tc_id}"
          end

          reserve_duration = rand(1.0..2.0).round(6).to_s
          res_rec = client.deep_snake(rec)
          res_req = {
            test_run_uri: tr_uri,
            index: rec_idx,
            test_record: res_rec
          }
          res_rec.delete(:test_step_results)
          res_rec[:duration] = reserve_duration
          res_rec[:comment] = { type: "text/plain",
                                content_lossy: "false",
                                content: "reserved by: #{EXECUTOR_NAME}"}

          client.test.update_test_record_at_index(**res_req)

          # TODO: make sleep depend on call response times
          sleep 5

          # check if we get the reservation
          get_run.call
          rec = records[rec_idx]

          if rec["duration"] == reserve_duration
            say "executor #{Thread.current.thread_variable_get(:num)} executing #{tc_id}"

            # sleep some time to simulate test execution
            sleep 15

            # verify we still hold the reservation
            get_run.call
            rec = records[rec_idx]
            if rec["duration"] != reserve_duration
              raise "we lost the reservation of #{tc_id}"
            end

            res_rec[:executed] = Time.now.iso8601
            res_rec[:executed_by_uri] = client.self_uri
            res_rec[:comment][:content] += "\ncompleted"
            res_rec[:result] = {id: "passed"}

            client.test.update_test_record_at_index(**res_req)

            # TODO: update worklog
          else
            say "skipping #{tc_id}, duration: #{rec["duration"]}, expected: #{reserve_duration}"
          end
        end

        if Thread.current == Thread.main
          require 'pry'
          binding.pry
        end
      end

      def create_test_case(name, tags: "", automated: "automated")
        tc = {
          content: {
            project: {
              uri: @project_uri
            },
            created: Time.now.iso8601,
            description: {
              type: "text/plain",
              content: "AOS QE Rock,\n" + name,
              content_lossy: "false"
            },
            title: name,
            type: {id: "testcase"},
            custom_fields: {
              custom: [
                {key: "tags", value: tags},
                {key: "caseautomation", value: {id: automated}},
                {key: "automation_script", value: {
                  type: "text/plain",
                  content: generate_auto_script,
                  contentLossy: "false"}
                }
              ]
            }
          }
        }
        polarion.tracker.create_work_item(**tc)
      end

      # we hardcode name, lets overwrite it if it exists
      def create_test_run_template(testrun_template_id = nil)
        tr_id = testrun_template_id || TEST_RUN_TEMPLATE
        tr_uri = polarion.testrun_uri(tr_id, @project)

        ## create empty run
        tr = polarion.test.get_test_run_by_id(project: @project, id: tr_id)
        if (tr.body.elements.first.attributes["unresolvable"].value == "true" rescue true)
          tr = polarion.test.create_test_run(project: @project, id: tr_id)
          raise "cannot create run: #{tr.fault}" if tr.fault
        end

        ## edit run to become a template
        trt_hash = {
          content: {
            uri: tr_uri,
            is_template: "true",
            query: run_template_expression,
            select_test_cases_by: {id: "staticQueryResult"},
            #type: {id: "featureverification"},
            custom_fields: {custom: [{key: "isautomated", value: "true"}]}
          }
        }
        trt = polarion.test.update_test_run(**trt_hash)
        raise "cannot update run: #{trt.fault}" if trt.fault
      end

      # @return [String] URI of new test run
      def create_test_run(testrun_id = nil, template_id = nil)
        trt_id = template_id || TEST_RUN_TEMPLATE
        tr_id = testrun_id || trt_id.sub(/[-_]?template$/, "") + "-#{rand_str(5, :dns)}"
        raise "specify testrun id" if tr_id == trt_id

        tr_uri = polarion.testrun_uri(tr_id, @project)

        # don't know how to delete or rename a testrun, create new one
        # tr = polarion.test.get_test_run_by_id(project: @project, id: tr_id)
        # if (tr.body.elements.first.attributes["unresolvable"].value == "true" rescue true)
        #  ## rename test run (dunno how to delete)
        #  tr_hash = {
        #    content: {
        #      uri: tr_uri,
        #      id: tr_id + "-" + rand_str(8, :dns),
        #      # status: { id: "notrun"},
        #      # template_uri: polarion.testrun_uri(trt_id, @project)
        #    }
        #  }
        #  tr = polarion.test.update_test_run(**tr_hash)
        #  raise "cannot create run: #{tr.fault}" if tr.fault
        # end

        ## create run from template
        tr = polarion.test.create_test_run(
          project: @project,
          id: tr_id,
          template: trt_id
        )
        raise "cannot create run: #{tr.fault}" if tr.fault
        return tr_uri
      end

      def testrun_exists?(resp)
        ! (resp.body.elements.first.attributes["unresolvable"].value == "true" rescue true)
      end

      def sql_get_workitems_from_run(run_id, project_id)
        return <<-eof
          select
            WORKITEM.C_URI
          from
            WORKITEM inner join PROJECT
              on WORKITEM.FK_URI_PROJECT = PROJECT.C_URI
          where
            PROJECT.C_ID = '#{project_id}' AND
            WORKITEM.C_TYPE = 'testcase' AND
            WORKITEM.C_URI = ANY(array(
              select
                TESTRECORD.FK_URI_TESTCASE
              from
                STRUCT_TESTRUN_RECORDS TESTRECORD inner join TESTRUN TESTRUN
                  on TESTRECORD.FK_P_TESTRUN = TESTRUN.C_PK
              where
                TESTRUN.C_ID = '#{run_id}'
            ))
        eof

        ## TODO, possible optimizations:
        #        TESTRECORD.C_DURATION = <REAL> AND
        #        TESTRECORD.C_COMMENT = <VARCHAR> AND
        #        TESTRECORD.C_RESULT = 'failed' AND
        #        TESTRECORD.C_EXECUTED > '2012-05-14 00:00:00' AND
        #        TESTRECORD.C_EXECUTED < '2012-05-20 00:00:00'
      end

      # @return [String] random script/arguments case parameter
      def generate_auto_script
        script = {ruby: "test/#{rand_str(5,:dns)}.feature"}
        if rand(100) < 30
          script[:args] = {
            image: rand_str(8,:dns),
            regexp: rand_str(10)
          }
        end

        return script
      end

      def generate_random_tags(num, max, min: 0)
        tags = []
        while tags.size < num
          tags = tags | [ rand(min..max) ]
        end

        # support up to 100 total tags with 2 digit padding
        tags.map {|t| "tag" + t.to_s.rjust(2, "0")}
      end

      def generate_random_matching_tags(num, max)
        raise "you're kidding me" if num < 5

        tags = generate_random_tags(num, max)

        (tags & ["tag01", "tag02"]).empty? && tags << ["tag01", "tag02"].sample
        tags = tags | ["tag05", "tag06"]
        tags = tags - ["tag03", "tag04"]

        while tags.size > num
          s = tags.sample
          tags.delete(s) unless ["tag01", "tag02", "tag05", "tag06"].include?(s)
        end

        while tags.size < num
          tags = tags | generate_random_tags(num - tags.size, max, min: 7)
        end

        return tags
      end

      def test_tags
        num = 15
        max = 97
        tags = generate_random_matching_tags(num, max)
        valid_tags = (max+1).times.map { |i| "tag" + i.to_s.rjust(2, "0") }
        invalid_tags = tags - valid_tags

        raise "size = #{tags.size}" if tags.size != num
        raise "invalid tags #{invalid_tags}" unless invalid_tags.empty?
        raise "no 1 or 2 tag" if (["tag01", "tag02"] - tags).size > 1
        raise "no 5 and 6 tag" unless (["tag05", "tag06"] - tags).empty?
        raise "3 or 4 tag" if (["tag03", "tag04"] - tags).size < 2
      end

      # this is some example tag expression, tried to be complicated enough
      def run_template_expression
        # 'tags contain "tag05" and tags contain "tag06" and (tags contain "tag01" || tags contain "tag02") and not (tags contain "tag03") || tags contain "tag04")'
        'tags:(contain "tag05") AND tags:(contain "tag06") AND ( tags:(contain "tag01") OR tags:(contain "tag02")) AND NOT (tags:(contain "tag03") OR tags:(contain "tag04"))'
      end

      def polarion
        unless @polarion
          @polarion = Connector.new
          at_exit do
            @polarion.logout
          end
        end
        return @polarion
      end

      def async_client
        cl = polarion.new_client
        at_exit do
          cl.logout
        end
        return cl
      end
    end
  end
end

if __FILE__ == $0
  CucuShift::Polarion::CucuWorkflow.new.run
end
