require 'openshift/project_resource'

module CucuShift
  # represents an OpenShift pod
  class Pod < ProjectResource
    extend  Common::BaseHelper
    # extend  Common::UserObjectClassHelper

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

      # s = pod_hash["spec"] # this is runtime, lets not cache

      s = pod_hash["status"]
      props[:ip] = s["podIP"]

      return self # mainly to help ::from_api_object
    end

    # @return [CucuShift::ResultHash] with :success depending on status=True
    #   with type=Ready
    def ready?(user:)
      res = get(user: user)

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

    # @return [CucuShift::ResultHash] with :success true if we've eventually
    #   got the pod in ready status; the result hash is from last executed get
    #   call
    def wait_till_ready(user, seconds)
      res = nil
      success = wait_for(seconds) {
        res = ready?(user: user)
        res[:success]
      }

      return res
    end

    # this useful if you wait for a pod to die
    def wait_till_not_ready(user, seconds)
      res = nil
      success = wait_for(seconds) {
        res = ready?(user: user)
        ! res[:success]
      }

      res[:success] = success
      return res
    end

    # check that a pod is present
    def wait_till_present(user, seconds)
      res = nil
      success = wait_for(seconds) {
        res = get(user:user)
        res[:success]
      }
      return res
    end

    def wait_till_status(status, user, seconds=15*60)
      res = nil
      success = wait_for(seconds) {
        res = status?(user: user, status: status)
        # if pod completed there's no chance to change status so exit early
        break if [:failed, :unknown].include?(res[:matched_status])
        res[:success]
      }
      return res
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if pod status is what's expected
    def status?(user:, status:)
      statuses = {
        pending: "Pending",
        running: "Running",
        succeeded: "Succeeded",
        failed: "Failed",
        unknown: "Unknown"
      }
      res = get(user: user)
      status = status.respond_to?(:map) ?
          status.map{ |s| statuses[s] } :
          [ statuses[status] ]

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

    # @param labels [String, Array<String,String>] labels to filter on, read
    # @param count [Integer] minimum number of pods to wait for
    #   [CucuShift::Common::BaseHelper#selector_to_label_arr] carefully
    def self.wait_for_labeled(*labels, count: 1, user:, project:, seconds:)
      wait_for_matching(user: user, project: project, seconds: seconds,
                        get_opts: {l: selector_to_label_arr(*labels)},
                        count: count) { true }
    end

    # @param count [Integer] minimum number of pods to wait for
    # @yield block that selects pods by returning true; see [#get_matching]
    # @return [CucuShift::ResultHash] with :matching key being array of matched
    #   pods;
    def self.wait_for_matching(count: 1, user:, project:, seconds:,
                                                                  get_opts: {})
      res = nil

      wait_for(seconds) {
        res = get_matching(user: user, project: project, get_opts: get_opts) { |p, p_hash|
          yield p, p_hash
        }
        res[:matching].size >= count
      }

      return res
    end

    # @yield block that selects pods by returning true; block receives
    #   |pod, pod_hash| as parameters where pod is a reloaded [Pod]
    # @return [CucuShift::ResultHash] with :matching key being array of matched
    #   pods
    def self.get_matching(user:, project:, get_opts: {})
      opts = {resource: 'pod', n: project.name, o: 'yaml'}
      opts.merge! get_opts
      res = user.cli_exec(:get, **opts)

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        res[:pods] = res[:parsed]["items"].map { |p|
          self.from_api_object(project, p)
        }
      else
        user.logger.error(res[:response])
        raise "cannot get pods for project #{project.name}"
      end

      res[:matching] = []
      res[:pods].zip(res[:parsed]["items"]) { |p, p_hash|
        res[:matching] << p if !block_given? || yield(p, p_hash)
      }

      return res
    end
    class << self
      alias list get_matching
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
