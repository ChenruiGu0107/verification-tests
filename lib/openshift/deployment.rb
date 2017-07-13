# frozen_string_literal: true

require 'openshift/pod_replicator'

# TODO: DRY together with replicaset.rb

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

    # cache some usualy immutable properties for later fast use
    # do not cache things that can change at any time like status and spec
    def update_from_api_object(d_hash)
      m = d_hash["metadata"]

      props[:uid]         = m["uid"]
      props[:labels]      = m["labels"]
      props[:annotations] = m["annotations"] # may change, use with care
      props[:created]     = m["creationTimestamp"] # already [Time]
      props[:spec]        = d_hash["spec"]
      props[:status]      = d_hash["status"] # may change, use with care

      super(d_hash)
    end

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

    MATCH_LABELS_DIG_PATH = %w[selector matchLabels].freeze
    private_constant :MATCH_LABELS_DIG_PATH

    def match_labels(user:, cached: true, quiet: false)
      options = {
        prop:   :spec,
        user:   user,
        quiet:  quiet,
        cached: cached,
      }.freeze
      get_cached_prop(options).dig(*MATCH_LABELS_DIG_PATH)
    end

  end
end
