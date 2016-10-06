require 'openshift/project_resource'
require 'openshift/container'

module CucuShift
  # represents an OpenShift pod
  class Pod < ProjectResource
    RESOURCE = "pods"
    # https://github.com/kubernetes/kubernetes/blob/master/pkg/api/types.go
    STATUSES = [:pending, :running, :succeeded, :failed, :unknown]
    # statuses that indicate pod running or completed successfully
    SUCCESS_STATUSES = [:running, :succeeded, :missing]
    TERMINAL_STATUSES = [:failed, :succeeded, :missing]

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that ca nchange at any time like status and spec
    def update_from_api_object(pod_hash)
      m = pod_hash["metadata"]
      props[:uid] = m["uid"]
      props[:generateName] = m["generateName"]
      props[:labels] = m["labels"]
      props[:created] = m["creationTimestamp"] # already [Time]
      props[:deleted] = m["deletionTimestamp"] # during grace period
      props[:grace_period] = m["deletionGracePeriodSeconds"] # might be nil
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
      props[:securityContext] = spec["securityContext"]
      props[:containers] = spec["containers"]

      s = pod_hash["status"]
      props[:ip] = s["podIP"]
      # status should be retrieved on demand but we cache it for the brave
      props[:status] = s


      return self # mainly to help ::from_api_object
    end

    # @return [CucuShift::ResultHash] with :success depending on status=True
    #   with type=Ready
    def ready?(user:, quiet: false, cached: false)
      if cached && props[:status]
        res = { instruction: "get cached pod #{name} readiness",
                response: {"status" => props[:status]}.to_yaml,
                success: true,
                exitstatus: 0,
                parsed: {"status" => props[:status]}
        }
      else
        res = get(user: user, quiet: quiet)
      end

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

    # @return [CucuShift::ResultHash] with :success true if we've eventually got
    #   the pod in terminating state; the result hash is from last executed
    #   get call
    def wait_till_terminating(user, seconds)
      stats = {}
      res = {
        instruction: "wait till pod #{name} reach terminating state",
        exitstatus: -1,
        success: false
      }

      res[:success] = !!wait_for(seconds, stats: stats) {
        t = terminating?(user: user, quiet: true)

        break if status?(user: user, status: TERMINAL_STATUSES,
                                 cached: true, quiet: true)[:success]

        t
      }

      res[:response] = "After #{stats[:iterations]} iterations and " <<
        "#{stats[:full_seconds]} seconds: " <<
        "#{res[:success] || phase(user: user, cached: true, quiet: true)}"
      logger.info res[:response]

      return res
    end

    # @note call without parameters only when props are loaded
    def ip(user: nil, cached: true, quiet: false)
      return get_cached_prop(prop: :ip, user: user, cached: cached, quiet: quiet)
    end

    # @note call without parameters only when props are loaded
    def terminating?(user: nil, cached: false, quiet: false)
      status?(user: user, status: :running,
              quiet: quiet, cached: cached)[:success] &&
        get_cached_prop(prop: :deleted, user: user, cached: true, quiet: true)
    end

    # @note call without parameters only when props are loaded
    # @return [Integer] fs_group UID
    def fs_group(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :securityContext, user: user, cached: cached, quiet: quiet)
      return spec["fsGroup"]
    end

    # @return [Integer] uuid_range base
    def sc_run_as_user(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :securityContext, user: user, cached: cached, quiet: quiet)
      return spec["runAsUser"]
    end

    # @return [Boolean] runAsNonRoot value
    def sc_run_as_nonroot(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :securityContext, user: user, cached: cached, quiet: quiet)
      return spec["runAsNonRoot"]
    end

    def sc_selinux_options(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :securityContext, user: user, cached: cached, quiet: quiet)
      return spec["seLinuxOptions"]
    end

    def supplemental_groups(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :securityContext, user: user, cached: cached, quiet: quiet)
      return spec["supplementalGroups"]
    end

    # returns [Hash] of Container objects belonging to a pod, keyed by container name
    #
    def containers(user:, cached: true, quiet: false)
      spec = get_cached_prop(prop: :containers, user: user, cached: cached, quiet: quiet)
      containers = {}
      spec.each do | container |
        cname = container['name']
        containers[cname] = CucuShift::Container.new( name: cname,
                                                      pod: self,
                                                      default_user: user)
      end
      return containers
    end

    # return the Container object matched by the lookup parameter
    def container(user:, name:, cached: true, quiet: false)
      self.containers(user:user, cached: cached, quiet: quiet).fetch(name) {
        raise "No container with name #{name} found."
      }
    end

    def uid(user, cached: true, quiet: false)
      return get_cached_prop(prop: :uid, user: user, cached: cached, quiet: quiet)
    end
    # @note call without parameters only when props are loaded
    def node_hostname(user: nil, cached: true, quiet: false)
      return get_cached_prop(prop: :node_hostname, user: user, cached: cached, quiet: quiet)
    end

    # @note call without parameters only when props are loaded
    def node_name(user: nil, cached: true, quiet: false)
      return get_cached_prop(prop: :node_name, user: user, cached: cached, quiet: quiet)
    end

    def env_var(name, container: nil, user: nil)
      if props[:containers].nil?
        self.get(user: user)
      end
      if props[:containers].length == 1 && !container
        env_var = props[:containers][0]["env"].find { |env_var| env_var["name"] == name }
      elsif container
        container_hash = props[:containers].find { |c| c["name"] == container }
        if container_hash.nil?
          raise "No container with name #{container} found..."
        end
        env_var = container_hash["env"].find { |env_var| env_var["name"] == name }
      end
      return env_var && env_var["value"]
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
