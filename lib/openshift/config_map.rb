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

    def value_of(key, user: nil, cached: true, quiet: false)
      self.data(user: user, cached: cached, quiet: quiet).dig(key)
    end

    # @param key [String] the key to set in the config map, make sure it is
    #   valid
    # @param value [String, Numeric, Boolean, nil] the value to set
    def set_value(key, value, user: nil, cached: true, quiet: false)
      unless key.class <= String
        raise "key must be string but it is #{key.inspect}"
      end

      case value
      when String, Numeric, TrueClass, FalseClass, nil
        # all is ok
      else
        raise "value must be String, Numeric, Boolean or nil"
      end

      res = default_user(user).cli_exec(
        :patch,
        resource: RESOURCE,
        resource_name: self.name,
        p: %@{"data": {#{key.to_json}: #{value.to_json}}}@
      )

      unless res[:success]
        detail = quiet ? res[:response] : "see log"
        raise "failed to patch config map: #{detail}"
      end
    end
  end
end
