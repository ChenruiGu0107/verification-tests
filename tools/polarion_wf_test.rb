#!/usr/bin/env ruby
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")

'''
Utility to execute simple CucuShift workflow test over a polarion server.

There are some pre-requisites for the project under testing:
* Test Case Workitem should have custom multi-line field automation_script
* Test Case Workitem should have custom enumeration field caseautomation with
  values "notautomated", "manualonly" and "automated"

For automated use set user and password in private/config/config.yaml or
  set env variables POLARION_USER and POLARION_PASSWORD

# clone repo and install dependencies if needed
cd cucushift
bundle check || bundle install --gemfile=tools/Gemfile
sudo dnf install rubygem-nokogiri # installing from gem requires additional native deps
gem install lolsoap # nokogiri an lolsoap install procedure not ironed out yet

# see help
tools/polarion_wf_test.rb -h

# create test template and sample test cases
tools/polarion_wf_test.rb generate-test-data -p <project id> -c <num cases to create> -m <num cases to match template>

# create run and simulate executors fighting for executing test cases
tools/polarion_wf_test.rb execute-tests -p <project id> -c <num executors>
'''

require 'commander'
require 'thread'
require 'yaml'

require 'common'
require 'polarion/polarion'
require 'polarion/polarion_tc_manager'

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

        command :fiddle do |c|
          c.syntax = "#{__FILE__} fiddle"
          c.description = 'enter a pry shell to play with API'
          c.action do |args, options|
            require 'pry'
            binding.pry
          end
        end

        command :"generate-test-data" do |c|
          c.syntax = "#{COMMAND_NAME} generate-test-data [options]"
          c.description = 'generate test cases and test run template in project'
          c.option('-p', '--project PROJECT', "the project to create them in")
          c.option('-c', '--count COUNT', "the number of test cases to generate")
          c.option('--case-name-prefix PREFIX', "string to use as prefix for new test case names")
          c.option('-m', '--matching MATCHING', "target number of test cases to match by the test run template")
          c.option('--tag-num TAG_NUM', "max number of tags used in total")
          c.option('-t', '--case-tags CASE_TAGS', "how many tags should each test case have (must be 5 or more)")
          c.action do |args, options|
            puts options.tag_num
            @project = options.project
            @project_uri = polarion.project_uri(@project)
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
              tags = tags.join(" ")

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
          c.option('--from-template TEMPLATE', "the template to create run")
          c.option('--test-run-name NAME', "the name for created test run")
          c.action do |args, options|
            @project = options.project
            @project_uri = polarion.project_uri(@project)
            count_executors = Integer(options.count) rescue 5
            say "using #{count_executors} executors"

            # create new testrun
            if options.from_template != "false"
              tr_uri = create_test_run(options.test_run_name, options.from_template)
            elsif options.test_run_name
              tr_uri = polarion.testrun_uri(options.test_run_name, @project)
            else
              raise "specify test-run-name when you want to use existing"
            end

            say "Created Test Run: #{tr_uri}"
            work_queue = Queue.new
            executors = []
            finished_executors = []
            failed_executors = []
            timeout = 5 * 24 * 60 * 60 # 5 days
            stats = {}

            executor_proc = proc {
              begin
                executor!(
                  async_client,
                  tr_uri,
                  work_queue,
                )
              rescue => e
                logger.error "critical error in #{executor_str()}\n" +
                  exception_to_string(e)
                redo
              end
            }
            count_executors.times { |i|
              executors << Thread.new(&executor_proc)
              # we have plenty of time before this variable is used
              executors[-1].thread_variable_set(:num, i)
            }
            all_executors = executors.dup

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

            # check for duplicate execution and whether all were executed
            executed_cases = all_executors.map{|t|t.thread_variable_get(:cases)}
            executed_num = executed_cases.reduce(0) {|m,c| m + c[:cases].size }
            executed_cases.each_with_index do |cases, index|
              executed_cases[0...index].each do |other_cases|
                common_cases = other_cases[:cases] & cases[:cases]
                unless common_cases.empty?
                  executed_num - common_cases.size
                  logger.error "Executor #{cases[:executor]} and #{other_cases[:executor]} both executed #{common_cases}"
                end
              end
            end
            if executed_num != executed_cases.first[:seen].size
              logger.error "executed total cases #{executed_num} but should have been #{executed_cases.first[:seen].size}"
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
        executor_str = EXECUTOR_NAME
        if Thread.current.thread_variable_get(:num)
          executor_str += "-#{Thread.current.thread_variable_get(:num)}"
        end

        manager = TCManager.new(client, executor_name: executor_str)
        run = manager.get_run(uri: tr_uri)
        work_items = manager.get_automation_data_for_run(run)

        cases_log = Thread.current.thread_variable_get(:cases)
        if cases_log
          executed_cases = cases_log[:cases]
          seen_cases = cases_log[:seen]
        else
          executed_cases = []
          seen_cases = Set.new
          cases_log = {type: :cases, executor: executor_str,
                       cases: executed_cases, seen: seen_cases}
          Thread.current.thread_variable_set(:cases, cases_log)
        end

        # while we find unreserved case, reserve them and mark them complete
        run.records.size.times do |i|
          rec = run.records[i]
          seen_cases << rec.workitem_id
          unless work_items.find { |c| c["id"] == rec.workitem_id }
            raise "cannot find case data: #{rec.workitem_id}"
          end

          logger.info "#{executor_str()} reserving #{rec.workitem_id}"
          next unless manager.reserve_test_record(rec)
          executed_cases << rec.workitem_id
          sleep 15 # it takes 15 seconds to execute imaginary test cases
          rec_update = {
            duration: rand(1.0..603.0).round(6).to_s,
            comment: {
              type: "text/plain",
              content_lossy: "false",
              content: "executed by: #{EXECUTOR_NAME} #{executor_str()}"
            },
            result: {id: "passed"},
            executed_by_uri: client.self_uri,
            executed: Time.now.iso8601
          }

          logger.info "#{executor_str()} setting #{rec.workitem_id} completion status"
          manager.update_test_record(rec, rec_update)

            # TODO: update worklog
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
                  content_lossy: "false"}
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

      # @return [String] random script/arguments case parameter
      def generate_auto_script
        script = {ruby: "test/#{rand_str(5,:dns)}.feature"}
        if rand(100) < 30
          script[:args] = {
            image: rand_str(8,:dns),
            regexp: rand_str(10)
          }
        end

        return script.to_yaml
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

      def executor_str
        "executor #{Thread.current.thread_variable_get(:num)}"
      end
    end
  end
end

if __FILE__ == $0
  CucuShift::Polarion::CucuWorkflow.new.run
end
