require 'openshift/project_resource'

module CucuShift
  # represnets an Openshift ReplicaSets (rs for short)
  class ReplicaSet < ProjectResource
    RESOURCE = "replicasets"

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that can change at any time like status and spec
    def update_from_api_object(rs_hash)
      m = rs_hash["metadata"]
      s = rs_hash["spec"]
      props[:uid] = m["uid"]
      props[:labels] = m["labels"]
      props[:annotations] = m["annotations"] # may change, use with care
      props[:created] = m["creationTimestamp"] # already [Time]
      props[:spec] = s
      props[:status] = rs_hash["status"] # may change, use with care

      return self # mainly to help ::from_api_object
    end

    # Not a dynmaic property, so don't cache
    def replicas(user:, cached: false, quiet: false)
      res = get_cached_prop(prop: :status, user: user, cached: cached, quiet: quiet)
      return res['replicas']
    end
  end
end
