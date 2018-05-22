require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Cluster Service Broker
  class ClusterServiceBroker < ClusterResource
    RESOURCE = "clusterservicebrokers"
    def metadata(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr['metadata']
    end

    def spec(spec: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr['spec']
    end

    def relist_behavior(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr.dig("spec", "relistBehavior")
    end

    def relist_duration_raw(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr.dig("spec", "relistDuration")
    end

    def relist_requests(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr.dig("spec", "relistRequests")
    end
  end
end
