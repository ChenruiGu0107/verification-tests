# frozen_string_literal: true

require 'openshift/pod_replicator'

# TODO: DRY together with replica_set.rb

module CucuShift

  # represents an Openshift Deployment
  class Deployment < PodReplicator

    RESOURCE = 'deployments'
    REPLICA_COUNTERS = {
      desired:   %w[spec replicas].freeze,
      current:   %w[status replicas].freeze,
      updated:   %w[status updatedReplicas].freeze,
      available: %w[status availableReplicas].freeze,
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
        instruction: "wait till deployment #{name} reach matching count",
        success: false
      }

      res[:success] = wait_for(seconds, stats: stats) do
        replica_count(user: user, cached: false, quiet: true) == replica_count
      end

      res[:response] = "After #{stats[:iterations]} iterations and " \
                       "#{stats[:full_seconds]} seconds: " \
                       "#{replica_count(user: user, cached: true , quiet: true)}"

      logger.info res[:response]
      return res
    end

    def current_replica_set(user:, cached: true, quiet: false)
      shared_options = { user: user, cached: true, quiet: quiet }.freeze

      labels = match_labels(**shared_options, cached: cached)
      revision = self.revision(**shared_options)

      CucuShift::ReplicaSet.get_labeled(*labels, user: user, project: project)
        .select { |item| item.revision(**shared_options) == revision }
        .max_by { |item| item.created_at(**shared_options) }
    end

    MATCH_LABELS_DIG_PATH = %w[spec selector matchLabels].freeze
    private_constant :MATCH_LABELS_DIG_PATH

    def match_labels(user: nil, cached: true, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig(*MATCH_LABELS_DIG_PATH)
    end

    def collision_count(user: nil, cached: true, quiet: false)
      raw_resource(user: user, cached: true, quiet: quiet).dig("status", "collisionCount")
    end
  end
end
