require 'openshift/project_resource'

require 'openshift/flakes/build_strategy'

module CucuShift
  # represents an OpenShift build
  class BuildConfig < ProjectResource
    RESOURCE = "buildconfigs"

    def output_to_ref(user: nil, cached: true, quiet: false)
      unless cached && props[:output_to_ref]
        raw = raw_resource(user: user, cached: cached, quiet: quiet)
        spec = raw.dig("spec", "output", "to")
        props[:output_to_ref] = ObjectReference.new(spec)
      end
      return props[:output_to_ref]
    end

    def output_to(user: nil, cached: true, quiet: false)
      output_to_ref(user: user, cached: cached, quiet: quiet).resource(self)
    end

    def strategy(user: nil, cached: true, quiet: false)
      unless cached && props[:strategy]
        raw = raw_resource(user: user, cached: cached, quiet: quiet)
        spec = raw.dig("spec", "strategy")
        props[:strategy] = BuildStrategy.from_spec(spec, self)
      end
      return props[:strategy]
    end
  end
end
