module CucuShift
  # represents OpenShift v3 Service concept
  class Service
    include Common::Helper
    include Common::UserObjectHelper

    attr_reader :props, :name, :project

    # @param name [String] service name
    # @param project [CucuShift::Project] the project where service was created
    def initialize(name:, project:, props: {})
      @name = name
      @project = project
      @props = props
    end

    # @return [CucuShift::ResultHash] with :success true if we've eventually
    #   got the pod in ready status; the result hash is from last executed get
    #   call
    def wait_to_appear(user, seconds)
      res = nil
      success = wait_for(seconds) {
        res = get(user: user)
        res[:success]
      }

      return res
    end

    def get(user:)
      res = cli_exec(as: user, key: :get, n: project.name,
                resource_name: name,
                resource: "service",
                output: "yaml")

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        update_from_api_object(res[:parsed])
      end

      return res
    end
    alias reload get

    def get_checked(user:)
      res = get(user: user)
      unless res[:success]
        logger.error(res[:response])
        raise "could not get service"
      end
      return res
    end

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that ca nchange at any time like status and spec
    def update_from_api_object(service_hash)
      m = service_hash["metadata"]
      s = service_hash["spec"]

      unless m["name"] == name
        raise "looks like a hash from another service: #{name} vs #{m["name"]}"
      end

      props[:created] = m["creationTimestamp"]
      props[:labels] = m["labels"]
      props[:ip] = s["portalIP"]
      props[:selector] = s["selector"]
      props[:ports] = s["ports"]

      return self
    end

    # @note call without parameters only when props are loaded
    def selector(user: nil)
      get_checked(user: user) unless props[:selector]

      return props[:selector]
    end

    # @note call without parameters only when props are loaded
    def url(user: nil)
      get_checked(user: user) if !props[:ip] || !props[:ports]

      return "#{props[:ip]}:#{props[:ports][0]["port"]}"
    end

    # @note call without parameters only when props are loaded
    def ip(user: nil)
      get_checked(user: user) if !props[:ip]

      return props[:ip]
    end

    ############### deal with comparison ###############
    def env
      project.env
    end

    def ==(s)
      s.kind_of?(self.class) && name == s.name && project == s.project
    end
    alias eql? ==

    def hash
      :service.hash ^ name.hash ^ project.hash
    end
  end
end
