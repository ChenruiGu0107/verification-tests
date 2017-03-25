require 'yaml'

module CucuShift
  module Platform
    # class to help operations over master-config.yaml file on the masters
    class MasterConfig < OpenShiftConfig
      def initialize(service)
        super
        @config_file_path = "/etc/origin/master/master-config.yaml"
      end
    end
  end
end
