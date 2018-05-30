module CucuShift
  module Platform
    class NodeService < OpenShiftService

      def self.discover(host, env)
        self.new(host, env)
      end

      def initialize(host, env)
        super
        @service = SystemdService.new("atomic-openshift-node.service", host)
      end

      def config
        @config ||= CucuShift::Platform::NodeConfig.for(self)
      end
    end
  end
end
