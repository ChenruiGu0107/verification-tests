require 'yaml'

module CucuShift
  module Platform
    # class to help operation over node-config.yaml file on the OpenShift nodes
    class NodeConfig < OpenShiftConfig
      def initialize(service)
        super
        @config_file_path = "/etc/origin/node/node-config.yaml"
      end
    end
  end
end
