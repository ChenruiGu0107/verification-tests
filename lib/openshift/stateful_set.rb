require 'openshift/project_resource'

module CucuShift
  # represnets an Openshift StatefulSets
  class StatefulSet < ProjectResource
    RESOURCE = "statefulsets"

    # Not a dynmaic property, so don't cache
    def replica_count(user: nil, cached: false, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('status', 'replicas')
    end

    # @return [Boolean] true if we've eventually
    # get the number of reclicas to match the desired number
    def wait_till_replica_count_match(user: nil, seconds:, replica_count:)
      stats = {}
      res = {
        instruction: "wait till replicaset #{name} reach matching count",
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
