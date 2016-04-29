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
        spec = YAML.load_file(spec)
      end
      name = spec["metadata"]["name"]
      create_opts = { f: '-', _stdin: spec.to_json, **opts }
      init_opts = {name: name, env: by.env}

      res = by.cli_exec(:create, **create_opts)
      res[:resource] = self.new(**init_opts)

      return res
    end

    # creates new resource from an OpenShift API Project object
    # @note requires subclass to define `#update_from_api_object`
    def self.from_api_object(env, resource_hash)
      self.new(env: env, name: resource_hash["metadata"]["name"]).
                                update_from_api_object(resource_hash)
    end

    # list resources by a user
    # @param user [CucuShift::User] the user who's projects we want to list
    # @param result [ResultHash] can be used to get full result hash from op
    # @return [Array<Resouece>]
    # @note raises error on issues
    def self.list(user:, quiet: false, result: {})
      res = result
      res.merge! user.cli_exec(:get, resource: self::RESOURCE, output: "yaml",
                          _quiet: quiet)
      if res[:success]
        list = YAML.load(res[:response])["items"]
        return list.map { |project_hash|
          self.from_api_object(user.env, project_hash)
        }
      else
        logger.error(res[:response])
        raise "error getting #{self::RESOURCE} for user: '#{user}'"
      end
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
