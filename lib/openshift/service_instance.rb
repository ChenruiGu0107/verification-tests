module CucuShift
  # represents an OpenShift ConfigMap
  class ServiceInstance < ProjectResource
    RESOURCE = "serviceinstances"

    # see #raw_resource
    def metadata(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('metadata')
    end

    def uid(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('metadata', 'uid')
    end

    def labels(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('metadata', 'labels')
    end

    def annotations(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('metadata', 'annotations')
    end

    def generation(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('metadata', 'generation')
    end

    def namespace(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('metadata', 'namespace')
    end

    def spec(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('spec')
    end

    def cluster_service_class_external_name(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('spec', 'clusterServiceClassExternalName')
    end

    def clsuter_service_class_ref(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('spec', 'clusterServiceClassRef')
    end

    def status(user: nil, cached: false, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('status')
    end

  end
end
