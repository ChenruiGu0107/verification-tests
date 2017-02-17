require 'openshift/project_resource'

module CucuShift
  # represnets an Openshift Deployment
  class Deployment < ProjectResource
    RESOURCE = "deployments"

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that can change at any time like status and spec
    def update_from_api_object(d_hash)

      m = d_hash["metadata"]
      props[:uid] = m["uid"]
      props[:labels] = m["labels"]
      props[:annotations] = m["annotations"] # may change, use with care
      props[:created] = m["creationTimestamp"] # already [Time]
      props[:spec] = d_hash["spec"]
      props[:status] = d_hash["status"] # may change, use with care

      return self # mainly to help ::from_api_object
    end

    def replica_count(user:, cached: false, quiet: false)
      res = get_cached_prop(prop: :status, user: user, cached: cached, quiet: quiet)
      return res['replicas']
    end
    alias replicas replica_count

  end
end
