module CucuShift
  module Platform
    class OpenShiftService
      attr_reader :service, :host
      private :service

      def initialize(host)
        @host = host
      end

      def start(**opts)
        service.start(**opts)
      end

      def stop(**opts)
        service.stop(**opts)
      end

      def restart(**opts)
        service.restart(**opts)
      end
    end
  end
end
