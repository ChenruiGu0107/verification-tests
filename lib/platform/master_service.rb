require 'http'

module CucuShift
  module Platform
    # @note this class represents an OpenShift master server that is running
    #   Kubernetes Services like API and Controller
    class MasterService < OpenShiftService
      include Common::Helper

      attr_reader :env

      IMPLEMENTATIONS = [MasterSystemdService, MasterScriptedStaticPodService]

      def self.type(host)
        IMPLEMENTATIONS.find { |i| i.detected_on?(host) }
      end

      def initialize(host, env)
        super(host)
        @env = env
      end

      def config
        @config ||= CucuShift::Platform::MasterConfig.new(self)
      end

      private def expected_load_time
        controller_lease_ttl + 5
      end

      private def controller_lease_ttl
        @controller_lease_ttl ||= config.as_hash["controllerLeaseTTL"] || 30
      end

      private def local_api_port
        @local_api_port ||= config.as_hash.dig("servingInfo", "bindAddress").split(":").last
      end

      private def api_url
        @api_url ||= "https://#{host.hostname}:#{local_api_port}"
      end

      private def wait_start
        res = {}
        success = wait_for(expected_load_time, interval: 5) {
          (res = Http.get(url: api_url))[:success]
        }
        return res
      end

      def start(**opts)
        CucuShift::ResultHash.aggregate_results([super, wait_start])
      end

      def restart(**opts)
        super
        # no better idea than hardcoding time needed for node to react on master restart command
        sleep 10
        CucuShift::ResultHash.aggregate_results([super, wait_start])
      end
    end
  end
end
