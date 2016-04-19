require 'yaml'

require_relative 'resource'

module CucuShift
  # @note represents a Resource / OpenShift API Object
  class ClusterResource < Resource

    # creates a new OpenShift Cluster Resource from spec
    # @param by [CucuShift::User, CucuShift::ClusterAdmin] the user to create
    #   Resource as
    # @param spec [String, Hash] the Hash representaion of the API object to
    #   be created or a String path of a JSON/YAML file
    # @return [CucuShift::ResultHash]
    def self.create(by:, spec:, **opts)
      if spec.kind_of? String
        # assume a file path (TODO: be more intelligent)
        spec = YAML.load_file(spec)["metadata"]["name"]
      end
      name = spec["metadata"]["name"]
      create_opts = { f: '-', _stdin: spec.to_json, **opts }
      init_opts = {name: name, env: by.env}

      res = by.cli_exec(:create, **create_opts)
      res[:resource] = self.new(**init_opts)

      return res
    end

    ############### take care of object comparison ###############
    def ==(p)
      p.kind_of?(self.class) && name == p.name && env == p.env
    end
    alias eql? ==

    def hash
      :project.hash ^ name.hash ^ env.hash
    end
  end
end
