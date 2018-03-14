# frozen_string_literal: true

require 'openshift/container_spec'
require 'openshift/pod_replicator'
require 'openshift/replication_controller'

module CucuShift

  # represents an OpenShift DeploymentConfig (dc for short) used for scaling pods
  class DeploymentConfig < PodReplicator
    RESOURCE = 'deploymentconfigs'
    STATUSES = %i[waiting running succeeded failed complete].freeze
    REPLICA_COUNTERS = {
      desired: %w[spec replicas].freeze,
      current: %w[status replicas].freeze,
      available: %w[status availableReplicas].freeze
    }.freeze

    # @param from_status [Symbol] the status we currently see
    # @param to_status [Array, Symbol] the status(es) we check whether current
    #   status can change to
    # @return [Boolean] true if it is possible to transition between the
    #   specified statuses (same -> same should return true)
    def status_reachable?(from_status, to_status)
      [to_status].flatten.include?(from_status) ||
        ![:failed, :succeeded].include?(from_status)
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if pod status is what's expected
    # @note TODO: can we just remove method and use [Resource#status?]
    def status?(user:, status:, quiet: false, cached: false)
      statuses = {
        waiting: "Waiting",
        running: "Running",
        succeeded: "Succeeded",
        failed: "Failed",
        complete: "Complete",
      }
      res = describe(user, quiet: quiet)
      if res[:success]
        status = [ status ].flatten
        overall_status = res[:parsed][:overall_status]
        res[:success] = status.any? {|s| statuses[s] == overall_status }
          res[:parsed][:overall_status] == statuses[status]
      end
      return res
    end

    # @return [CucuShift::ResultHash] with :success depending on status['replicas'] == spec['replicas']
    # @note at the moment we check how many running replicas we have, does it
    #   make more sense and is it reliable to just check :overall_status shown
    #   by the describe command with the `#status?` method?
    def ready?(user:, quiet: false)
      res = get(user: user, quiet: quiet)

      if res[:success]
        available = available_replicas(user: user, cached: true, quiet: true)
        res[:success] = (
          available > 0 &&
            replicas(user: user, cached: true, quiet: true) == available
        )
      end
      return res
    end

    # we define this in method_missing so alias can't fly
    # alias replicas desired_replicas
    def replicas(*args, &block)
      desired_replicas(*args, &block)
    end

    def available_replicas(user: nil, cached: false, quiet: false)
      if env.version_ge("3.3", user: user)
        return super(user: user, cached: cached, quiet: quiet)
      else
        res = describe(user, quiet: quiet)
        raise "cannot describe dc #{name}" unless res[:success]
        return res[:parsed][:replicas_status][:current].to_i
      end
    end

    def latest_version(user: nil, cached: false, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("status", "latestVersion")
    end

    # @return [CucuShift::ReplicationController[
    def replication_controller(user: nil, cached: true)
      version = latest_version(user: user, cached: cached, quiet: true)

      if props[:rc]&.name&.end_with?("-#{version}")
        return props[:rc]
      else
        rc_name = "#{name}-#{version}"
        props[:rc] = ReplicationController.new(name: rc_name, project: project)
        props[:rc].default_user = default_user(user)
        return props[:rc]
      end
    end
    alias rc replication_controller

    def replication_controller=(rc)
      props[:rc] = rc
    end
    alias rc= replication_controller=

    # availablity check only exists in 3.3, and oc describe doesn't have that
    # information prior, so we can't use the same logic to check for that info
    # @note only works with v3.3+
    def unavailable_replicas(user: nil, cached: false, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("status", "unavailableReplicas")
    end

    def strategy(user: nil, cached: true, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("spec", "strategy")
    end

    def selector(user: nil, cached: true, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("spec", "selector")
    end

    def triggers(user: nil, cached: false, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("spec", "triggers")
    end

    # return specific trigger matched by type, please note cached is default to false
    def trigger_params(user: nil, type:, cached: false, quiet: false)
      triggers = self.triggers(user: user, cached: cached, quiet: quiet)
      trigger = triggers.find {|t| t["type"] == type}
      case trigger["type"]
        when "ImageChange"
          index_key = "imageChangeParams"
        when "ConfigChange"
          index_key = "configChangeParams"
        else
          raise "Unsupported trigger type '#{type}' detected"
      end
      if trigger.has_key? index_key
        return trigger[index_key]
      else
        return {}
      end
    end

    # return the last triggered image
    def last_image_for_trigger(user: nil, type:, cached: false, quiet: false)
      return  trigger_params(user:user, type: "ImageChange")['lastTriggeredImage']
    end

    def revision_history_limit(user: nil, cached: true, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("spec", "revisionHistoryLimit")
    end

    # @return undefined
    # @raise on error
    def rollout_latest(user: nil, quiet: false)
      res = default_user(user).cli_exec(:rollout_latest,
                                              resource: "dc/#{name}",
                                              _quiet: quiet
                                             )
      unless res[:success]
        raise "could not redeploy dc #{name}" +
          quiet ? ":\n#{res[:response]}" : ", see log"
      end
    end
  end
end
