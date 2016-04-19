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

    def visible?(user:, result: {})
      result.clear.merge!(get(user: user))
      if result[:success]
        return true
      elsif result[:responce] =~ /not found/
        return false
      else
        # e.g. when called by user without rights to list Resource
        raise "error getting #{self.class.name} '#{name}' existence: #{result[:response]}"
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

    # @return [CucuShift::ResultHash]
    def wait_to_appear(user, seconds = 30)
      res = {}
      wait_for(seconds) {
        exists?(user: user, result: res)
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
    alias wait_to_disappear disappeared?

    def status_raw(user:, cached: false)
      if cached && props[:status]
        return props[:status]
      else
        get(user: user)
        raise("#{self.class}} does not handle status") unless props[:status]
        return props[:status]
      end
    end

    def phase(user: , cached: false)
      return status_raw(user: user, cached: cached)["phase"].downcase.to_sym
      # TODO: implement `missing` phase?
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
