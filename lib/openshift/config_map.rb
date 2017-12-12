module CucuShift
  # represents an OpenShift ConfigMap
  class ConfigMap < ProjectResource
    RESOURCE = 'configmaps'

    # see #raw_resource
    def data(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('data')
    end

    # # @name: the name to the data hash element we want to be parsed
    # # @return: a parsed YAML in the form of a Hash
    # def parsed_xml_data(user: nil, name: nil, cached: true, quiet: false)
    #   raw_data = self.data(user: user, cached: cached, quiet: quiet)
    #   parsed_data = YAML.load(raw_data.dig(name))
    #   return parsed_data
    # end

    def namespace(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('metadata', 'namespace')
    end

    def labels(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('metadata', 'labels')
    end

    def created(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('metadata', 'creationTimestamp')
    end
  end
end
