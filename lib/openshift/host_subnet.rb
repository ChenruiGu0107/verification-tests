require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Host Subnet
  class HostSubnet < ClusterResource
    RESOURCE = 'hostsubnets'

    def update_from_api_object(hs_hash)
      m = hs_hash["metadata"]

      unless hs_hash["kind"] == "HostSubnet"
        raise "hash not from a HostSubnet: #{hs_hash["kind"]}"
      end
      unless name == m["name"]
        raise "hash from a different HostSubnet: #{name} vs #{m["name"]}"
      end

      props[:uid] = m["uid"]
      props[:host] = hs_hash["host"]

      return self # mainly to help ::from_api_object
    end
  end
end
