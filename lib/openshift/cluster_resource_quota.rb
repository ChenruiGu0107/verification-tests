require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift cluster resource quota
  class ClusterResourceQuota < ClusterResource
    RESOURCE = 'clusterresourcequotas'

    def update_from_api_object(crq_hash)
      m = crq_hash["metadata"]
      s = crq_hash["spec"]

      unless crq_hash["kind"] == "ClusterResourceQuota"
        raise "hash not from a ClusterResourceQuota but #{crq_hash["kind"]}"
      end
      unless name == m["name"]
        raise "hash from a different ClusterResourceQuota: #{name} vs #{m["name"]}"
      end

      props[:quota] = s["quota"]
      props[:selector] = s["selector"]

      props[:status] = crq_hash["status"]

      return self # mainly to help ::from_api_object
    end
  end
end
