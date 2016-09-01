module CucuShift
  module Polarion
    class TestRecord
      attr_reader :run, :index

      # @param run [TestRun]
      # @param index [Integer]
      def initialize(run, index)
        @run = run
        @index = index
      end

      private def as_hash
        run.send(:record_hashes)[index]
      end

      def comment
        as_hash.dig("comment", "content")
      end

      def runnable?
        @runnable ||= !as_hash["result"] || as_hash["result"]["id"] == "rerun"
      end

      def obtained
        run.obtained
      end

      #def executed
      #  as_hash["executed"] # need parsed iso time
      #end

      #def duration
      #  as_hash["duration"] # need to float
      #end

      #def comment
      #  as_hash["comment"]
      #end

      # @return [Hash] suitable for calling `#update_test_record_at_index`
      def to_req
        @req ||= Collections.deep_freeze({
          test_run_uri: run.uri,
          index: index,
          test_record: Connector.deep_snake(as_hash)
        })
      end

      # @param opts [Hash] the updated test record fields (see WSDL structure)
      # @return [Hash] suitable for calling `#update_test_record_at_index`
      def to_modified_req(opts)
        req = to_req.dup
        req[:test_record] = Collections.deep_merge(req[:test_record], opts)
        return req
      end

      # return request to clear record status
      # {"attachments"=>"",
      #  "iteration"=>"-1",
      #  "signed"=>"false",
      #  "testCaseURI"=>
      #    "subterra:data-service:objects:/default/OSE${WorkItem}OSE-9167",
      #  "testCaseRevision"=>"756354",
      #  "testStepResults"=>""}
      def to_clean_state_req
        req = to_req.dup
        req[:test_record] = req[:test_record].dup
        allowed_keys = [:test_case_uri, :test_case_revision]
        req[:test_record].keys.each do |k|
          unless allowed_keys.include? k
            req[:test_record].delete(k)
          end
        end
        return req
      end

      def workitem_uri
        as_hash["testCaseURI"]
      end
      alias test_case_uri workitem_uri

      def workitem_id
        @workitem_id ||= workitem_uri.match(%r|\${WorkItem}(.*)$|)[1]
      end
      alias test_case_id workitem_id
    end
  end
end
