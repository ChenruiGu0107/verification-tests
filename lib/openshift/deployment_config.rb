require 'common'

module CucuShift
  # represents an OpenShift DeploymentConfig (dc for short) used for scaling pods
  class DeploymentConfig
    include Common::Helper
    include Common::UserObjectHelper
    extend  Common::BaseHelper
    attr_reader :props, :name, :project

    # @param name [String] name of dc
    # @param project [CucuShift::Project] the project dc belongs to
    # @param props [Hash] additional properties of the dc
    def initialize(name:, project:, props: {})
      @name = name
      @project = project
      @props = props
    end

    # creates new dc from an OpenShift API dc object
    def self.from_api_object(project, dc_hash)
      self.new(project: project, name: dc_hash["metadata"]["name"]).
                                update_from_api_object(dc_hash)
    end

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that can change at any time like status and spec
    def update_from_api_object(dc_hash)
      m = dc_hash["metadata"]
      s = dc_hash["spec"]
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

    def describe(user)
      resource_type = "dc"
      resource_name = name
      res = cli_exec(as: user, key: :describe, n: project.name,
        name: resource_name,
        resource: resource_type)
      res[:parsed] = self.parse_oc_describe(res[:response]) if res[:success]
      return res
    end

    def wait_till_status(status, user, seconds=15*60)
      res = nil
      success = wait_for(seconds) {
        res = status?(user, status)
        # if dc completed there's no chance to change status so exit early
        break if [:failed, :succeeded].include?(res[:matched_status])
        res[:success]
      }
      return res
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if pod status is what's expected
    def status?(user, status)
      statuses = {
        waiting: "Waiting",
        running: "Running",
        succeeded: "Succeeded",
        failed: "Failed",
        complete: "Complete",
      }
      res = describe(user)
      if res[:success]
        res[:success] = res[:parsed][:overall_status] == statuses[status]
      end
      return res
    end

    # @return [CucuShift::ResultHash] with :success depending on status['replicas'] == spec['replicas']
    def ready?(user)
      res = describe(user)

      if res[:success]
        # return success if the pod is running
        res[:success] =  res[:parsed][:pods_status][:running].to_i == 1
      end
      return res
    end


    # @return [CucuShift::ResultHash] with :success true if we've eventually
    #   got the status to equal to the expected version in ready status; the result hash is
    #   from last executed get call
    def wait_till_ready(user, seconds)
      res = nil
      success = wait_for(seconds) {
        res = ready?(user)
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

    # @yield block that selects dcs by returning true; see [#get_matching]
    # @return [CucuShift::ResultHash] with :matching key being array of matched
    #   pods;
    def self.wait_for_matching(user:, project:, seconds:, get_opts: {})
      res = nil

      wait_for(seconds) {
        res = get_matching(user: user, project: project, get_opts: get_opts) { |d, d_hash|
          yield d, d_hash
        }
        ! res[:matching].empty?
      }

      return res
    end

    # @yield block that selects dcs by returning true; block receives
    #   |dc, dc_hash| as parameters where dc is a reloaded [DeployConfig]
    # @return [CucuShift::ResultHash] with :matching key being array of matched
    #   dcs
    def self.get_matching(user:, project:, get_opts: {})
      opts = {resource: 'dc', n: project.name, o: 'yaml'}
      opts.merge! get_opts
      res = user.cli_exec(:get, **opts)

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        res[:dcs] = res[:parsed]["items"].map { |d|
          self.from_api_object(project, d)
        }
      else
        user.logger.error(res[:response])
        raise "cannot get dcs for project #{project.name}"
      end

      res[:matching] = []
      res[:dcs].zip(res[:parsed]["items"]) { |dc, dc_hash|
        res[:matching] << dc if !block_given? || yield(dc, dc_hash)
      }

      return res
    end
    class << self
      alias list get_matching
    end


    def env
      project.env
    end

    def ==(dc)
      dc.kind_of?(self.class) && name == dc.name && project == dc.project
    end
    alias eql? ==

    def hash
      :dc.hash ^ name.hash ^ project.hash
    end
  end
end
