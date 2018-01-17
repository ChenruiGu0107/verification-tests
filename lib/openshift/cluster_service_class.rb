require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Cluster Service Class
  class ClusterServiceClass < ClusterResource
    RESOURCE = "clusterserviceclasses"

    def metadata(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr['metadata']
    end

    def spec(spec: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr['spec']
    end

    def uid(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr.dig("metadata", "uid")
    end

    def external_name(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr.dig("spec", "externalName")
    end

    def dependencies(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr.dig('spec', 'externalMetadata', 'dependencies')
    end

    def provider_display_name(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr.dig('spec', 'externalMetadata', 'providerDisplayName')
    end

  end  # end of class
end
