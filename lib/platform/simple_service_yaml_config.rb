require 'yaml'

module CucuShift
  module Platform
    # class to help operations over master-config.yaml file on the masters
    class SimpleServiceYAMLConfig
      attr_reader :config_file, :service

      def initialize(service, config_file_path)
        @service = service
        @config_file = YAMLRestorableFile.new(
          service.host,
          config_file_path
        )
      end

      def as_hash
        config_file.as_hash
      end

      def merge!(update)
        config_file.merge!(update)
      end

      def restore
        config_file.restore
        apply
      end

      def apply
        service.restart
      end
    end
  end
end
