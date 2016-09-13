require 'ownthat'
require_relative 'polarion'
require_relative 'polarion_test_run'
require_relative 'polarion_test_record'

module CucuShift
  module Polarion
    class TCManager
      include Common::Helper

      attr_reader :polarion, :opts
      private :polarion, :opts

      def initialize(connection = nil, ownthat: nil, **opts)
        @polarion = connection || Connector.new
        @opts = (conf[:services, :polarion, :manager] || {}).merge(opts)
        @opts.freeze
        @ownthat = ownthat
      end

      private def ownthat
        @ownthat ||= OwnThat.new
      end

      def executor_name
        @executor_name ||= opts[:executor_name] || EXECUTOR_NAME
      end

      # @param tr [TestRun]
      # @param time [String] duration of the lock or time in ruby parsable
      #   format
      # @return [Boolean]
      def reserve_test_run(tr, time: "5m", &block)
        ownthat.reserve(
          polarion.send(:wsdl_base_url),
          tr.uri,
          time,
          executor_name,
          &block
        )
      end

      # @param tr [TestRecord]
      # @return [Boolean]
      def reserve_test_record(tr)
        if tr.runnable?
          return ownthat.reserve(
            polarion.send(:wsdl_base_url), # use url as namespace
            "#{tr.run.project_id} #{tr.run.id} #{tr.workitem_id}",
            "1d", # lock for one day, we can optimize later
            executor_name
          )
        else
          return false
        end
      end

      # @param tr [TestRecord]
      # @param opts [Hash] to be deep-merged into existing test record
      # @return undefined
      def update_test_record(tr, opts)
        update_rec_at_index(tr.to_modified_req(opts))
      end

      def get_run(uri: nil, id: nil, project_id: nil)
        err = nil
        tr  = nil
        got = wait_for(160, interval: 5) do
          begin
            if uri
              tr = polarion.test.get_test_run_by_uri(uri: uri)
            elsif id && project_id
              tr = polarion.test.get_test_run_by_id(project: project_id,
                                                  id: id)
            else
              logger.error "please specify URI or ID and PROJECT_ID"
              break
            end
          rescue => e
            err = e
            logger.warn "POLARION: #{executor_name()}: #{e.inspect}"
            false
          end
        end
        unless got
          raise err rescue raise "#{executor_name()} could not get #{uri} record 3m"
        end
        if tr.fault || !TCManager.resource_exists?(tr)
          logger.error "POLARION:\n" + tr.body.to_xml
          raise "error getting TestRun #{uri}"
        end
        return TestRun.new(tr)
      end

      # @param run [TestRun]
      # @return [Array] of Hash with specified fields of workitems from run
      def get_automation_data_for_run(run)
        sql = sql_get_workitems_from_run(run.id, run.project_id)
        cases = polarion.tracker.query_work_items_by_sql(
          sql_query: sql,
          fields: [
            "id",
            "customFields.caseautomation",
            "customFields.automation_script"
          ]
        )
        work_items = cases.body_hash["queryWorkItemsBySQLReturn"]

        if run.records.size != work_items.size
          raise "count of test records is #{run.records.size} but found #{work_items.size} workitems"
        end

        return work_items
      end

      def update_rec_at_index(request, retries: 5)
        retries.times do
          res = do_update_rec_at_index(request)
          return res if res
          sleep 10
        end
        raise "could not update test record"
      end

      def do_update_rec_at_index(request)
        return polarion.test.update_test_record_at_index(**request)
      rescue => e
        tc_id = request[:test_record][:test_case_uri].sub(/^.+}/, "")
        if PolarionCallError === e &&
            e.message.include?("ConcurrentModificationException")
          logger.info "POLARION: #{executor_name()}: case #{tc_id} " <<
            "concurrent modification"
        else
          logger.warn "POLARION: #{executor_name()}: case #{tc_id} unknown " <<
            "update error:\n" << exception_to_string(e)
        end
        return false
      end

      # chek SOAP response whether requested resource exists
      def self.resource_exists?(resp)
        ! (resp.body.elements.first.attributes["unresolvable"].value == "true" rescue true)
      end

      def sql_get_workitems_from_run(run_id, project_id)
=begin
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
=end
        return <<-eof
          select
            TESTRECORD.FK_URI_TESTCASE
          from
            PROJECT
          inner join
            TESTRUN
              on PROJECT.C_PK = TESTRUN.FK_PROJECT
          inner join
            STRUCT_TESTRUN_RECORDS TESTRECORD
              on TESTRUN.C_PK = TESTRECORD.FK_P_TESTRUN
          where
            PROJECT.C_ID = '#{project_id}' AND
            TESTRUN.C_ID = '#{run_id}'
        eof
=begin
        return <<-eof
          select
            FK_URI_TESTCASE
          from
            STRUCT_TESTRUN_RECORDS
          where
            FK_P_TESTRUN = (
              select
                C_PK
              from
                TESTRUN
              where
                FK_PROJECT = (
                  select C_PK from PROJECT where PROJECT.C_ID = '#{project_id}'
                )
              and
                TESTRUN.C_ID = '#{run_id}'
            )
        eof
=end
        ## TODO, other possible optimizations:
        #        TESTRECORD.C_DURATION = <REAL> AND
        #        TESTRECORD.C_COMMENT = <VARCHAR> AND
        #        TESTRECORD.C_RESULT = 'failed' AND
        #        TESTRECORD.C_EXECUTED > '2012-05-14 00:00:00' AND
        #        TESTRECORD.C_EXECUTED < '2012-05-20 00:00:00'
      end
    end
  end
end
