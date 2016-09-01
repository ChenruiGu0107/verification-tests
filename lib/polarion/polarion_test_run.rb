module CucuShift
  module Polarion
    class TestRun
      attr_reader :resp, :obtained
      private :resp

      def initialize(run_resp, obtained: Time.now)
        @resp = run_resp
        @obtained = obtained
      end

      def id
        @id ||= as_hash["getTestRunByUriReturn"]["id"]
      end

      def uri
        @uri ||= resp.body.elements.first.attributes["uri"].value
      end

      def project_id
        @project_id ||= project_uri.match(%r|default/(\w+)\${Project}|)[1]
      end

      def project_uri
        @project_uri ||= as_hash["getTestRunByUriReturn"]["projectURI"]
      end

      private def as_hash
        @tr_hash ||= resp.body_hash
      end

      private def record_hashes
        as_hash["getTestRunByUriReturn"]["records"]["TestRecord"]
      end

      def records
        @records ||= record_hashes.size.times.map do |i|
          TestRecord.new(self, i)
        end
      end
    end
  end
end
