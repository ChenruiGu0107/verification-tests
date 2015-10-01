require 'common'

module CucuShift
  # represents an OpenShift ReplicationController (rc for short) used for scaling pods
  class ReplicationController
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
      self.new(project: project, name: rc_hash["metadata"]["name"]).
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
                resource: "rc",
                output: "yaml")

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        update_from_api_object(res[:parsed])
      end

      return res
    end

    # @return [CucuShift::ResultHash] with :success depending on status['replicas'] == spec['replicas']
    def ready?(user:)
      res = get(user: user)
      if res[:success]
        res[:success] = res[:parsed]["status"]["replicas"] == res[:parsed]["spec"]["replicas"]
      end
      return res
    end

    # @return [CucuShift::ResultHash] with :success true if we've eventually
    #   got the rc in ready status; the result hash is from last executed get
    #   call
    def wait_till_ready(user, seconds)
      res = nil
      success = wait_for(seconds) {
        res = ready?(user: user)
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
    #   rcs;
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

    # @yield block that selects rcs by returning true; block receives
    #   |rc, rc_hash| as parameters where rc is a reloaded [RepicationController]
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
      res[:rcs].zip(res[:parsed]["items"]) { |rc, rc_hash|
        res[:matching] << rc if !block_given? || yield(rc, rc_hash)
      }

      return res
    end
    class << self
      alias list get_matching
    end


    def env
      project.env
    end

    def ==(r)
      r.kind_of?(self.class) && name == r.name && project == r.project
    end
    alias eql? ==

    def hash
      :rc.hash ^ name.hash ^ project.hash
    end
  end
end
