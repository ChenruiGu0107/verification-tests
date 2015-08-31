require 'common'

module CucuShift
  # represents an OpenShift pod
  class Pod
    include Common::Helper
    include Common::UserObjectHelper
    extend  Common::BaseHelper
    # extend  Common::UserObjectClassHelper

    attr_reader :props, :name, :project

    # @param name [String] name of pod
    # @param project [CucuShift::Project] the project pod belongs to
    # @param props [Hash] additional properties of the pod
    def initialize(name:, project:, props: {})
      @name = name
      @project = project
      @props = props
    end

    # creates new pod from an OpenShift API Pod object
    def self.from_api_object(project, pod_hash)
      self.new(project: project, name: pod_hash["metadata"]["name"]).
                                update_from_api_object(pod_hash)
    end

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
      # s = pod_hash["status"] # this is runtime, lets not cache

      return self # mainly to help ::from_api_object
    end

    def get(user:)
      res = cli_exec(as: user, key: :get, n: project.name,
                resource_name: name,
                resource: "pod",
                output: "yaml")

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        update_from_api_object(res[:parsed])
      end

      return res
    end
    alias reload get

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

    # @param labels [String, Array<String,String>] labels to filter on, read
    #   [CucuShift::Common::BaseHelper#selector_to_label_arr] carefully
    def self.wait_for_labeled(*labels, user:, project:, seconds:)
      wait_for_matching(user: user, project: project, seconds: seconds,
                        get_opts: {l: selector_to_label_arr(*labels)}) {true}
    end

    # @yield block that selects pods by returning true; see [#get_matching]
    # @return [CucuShift::ResultHash] with :matching key being array of matched
    #   pods;
    def self.wait_for_matching(user:, project:, seconds:, get_opts: {})
      res = nil

      wait_for(seconds) {
        res = get_matching(user: user, project: project, get_opts: get_opts) { |p, p_hash|
          yield p, p_hash
        }
        ! res[:matching].empty?
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
      res = cli_exec(as: user, key: :get, **opts)

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
    alias list get_matching

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

    def env
      project.env
    end

    def ==(p)
      p.kind_of?(self.class) && name == p.name && project == p.project
    end
    alias eql? ==

    def hash
      :pod.hash ^ name.hash ^ project.hash
    end
  end
end

