require 'yaml'

require 'openshift/project_resource'

require 'openshift/pod'
require 'openshift/route'

module CucuShift
  # represents OpenShift v3 Service concept
  class Service < ProjectResource
    RESOURCE = "services"

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that ca nchange at any time like status and spec
    def update_from_api_object(service_hash)
      super

      m = service_hash["metadata"]
      s = service_hash["spec"]

      unless m["name"] == name
        raise "looks like a hash from another service: #{name} vs #{m["name"]}"
      end

      props[:created] = m["creationTimestamp"]
      props[:labels] = m["labels"]
      props[:ip] = s["portalIP"] || s["clusterIP"]
      props[:selector] = s["selector"]
      props[:ports] = s["ports"]

      return self
    end

    # @return [CucuShift::ResultHash] with :success if at least one pod by
    #   selector is ready
    def ready?(user: nil, quiet: false, cached: false)
      res = {}
      pods = pods(user: user, quiet: quiet, cached: cached, result: res)
      pods.select! { |p| p.ready?(user: user, cached: true)[:success] }
      res[:success] = pods.size > 0
      return res
    end

    # @return [Array<Pod>]
    def pods(user: nil, quiet: false, cached: true, result: {})
      if !selector(user: user, quiet: quiet) || selector.empty?
        raise "can't tell if ready for services without pod selector"
      end

      unless cached && props[:pods]
        props[:pods] = Pod.get_labeled(*selector,
                                       user: default_user(user),
                                       project: project,
                                       quiet: quiet,
                                       result: result)
      end
      return props[:pods]
    end

    # @param by [CucuShift::User] the user to create route with
    def expose(user: nil, port: nil)
      opts = {
        output: :yaml,
        resource: :service,
        resource_name: name,
        namespace: project.name,
      }
      opts[:port] = port if port
      res = default_user(user).cli_exec(:expose, **opts)

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        route = Route.from_api_object(project, res[:parsed])
        route.service = self
        return route
      else
        raise "could not expose service: #{res[:response]}"
      end
    end

   # @note call without user only when props are loaded; get object to refresh
    def selector(user: nil, cached: true, quiet: false)
      return get_cached_prop(prop: :selector, user: user, cached: cached, quiet: quiet)
    end

    # @note call without parameters only when props are loaded
    def url(user: nil, cached: true, quiet: false)
      ip = get_cached_prop(prop: :ip, user: user, cached: cached, quiet: quiet)
      ports = get_cached_prop(prop: :ports, user: user, cached: cached, quiet: quiet)

      return "#{ip}:#{ports[0]["port"]}"
    end

    # @note call without parameters only when props are loaded
    def ip(user: nil, cached: true, quiet: false)
      return get_cached_prop(prop: :ip, user: user, cached: cached, quiet: quiet)
    end
    # @note call without parameters only when props are loaded
    # return @Array of ports
    def ports(user: nil, cached: true, quiet: false)
      return get_cached_prop(prop: :ports, user: user, cached: cached, quiet: quiet)
    end

    # @note call without parameters only when props are loaded
    def node_port(user: nil, port:, cached: true, quiet: false)
      node_port = nil
      ports = get_cached_prop(prop: :ports, user: user, cached: cached, quiet: quiet)
      ports.each do | p |
        node_port = p['nodePort'] if p['port'] == port
      end
      return node_port
    end
  end
end
