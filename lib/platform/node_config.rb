require 'yaml'

module CucuShift
  module Platform
    # class which interacts with the node-config.yaml file on the node(s) of the openshift instalation.
    class NodeConfig < OpenShiftConfig

      def initialize(host, service)
        super
        @config_file_path = "/etc/origin/node/node-config.yaml"
      end
    end
  end
end
