module CucuShift
  # @note this class represents an OpenShift master server that is running
  #   Kubernetes Services like Scheduler, Registration, etc.
  class Master
  # @param host [CucuShift::Host] a mashine
    def initialize(host, opts={})
      @host = host
    end

    def restart_master_service()
      @result = @host.exec_admin("systemctl status atomic-openshift-master")
      unless @result[:success] && @result[:response].include?("active (running)")
        raise "something already wrong with node service, failing early on #{@host.hostname}"
      end

      @result = @host.exec_admin("systemctl restart atomic-openshift-master")
      unless @result[:success]
        raise "could not restart master service on #{@host.hostname}"
      end

      sleep 15 # give service some time to fail
      @result = @host.exec_admin("systemctl status atomic-openshift-master")
      unless @result[:success] && @result[:response].include?("active (running)")
        raise "master service not running on #{@host.hostname}"
      end
    end
  end
end
