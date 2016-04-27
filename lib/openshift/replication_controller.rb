require 'openshift/project_resource'

module CucuShift
  # represents an OpenShift ReplicationController (rc for short) used for scaling pods
  class ReplicationController < ProjectResource
    RESOURCE = "replicationcontroller"

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that can change at any time like status and spec
    def update_from_api_object(rc_hash)
      m = rc_hash["metadata"]
      s = rc_hash["spec"]
      props[:uid] = m["uid"]
      props[:labels] = m["labels"]
      props[:created] = m["creationTimestamp"] # already [Time]
      props[:spec] = s

      return self # mainly to help ::from_api_object
    end

    def describe(user, quiet: false)
      resource_type = "rc"
      resource_name = name
      cli_opts = {
        as: user, key: :describe, n: project.name,
        name: resource_name,
        resource: resource_type,
        _quiet: quiet
      }
      cli_opts[:_quiet] = quiet if quiet

      res = cli_exec(**cli_opts)
      res[:parsed] = self.parse_oc_describe(res[:response]) if res[:success]
      return res
    end

    # @param from_status [Symbol] the status we currently see
    # @param to_status [Array, Symbol] the status(es) we check whether current
    #   status can change to
    # @return [Boolean] true if it is possible to transition between the
    #   specified statuses (same -> same should return true)
    def status_reachable?(from_status, to_status)
      [to_status].flatten.include?(from_status) ||
        ![:failed, :succeeded].include?(from_status)
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if pod status is what's expected
    def status?(user, status, quiet: false)
      statuses = {
        waiting: "Waiting",
        running: "Running",
        succeeded: "Succeeded",
        failed: "Failed",
        complete: "Complete",
      }
      res = describe(user, quiet: quiet)
      if res[:success]
        pods_status = res[:parsed][:pods_status]
        res[:success] = (pods_status[status].to_i != 0)
      end
      return res
    end

    # @return [CucuShift::ResultHash] with :success depending on status['replicas'] == spec['replicas']
    #  Please note we also need to check that the spec.replicas is > 0
    def ready?(user:, quiet: false)
      res = get(user: user, quiet: quiet)
      if res[:success]
        res[:success] = (res[:parsed]["status"]["replicas"] == res[:parsed]["spec"]["replicas"] \
                         and res[:parsed]["spec"]["replicas"].to_i > 0)
      end
      return res
    end

    # @return [CucuShift::ResultHash] with :success true if we've eventually
    #   got the rc in ready status; the result hash is from last executed get
    #   call
    def wait_till_ready(user, seconds)
      res = nil
      iterations = 0
      start_time = monotonic_seconds

      success = wait_for(seconds) {
        res = ready?(user: user, quiet: true)

        logger.info res[:command] if iterations == 0
        iterations = iterations + 1

        res[:success]
      }

      duration = monotonic_seconds - start_time
      logger.info "After #{iterations} iterations and #{duration.to_i} " <<
        "seconds:\n#{res[:response]}"

      return res
    end

    # @return [CucuShift::ResultHash]
    def replica_count_match?(user:, state:, replica_count:, quiet: false)
      res = describe(user, quiet: quiet)
      if res[:success]
        res[:success] = res[:parsed][:pods_status][state].to_i == replica_count
      end
      return res
    end

    # @return [CucuShift::ResultHash] with :success true if we've eventually
    #   get the number of reclicas 'running' to match the desired number
    def wait_till_replica_count_match(user:, state:, seconds:, replica_count:)
      res = nil
      iterations = 0
      start_time = monotonic_seconds

      success = wait_for(seconds) {
        res = replica_count_match?(user: user, state: state, replica_count: replica_count, quiet: true)

        logger.info res[:command] if iterations == 0
        iterations = iterations + 1

        res[:success]
      }

      duration = monotonic_seconds - start_time
      logger.info "After #{iterations} iterations and #{duration.to_i} " <<
        "seconds:\n#{res[:response]}"

      return res
    end
  end
end
