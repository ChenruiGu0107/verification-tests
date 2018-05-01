module CucuShift
  module Platform
    class NodeService < OpenShiftService

      def self.discover(host)
        self.new(host)
      end

      def initialize(host)
        super
        @service = SystemdService.new("atomic-openshift-node.service", host)
      end

      def config
        @config ||= CucuShift::Platform::NodeConfig.new(self)
      end
    end
  end
end
