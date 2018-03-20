require 'openshift/pod_replicator'

module CucuShift
  # represnets an Openshift StatefulSets
  class DaemonSet < PodReplicator
    RESOURCE = "daemonsets"
    
    # all these counters are accessible as method calls
    # see implementation in PodReplicator#method_missing
    # e.g. ds.misscheduled_replicas(cached: false)
    REPLICA_COUNTERS = {
      desired: %w[status desiredNumberScheduled].freeze,
      current: %w[status currentNumberScheduled].freeze,
      ready:   %w[status numberReady].freeze,
      updated_scheduled: %w[status updatedNumberScheduled].freeze,
      misscheduled: %w[status numberMisscheduled].freeze,
      available: %w[status numberAvailable].freeze,
    }.freeze
  end
end
