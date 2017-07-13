# frozen_string_literal: true

require 'openshift/pod_replicator'

module CucuShift

  # represents an OpenShift DeploymentConfig (dc for short) used for scaling pods
  class DeploymentConfig < PodReplicator

    RESOURCE = 'deploymentconfigs'
    STATUSES = %i[waiting running succeeded failed complete].freeze
    REPLICA_COUNTERS = {
      desired: %w[spec replicas].freeze,
      current: %w[status replicas].freeze,
    }.freeze

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that can change at any time like status and spec
    def update_from_api_object(dc_hash)
      m = dc_hash["metadata"]
      props[:spec] = dc_hash["spec"]
      props[:status] = dc_hash["status"]
      props[:uid] = m["uid"]
      props[:labels] = m["labels"]
      props[:created] = m["creationTimestamp"] # already [Time]

      super(dc_hash)
    end

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

    def replicas(user:, cached: false, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user,
                             cached: cached, quiet: quiet)
      return spec["replicas"]
    end

    def available_replicas(user:, cached: false, quiet: false)
      status = get_cached_prop(prop: :status, user: user,
                             cached: cached, quiet: quiet)

      if status["availableReplicas"]
        # OCP 3.3 and later
        return status["availableReplicas"]
      else
        # OCP 3.2 and earlier
        res = describe(user, quiet: quiet)
        raise "cannot describe dc #{name}" unless res[:success]
        return res[:parsed][:replicas_status][:current].to_i
      end
    end

    # avilablity check only exists in 3.3, and oc describe doesn't have that
    # information prior, so we can't use the same logic to check for that info
    def unavailable_replicas(user:, cached: false, quiet: false)
      status = get_cached_prop(prop: :status, user: user,
                             cached: cached, quiet: quiet)

      if status["unavailableReplicas"]
        # OCP 3.3 and later
        return status["unavailableReplicas"]
      end
    end

    def strategy(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return spec['strategy']
    end

    def selector(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return spec['selector']
    end

    def triggers(user:, cached: false, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return spec['triggers']
    end

    # return specific trigger matched by type, please note cached is default to false
    def trigger_params(user:, type:, cached: false, quiet: false)
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
    def last_image_for_trigger(user:, type:, cached: false, quiet: false)
      return  trigger_params(user:user, type: "ImageChange")['lastTriggeredImage']
    end

    def template(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return spec['template']
    end

  end
end
