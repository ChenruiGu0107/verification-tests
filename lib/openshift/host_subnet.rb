require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Host Subnet
  class HostSubnet < ClusterResource
    RESOURCE = 'hostsubnets'

    def ip(user: nil, cached: true, quiet: true)
      raw = raw_resource(user: user, cached: cached, quiet: quiet, res: nil)

      return raw["hostIP"]
    end

    def host(user: nil, cached: true, quiet: true)
      raw = raw_resource(user: user, cached: cached, quiet: quiet, res: nil)

      return raw["host"]
    end

    def subnet(user: nil, cached: true, quiet: true)
      raw = raw_resource(user: user, cached: cached, quiet: quiet, res: nil)

      return raw["subnet"]
    end
  end
end
