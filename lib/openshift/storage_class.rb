require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Storage Class
  class StorageClass < ClusterResource
    RESOURCE = 'storageclasses'

    def update_from_api_object(sc_hash)
      m = sc_hash["metadata"]

      unless sc_hash["kind"] == "StorageClass"
        raise "hash not from a StorageClass: #{sc_hash["kind"]}"
      end
      unless name == m["name"]
        raise "hash from a different StorageClass: #{name} vs #{m["name"]}"
      end

      props[:uid] = m["uid"]
      props[:spec] = sc_hash["spec"]

      return self # mainly to help ::from_api_object
    end
  end
end
