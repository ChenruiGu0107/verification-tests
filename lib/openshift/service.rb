require 'openshift/project_resource'

module CucuShift
  # represents OpenShift v3 Service concept
  class Service < ProjectResource
    RESOURCE = "services"

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
  end
end
