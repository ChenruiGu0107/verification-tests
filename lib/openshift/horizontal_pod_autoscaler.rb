require 'openshift/pod_replicator'

module CucuShift
  # represents an OpenShift Image Stream
  class HorizontalPodAutoscaler < PodReplicator
    RESOURCE = "horizontalpodautoscalers"

    REPLICA_COUNTERS = {
      max: %w[spec maxReplicas].freeze,
      min: %w[spec minReplicas].freeze,
      current: %w[status currentReplicas].freeze,
    }.freeze

    def target_cpu_utilization_percentage(user: nil, cached: true, quiet: false)
      obj = raw_resource(user: user, cached: cached, quiet: quiet)
      return obj.dig('spec', 'targetCPUUtilizationPercentage')
    end

    def current_cpu_utilization_percentage(user: nil, cached: true, quiet: false)
      obj = raw_resource(user: user, cached: cached, quiet: quiet)
      return obj.dig('status', 'currentCPUUtilizationPercentage')
    end

    def current_replicas(user: nil, cached: true, quiet: false)
      replica_counters(user: user, cached: cached, quiet: quiet)[:current]
    end

    def max_replicas(user: nil, cached: true, quiet: false)
      replica_counters(user: user, cached: cached, quiet: quiet)[:max]
    end

    def min_replicas(user: nil, cached: true, quiet: false)
      replica_counters(user: user, cached: cached, quiet: quiet)[:min]
    end
  end
end
