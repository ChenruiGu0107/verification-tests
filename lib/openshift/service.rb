require 'openshift/pod'
require 'openshift/project_resource'

module CucuShift
  # represents OpenShift v3 Service concept
  class Service < ProjectResource
    RESOURCE = "services"

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

    # @param cached [Boolean] does nothing, keep for compatibility
    # @return [CucuShift::ResultHash] with :success if at least one pod by
    #   selector is ready
    def ready?(user:, quiet: false, cached: false)
      if !selector(user: user, quiet: quiet) || selector.empty?
        raise "can't tell if ready for services without pod selector"
      end

      res = {}
      Pod.get_labeled(*selector,
                      user: user,
                      project: project,
                      quiet: quiet,
                      result: res) { |p, p_hash|
        p.ready?(user: user, cached: true)[:success]
      }

      return res
    end

    # @note call without user only when props are loaded; get object to refresh
    def selector(user: nil, quiet: false)
      get_checked(user: user, quiet: quiet) unless props.has_key?(:selector)

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
