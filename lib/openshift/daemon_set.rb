require 'openshift/pod_replicator'

module CucuShift
  # represnets an Openshift StatefulSets
  class DaemonSet < PodReplicator
    RESOURCE = "daemonsets"
    REPLICA_COUNTERS = {
      desired: %w[status desiredNumberScheduled].freeze,
      current: %w[status currentNumberScheduled].freeze,
      ready:   %w[status numberReady].freeze,
      updated_scheduled: %w[status updatedNumberScheduled].freeze,
      misscheduled: %w[status numberMisscheduled].freeze,
      available: %w[status numberAvailable].freeze,
    }.freeze

    # cache some usualy immutable properties for later fast use; do not cache
    # things that can change at any time like status and spec
    def update_from_api_object(hash)
      super

      m = hash["metadata"]
      s = hash["spec"]
      props[:uid] = m["uid"]
      props[:labels] = m["labels"]
      props[:annotations] = m["annotations"] # may change, use with care
      props[:created] = m["creationTimestamp"] # already [Time]
      props[:spec] = s
      props[:status] = hash["status"] # may change, use with care

      return self # mainly to help ::from_api_object
    end

    def desired_number_scheduled(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :status, user: user, cached: cached, quiet: quiet)
      return spec["desiredNumberScheduled"]
    end

  end
end
