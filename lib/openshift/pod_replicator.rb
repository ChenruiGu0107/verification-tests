# frozen_string_literal: true

require 'openshift/project_resource'
require 'active_support/core_ext/hash/slice'
require 'base_helper'

module CucuShift
  class PodReplicator < ProjectResource

    ## must be defined in subclasses
    # REPLICA_COUNTERS = {
    #   counter_name: %w[path to dig].freeze,
    # }.freeze

    def replica_counters(user:, cached: true, quiet: false, res: nil)
      resource = raw_resource(user: user, quiet: quiet, res: res, cached: cached)
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
        counters = replica_counters(user: user, quiet: true,
                                    cached: false, res: result)
        counters.slice(*expected.keys) == expected
      end

      logger.info "After #{stats[:iterations]} iterations\n" \
        "and #{stats[:full_seconds]} seconds:\n" \
        "#{replica_counters(user: user, quiet: true).inspect}"

      unless result[:success]
        logger.warn "#{shortclass}: timeout waiting for replica counters " \
          "to match; last state:\n\$ #{result[:command]}\n#{result[:response]}"
      end
      return result
    end

    def revision(user:, cached: true, quiet: false)
      annotation('deployment.kubernetes.io/revision',
        user: user, cached: cached, quiet: quiet)
    end

    ################### container spec related methods ####################
    def template(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return spec['template']
    end

    # translate template containers into ContainerSpec object
    def containers_spec(user: nil, cached: true, quiet: false)
      specs = []
      containers_spec = template(user: user)['spec']['containers']
      containers_spec.each do | container_spec |
        specs.push ContainerSpec.new container_spec
      end
      return specs
    end

    # return the spec for a specific container identified by the param name
    def container_spec(user: nil, name:, cached: true, quiet: false)
      specs = containers_spec(user: user, cached: cached, quiet: quiet)
      target_spec = {}
      specs.each do | spec |
        target_spec = spec if spec.name == name
      end
      raise "No container spec found mathcing '#{name}'!" if target_spec.is_a? Hash
      return target_spec
    end

  end
end
