require 'yaml'

require 'common'

module CucuShift
  # @note represents a Resource / OpenShift API Object
  class Resource
    include Common::Helper
    include Common::UserObjectHelper

    # this needs to be set per sub class
    # represents the string we use with `oc get ...`
    # also represents string we use in REST call URL path
    # e.g. RESOURCE = "pods"

    attr_reader :props, :name

    def env
      raise "need to be implemented by subclass"
    end

    def visible?(user:)
      res = get(user: user)
      if res[:success]
        return true
      elsif res[:responce] =~ /not found/
        return false
      else
        # e.g. when called by user without rights to list Resource
        raise "error getting to knoe #{self.class.name} existence: #{res[:response]}"
      end
    end
    alias exists? visible?

    def get_checked(user:)
      res = get(user: user)
      unless res[:success]
        logger.error(res[:response])
        raise "could not get self.class::RESOURCE"
      end
      return res
    end

    def get(user:)
      get_opts = {
        as: user, key: :get,
        resource_name: name,
        resource: self.class::RESOURCE,
        output: "yaml"
      }

      if defined? project
        get_opts[:namespace] = project.name
      end

      res = cli_exec(get_opts)

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        update_from_api_object(res[:parsed])
      end

      return res
    end
    alias reload get

    # creates a new Resource CucuShift object from spec
    # @param by [CucuShift::User, CucuShift::ClusterAdmin] the user to create
    #   Resource as
    # @param spec [String, Hash] the API object to create PV or a JSON/YAML file
    # @return [CucuShift::ResultHash]
    def self.create(by:, spec:, **opts)
      raise "need to be implemented by subclass"
    end

    # @return [CucuShift::ResultHash]
    def wait_to_appear(user, seconds)
      res = nil

      success = wait_for(seconds) {
        res = get(user: user)
        res[:success]
      }

      return res
    end
    alias wait_to_be_created wait_to_appear

    # @return [Boolean]
    def disappeared?(user, seconds = 30)
      return wait_for(seconds) {
        ! visible?(user: user)
      }
    end

    # TODO: implement the #status? and #wait_till_status like methods

    ############### take care of object comparison ###############
    def ==(resource)
      raise "need to be implemented by subclass"
    end
    alias eql? ==

    def hash
      raise "need to be implemented by subclass"
    end
  end
end
