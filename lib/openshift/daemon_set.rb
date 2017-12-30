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

    def desired_number_scheduled(user:, cached: true, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("status", "desiredNumberScheduled")
    end

  end
end
