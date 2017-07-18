module CucuShift
  module Platform
    # Class which represents a generic openshift service running on a host
    class OpenShiftService
      include Common::BaseHelper

      attr_reader :host, :services

      def initialize(host)
        @host = host
      end

      def status(service, quiet: false)
        statuses = {
          active: "active \\(running\\)",
          inactive: "inactive"
        }

        # interesting whether `systemctl is-active svc` is better
        result = host.exec_admin("systemctl status #{service}", quiet: quiet)
        if result[:response].include? "Active:"
          result[:success] = true
        else
          raise "could not execute systemctl:\n#{result[:response]}"
        end

        statuses.keys.each do |key|
          if result[:response] =~ /Active:.*#{statuses[key]}/
            result[:status] = key
            return result
          end
        end
        result[:status] = :unknown
        return result
      end

      def logger
        host.logger
      end

      # Will restart the provided service.
      # @param opts [Hash] see supported options below
      #   :raise [Boolean] raise if restart fails
      # @param service [String] name of the service running on the host
      def restart(service, **opts)
        raise "No service provided to restart!" unless service
        results = []
        logger.info "before restart status of service #{service} on " \
          "#{host.hostname} is: #{status(service, quiet: true)[:status]}"

        result = host.exec_admin("systemctl restart #{service}")
        results.push(result)
        unless result[:success]
          if opts[:raise]
            raise "could not restart service #{service} on #{host.hostname}"
          end
          return CucuShift::ResultHash.aggregate_results(results)
        end

        ## this below seems to not make much sense
        #terminal_statuses = [:active, :inactive]
        #stable_status = wait_for(120) {
        #  result = status(service, quiet: true)
        #  terminal_statuses.include? result[:status]
        #}
        #results.push(result)
        #
        #unless stable_status
        #  # the `:raise` option is not respected here because unless service
        #  #   reach some stable status, we can't say for sure whether
        #  #   restart failed or not (it could be just too slow)
        #  raise CucuShift::TimeoutError,
        #    "service #{service} on #{host.hostname} never reached " \
        #    "a stable status:\n#{result[:response]}"
        #end
        #
        #if result[:status] == :active
          sleep expected_load_time
          result = status(service)
          results.push(result)
          unless result[:status] == :active
            result[:success] = false
            err_msg = "service #{service} on #{host.hostname} died after " \
              "#{expected_load_time} seconds"
            if opts[:raise]
              raise err_msg
            else
              logger.warn err_msg
            end
          end
        #else
        #  result[:success] = false
        #  err_msg = "service #{service} on #{host.hostname} could not be" \
        #    "activated:\n#{result[:response]}"
        #  if opts[:raise]
        #    raise CucuShift::TimeoutError, err_msg
        #  else
        #    logger.warn err_msg
        #  end
        #end

        return CucuShift::ResultHash.aggregate_results(results)
      end

      def expected_load_time
        20
      end

      # executes #restart on each of the services configured.
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
