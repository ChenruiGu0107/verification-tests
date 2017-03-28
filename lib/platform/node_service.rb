module CucuShift
  module Platform
    class NodeService < OpenShiftService

      def initialize(host)
        super
        @services = ["atomic-openshift-node.service"]
      end

      def config
        @config ||= CucuShift::Platform::NodeConfig.new(self)
      end
    end
  end
end
