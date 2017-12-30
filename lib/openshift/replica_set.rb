# frozen_string_literal: true

require 'openshift/pod_replicator'

# TODO: DRY together with deployment.rb

module CucuShift

  # represents an Openshift ReplicaSets (rs for short)
  class ReplicaSet < PodReplicator

    RESOURCE = 'replicasets'
    REPLICA_COUNTERS = {
      desired: %w[spec replicas].freeze,
      current: %w[status replicas].freeze,
      ready:   %w[status readyReplicas].freeze,
    }.freeze

    # we define this in method_missing so alias can't fly
    # alias replica_count current_replicas
    def replica_count(*args, &block)
      current_replicas(*args, &block)
    end
    alias replicas replica_count

    # @return [Boolean] true if we've eventually
    #   get the number of replicas to match the desired number
    def wait_till_replica_count_match(user:, seconds:, replica_count:)
      stats = {}
      res = {
        instruction: "wait till replicaset #{name} reach matching count",
        success:     false,
      }

      res[:success] = wait_for(seconds, stats: stats) do
        replica_count(user: user, cached: false, quiet: true) == replica_count
      end

      res[:response] = "After #{stats[:iterations]} iterations and " \
                       "#{stats[:full_seconds]} seconds: " \
                       "#{replica_count(user: user, cached: true, quiet: true)}"

      logger.info res[:response]
      return res
    end
  end
end
