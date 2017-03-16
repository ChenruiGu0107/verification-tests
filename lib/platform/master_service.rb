module CucuShift
  module Platform
    # @note this class represents an OpenShift master server that is running
    #   Kubernetes Services like Scheduler, Registration, etc.
    class MasterService < OpenShiftService

      def services
        @services ||= if ha?
          config_hash = config.as_hash()
          @controller_lease_ttl = config_hash["controllerLeaseTTL"]
          @services = ["atomic-openshift-master-api.service", "atomic-openshift-master-controllers.service"]
        else
          @services = ["atomic-openshift-master"]
        end
      end

      def config
        @config ||= CucuShift::Platform::MasterConfig.new(host, self)
      end

      def ha?
       @ha ||= host.exec_admin("systemctl | grep atomic-openshift-master-controllers.service")[:success]
      end
    end
  end
end
