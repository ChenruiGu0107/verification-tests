require 'openshift/project_resource'

module CucuShift
  # represents an OpenShift pod
  class Pod < ProjectResource

    # statuses that indicate pod running or completed successfully
    SUCCESS_STATUSES = [:running, :succeeded, :missing]
    RESOURCE = "pods"

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that ca nchange at any time like status and spec
    def update_from_api_object(pod_hash)
      m = pod_hash["metadata"]
      props[:uid] = m["uid"]
      props[:generateName] = m["generateName"]
      props[:labels] = m["labels"]
      props[:created] = m["creationTimestamp"] # already [Time]
      props[:annotations] = m["annotations"]
      props[:deployment_config_version] = m["annotations"]["openshift.io/deployment-config.latest-version"]
      props[:deployment_config_name] = m["annotations"]["openshift.io/deployment-config.name"]
      props[:deployment_name] = m["annotations"]["openshift.io/deployment.name"]

      # for builder pods
      props[:build_name] = m["annotations"]["openshift.io/build.name"]

      # for deployment pods
      # ???

      spec = pod_hash["spec"] # this is runtime, lets not cache
      props[:node_hostname] = spec["host"]
      props[:node_name] = spec["nodeName"]

      s = pod_hash["status"]
      props[:ip] = s["podIP"]


      return self # mainly to help ::from_api_object
    end

    # @return [CucuShift::ResultHash] with :success depending on status=True
    #   with type=Ready
    def ready?(user:, quiet: false)
      res = get(user: user, quiet: quiet)

      if res[:success]
        res[:success] =
          res[:parsed]["status"] &&
          res[:parsed]["status"]["conditions"] &&
          res[:parsed]["status"]["conditions"].any? { |c|
            c["type"] == "Ready" && c["status"] == "True"
          }
      end

      return res
    end

    # @note call without parameters only when props are loaded
    def ip(user: nil)
      get_checked(user: user) if !props[:ip]

      return props[:ip]
    end

    # @note call without parameters only when props are loaded
    def node_hostname(user: nil)
      get_checked(user: user) if !props[:node_hostname]

      return props[:node_hostname]
    end

    # @note call without parameters only when props are loaded
    def node_name(user: nil)
      get_checked(user: user) if !props[:node_name]

      return props[:node_name]
    end

    # this useful if you wait for a pod to die
    def wait_till_not_ready(user, seconds)
      res = nil
      iterations = 0
      start_time = monotonic_seconds

      success = wait_for(seconds) {
        res = ready?(user: user, quiet: true)

        logger.info res[:command] if iterations == 0
        iterations = iterations + 1

        ! res[:success]
      }

      duration = monotonic_seconds - start_time
      logger.info "After #{iterations} iterations and #{duration.to_i} " <<
        "seconds:\n#{res[:response]}"

      res[:success] = success
      return res
    end

    # @param from_status [Symbol] the status we currently see
    # @param to_status [Array, Symbol] the status(es) we check whether current
    #   status can change to
    # @return [Boolean] true if it is possible to transition between the
    #   specified statuses (same -> should be true)
    def status_reachable?(from_status, to_status)
      [to_status].flatten.include?(from_status) ||
        ![:failed, :unknown].include?(from_status)
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if pod status is what's expected
    def status?(user:, status:, quiet: false)
      #The 'missing' status is used a a dummy value; when some pods become
      #ready, they die (build/deploy), and we still want to count them as well.
      statuses = {
        pending: "Pending",
        running: "Running",
        succeeded: "Succeeded",
        failed: "Failed",
        missing: "Dummy Value",
        unknown: "Unknown"
      }

      res = get(user: user, quiet: quiet)
      status = status.respond_to?(:map) ?
          status.map{ |s| statuses[s] } :
          [ statuses[status.to_sym] ]

      #Check if the user-provided status actually exists
      if status.any?{|s| s.nil?}
        raise "The provided status is not a pre-existing state. Please check again."
      end

      if res[:success]
        res[:success] =
          res[:parsed]["status"] &&
          res[:parsed]["status"]["phase"] &&
          status.include?(res[:parsed]["status"]["phase"])

        res[:matched_status], garbage = statuses.find { |sym, str|
          str == res[:parsed]["status"]["phase"]
        }
      # missing pods mean pod has been destroyed already probably deploy pod
      elsif res[:stderr].include? 'not found'
        res[:success] = true if status.include? :missing
        res[:matched_status] = :missing
      end
      return res
    end

    # executes command on pod
    def exec(command, *args, as:)
      #opts = []
      #opts << [:pod, name]
      #opts << [:cmd_opts_end, true]
      #opts << [:exec_command, command]
      #args.each {|a| opts << [:exec_command_arg, a]}
      #
      #env.cli_executor.exec(as, :exec, opts)

      cli_exec(as: as, key: :exec, pod: name, n: project.name,
               oc_opts_end: true,
               exec_command: command,
               exec_command_arg: args)
    end
  end
end
