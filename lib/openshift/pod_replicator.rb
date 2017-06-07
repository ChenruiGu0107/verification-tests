# frozen_string_literal: true

require 'openshift/project_resource'
require 'active_support/core_ext/hash/slice'

module CucuShift
  class PodReplicator < ProjectResource

    ## must be defined in subclasses
    # REPLICA_COUNTERS = {
    #   counter_name: %w[path to dig].freeze,
    # }.freeze

    def replica_counters(user:, cached: true, quiet: false)
      shared_options = { user: user, cached: cached, quiet: quiet }.freeze

      resource = {
        'spec'   => get_cached_prop(**shared_options, prop: :spec),
        'status' => get_cached_prop(**shared_options, prop: :status),
      }.freeze

      self.class::REPLICA_COUNTERS.map do |counter, path|
        [counter, resource.dig(*path).to_i]
      end.to_h.freeze
    end

    def wait_till_replica_counters_match(user:, seconds:, **options)
      expected = options.slice(*self.class::REPLICA_COUNTERS.keys)

      stats = {}
      result = {
        instruction: "wait till deployment #{name} reaches matching count",
        success: false,
      }

      result[:success] = wait_for(seconds, stats: stats) do
        counters = replica_counters(user: user, quiet: true, cached: false)
        counters.slice(*expected.keys) == expected
      end

      result[:response] = <<-MESSAGE.gsub(/[[:space:]]+/, ' ').strip
        After #{stats[:iterations]} iterations
        and #{stats[:full_seconds]} seconds:
        #{replica_counters(user: user, quiet: true).inspect}
      MESSAGE

      logger.info result[:response]
      result
    end

    def revision(user:, cached: true, quiet: false)
      annotation('deployment.kubernetes.io/revision',
        user: user, cached: cached, quiet: quiet)
    end

  end
end
