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

    # @return [Boolean] true if we've eventually
    #   get the number of reclicas to match the desired number
    def wait_till_replica_count_match(user:, seconds:, replica_count:)
      stats = {}
      res = {
        instruction: "wait till deployemnt #{name} reach matching count",
        success: false
      }
      res[:success] = wait_for(seconds, stats: stats) {
        replica_count(user: user, cached: false, quiet: true) == replica_count
      }
      res[:response] = "After #{stats[:iterations]} iterations and " \
                       "#{stats[:full_seconds]} seconds: " \
                       "#{replica_count(user: user, cached: true , quiet: true)}"
      logger.info res[:response]
      return res
    end
  end
end
