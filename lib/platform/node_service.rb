module CucuShift
  module Platform
    class NodeService < OpenShiftService

      def initialize(host, env)
        super
        @services = ["atomic-openshift-node.service"]
      end

      def schedulable?
        @schedulable ||= env.nodes.select { |n| n.schedulable? if n.host.hostname == host.hostname }.length
        return @schedulable == 1
      end

      def config
        @config ||= CucuShift::Platform::NodeConfig.new(host, self)
      end
    end
  end
end
