require 'common'

module CucuShift
  # represents an OpenShift DeploymentConfig (dc for short) used for scaling pods
  class DeploymentConfig
    include Common::Helper
    include Common::UserObjectHelper
    extend  Common::BaseHelper
    attr_reader :props, :name, :project

    # @param name [String] name of rc
    # @param project [CucuShift::Project] the project rc belongs to
    # @param props [Hash] additional properties of the rc
    def initialize(name:, project:, props: {})
      @name = name
      @project = project
      @props = props
    end

    # creates new rc from an OpenShift API rc object
    def self.from_api_object(project, rc_hash)
      self.new(project: project, name: pod_hash["metadata"]["name"]).
                                update_from_api_object(rc_hash)
    end

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

    def get(user:)
      res = cli_exec(as: user, key: :get, n: project.name,
                resource_name: name,
                resource: "dc",
                output: "yaml")

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        update_from_api_object(res[:parsed])
      end

      return res
    end

    def describe(user, version)
      res = cli_exec(as: user, key: :describe, n: project.name,
        name: name + "-#{version}",
        resource: "rc")

    end


    def wait_till_status(status, version, user, seconds=15*60)
      res = nil
      success = wait_for(seconds) {
        res = status?(user, status, version)
        # if pod completed there's no chance to change status so exit early
        break if [:failed, :unknown, :missing].include?(res[:matched_status])
        res[:success]
      }
      return res
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if pod status is what's expected
    def status?(user, status, version)
      statuses = {
        waiting: "Waiting",
        running: "Running",
        succeeded: "Succeeded",
        failed: "Failed",
      }
      res = describe(user, version)
      if res[:success]
        pods_status = parse_oc_describe(res[:response])[:pods_status]
        res[:success] = (pods_status[status].to_i != 0)
      end
      return res
    end

    # @return [CucuShift::ResultHash] with :success depending on status['replicas'] == spec['replicas']
    def ready?(user, version)
      #res = get(user: user)
      res = describe(user, version)

      if res[:success]
        oc_output = parse_oc_describe(res[:response])
        # return success if the pod is running  
        res[:success] =  parse_oc_describe(res[:response])[:pods_status][:running].to_i == 1
      end
      return res
    end


    # @return [CucuShift::ResultHash] with :success true if we've eventually
    #   got the status to equal to the expected version in ready status; the result hash is
    #   from last executed get call
    def wait_till_ready(user, version, seconds)
      res = nil
      success = wait_for(seconds) {
        res = ready?(user, version)
        res[:success]
      }

      return res
    end

    # @param labels [String, Array<String,String>] labels to filter on, read
    #   [CucuShift::Common::BaseHelper#selector_to_label_arr] carefully
    def self.wait_for_labeled(*labels, user:, project:, seconds:)
      wait_for_matching(user: user, project: project, seconds: seconds,
                        get_opts: {l: selector_to_label_arr(*labels)}) {true}
    end

    # @yield block that selects rcs by returning true; see [#get_matching]
    # @return [CucuShift::ResultHash] with :matching key being array of matched
    #   pods;
    def self.wait_for_matching(user:, project:, seconds:, get_opts: {})
      res = nil

      wait_for(seconds) {
        res = get_matching(user: user, project: project, get_opts: get_opts) { |r, r_hash|
          yield r, r_hash
        }
        ! res[:matching].empty?
      }

      return res
    end

    # @yield block that selects pods by returning true; block receives
    #   |pod, pod_hash| as parameters where pod is a reloaded [Pod]
    # @return [CucuShift::ResultHash] with :matching key being array of matched
    #   rcs
    def self.get_matching(user:, project:, get_opts: {})
      opts = {resource: 'rc', n: project.name, o: 'yaml'}
      opts.merge! get_opts
      res = user.cli_exec(:get, **opts)

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        res[:rcs] = res[:parsed]["items"].map { |r|
          self.from_api_object(project, r)
        }
      else
        user.logger.error(res[:response])
        raise "cannot get rcs for project #{project.name}"
      end

      res[:matching] = []
      res[:rcs].zip(res[:parsed]["items"]) { |r, r_hash|
        res[:matching] << p if !block_given? || yield(r, r_hash)
      }

      return res
    end
    class << self
      alias list get_matching
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
