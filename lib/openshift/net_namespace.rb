require 'openshift/cluster_resource'

module CucuShift
  # represnets an Openshift NetNamespace
  class NetNamespace < ClusterResource
    RESOURCE = "netnamespaces"

    # cache some usualy immutable properties for later fast use; do not cache
    # things that can change at any time like status and spec
    def update_from_api_object(hash)
      m = hash["metadata"]
      props[:netname] = hash["netname"]
      props[:netid] = hash["netid"]
      props[:uid] = m["uid"]
      props[:labels] = m["labels"]
      props[:annotations] = m["annotations"] # may change, use with care
      props[:created] = m["creationTimestamp"] # already [Time]
      props[:status] = hash["status"] # may change, use with care

      return self # mainly to help ::from_api_object
    end
    
    def annotations(user: env.admin, cached: true, quiet: false)
      return get_cached_prop(prop: :annotations, user: user, cached: cached, quiet: quiet)
    end
  end
end
