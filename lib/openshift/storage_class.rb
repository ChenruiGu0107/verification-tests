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
      props[:parameters] = sc_hash["parameters"]
      props[:annotations] = m["annotations"]
      return self # mainly to help ::from_api_object
    end
    
    def default?(user: nil, cached: true, quiet:false)
      annotation = get_cached_prop(prop: :annotations, user: user, cached: cached, quiet: quiet)
      if annotation 
        default_value = annotation("storageclass.beta.kubernetes.io/is-default-class") ||
                        annotation("storageclass.kubernetes.io/is-default-class")
        return "true" == default_value
      end
    end 
    
    def rest_url(user: nil, cached: true, quiet: false)
      param = get_cached_prop(prop: :parameters, user: user, cached: cached, quiet: quiet)
      return param["resturl"]
    end
  end
end
