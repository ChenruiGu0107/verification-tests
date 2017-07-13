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

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that can change at any time like status and spec
    def update_from_api_object(rs_hash)
      m = rs_hash["metadata"]
      s = rs_hash["spec"]

      props[:uid]         = m["uid"]
      props[:labels]      = m["labels"]
      props[:annotations] = m["annotations"] # may change, use with care
      props[:created]     = m["creationTimestamp"] # already [Time]
      props[:spec]        = s
      props[:status]      = rs_hash["status"] # may change, use with care

      super(rs_hash)
    end

    # Not a dynamic property, so don't cache
    def replica_count(user:, cached: false, quiet: false)
      res = get_cached_prop(prop: :status, user: user, cached: cached, quiet: quiet)
      return res['replicas']
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
