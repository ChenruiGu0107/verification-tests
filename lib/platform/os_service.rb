module CucuShift
  module Platform
    # Class which represents a generic openshift service running on a host
    class OpenShiftService

      attr_reader :host, :env, :controller_lease_ttl, :services

      def initialize(host, env)
        @host = host
        @env = env
      end

      # Will restart the provided service. If the process fails it will raise an error
      # @param service [String] name of the service running on the host
      def restart(service, **opts)
        raise "No service provided to restart!" unless service
        results = []
        result = host.exec_admin("systemctl status #{service}")
        results.push(result)
        if opts[:raise]
          unless result[:success] && result[:response].include?("active (running)")
            raise "something already wrong with node service #{service}, failing early on #{host.hostname}"
          end
        end

        result = host.exec_admin("systemctl restart #{service}")
        results.push(result)
        if opts[:raise]
          unless result[:success]
            raise "could not restart node service #{service} on #{host.hostname}"
          end
        end

        if controller_lease_ttl.nil?
          sleep 35 # give service some time to fail
        else
          sleep controller_lease_ttl + 5
        end

        result = host.exec_admin("systemctl status #{service}")
        results.push(result)
        if opts[:raise]
          unless result[:success] && result[:response].include?("active (running)")
            raise "node service #{service} not running on #{host.hostname}"
          end
        end

        return CucuShift::ResultHash.aggregate_results(results)
      end


      # Wrapper mehod which executes #restart on each of the services configured.
      def restart_all(**opts)
        results = []
        services.each { |service|
          results.push(restart(service, opts))
        }
        return CucuShift::ResultHash.aggregate_results(results)
      end

    end
  end
end
