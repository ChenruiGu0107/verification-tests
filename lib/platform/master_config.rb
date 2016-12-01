require 'yaml'

module CucuShift
  module Platform
    # class which interacts with the master-config.yaml file on the master(s) of the openshift instalation.
    class MasterConfig < OpenShiftConfig

      def initialize(host, node)
        super
        @config_file_path = "/etc/origin/master/master-config.yaml"
      end
    end
  end
end
