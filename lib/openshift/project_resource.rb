require 'json'
require 'yaml'

require 'openshift/resource'

module CucuShift
  # @note represents an OpenShift namespaced Resource (part of a Project)
  class ProjectResource < Resource
    attr_reader :project

    # RESOURCE = "define me"

    # @param name [String] name of the resource
    # @param project [CucuShift::Project] the project we belong to
    # @param props [Hash] additional properties of the resource
    def initialize(name:, project:, props: {})
      @name = name
      @project = project
      @props = props
    end

    def env
      project.env
    end

    # creates a new OpenShift Project Resource via API
    # @param by [CucuShift::User, CucuShift::ClusterAdmin] the user to create
    #   ProjectResource as
    # @param project [CucuShift::Project] the namespace for the new resource
    # @param spec [String, Hash] the Hash object to create project resource or
    #   a String path of a JSON/YAML file
    # @return [CucuShift::ResultHash]
    def self.create(by:, project:, spec:, **opts)
      if spec.kind_of? String
        # assume a file path (TODO: be more intelligent)
        spec = YAML.load_file(spec)["metadata"]["name"]
      end
      name = spec["metadata"]["name"]

      res = cli_exec(as: by, n: project.name, key: :create, f: '-',
                                              _stdin: spec.to_json, **opts)
      res[:resource] = self.new(name: name, project: project)

      return res
    end

    # list objects
    # @param user [CucuShift::User] the user who can list these resources
    # @param project [CucuShift::Project] the project to list objects in
    # @return [Array<Resource>]
    # @note raises error on issues
    def self.list(user:, project:)
      res = user.cli_exec(:get, resource: self.class::RESOURCE, output: "yaml",
                          namespace: project.name)
      if res[:success]
        list = YAML.load(res[:response])["items"]
        return list.map { |resource_hash|
          self.from_api_object(project, resource_hash)
        }
      else
        logger.error(res[:response])
        raise "error getting #{self.class::RESOURCE}"
      end
    end

    # creates new ProjectResource from an OpenShift API object hash
    def self.from_api_object(project, resource_hash)
      self.new(project: project, name: resource_hash["metadata"]["name"]).
                                update_from_api_object(resource_hash)
    end

    def delete(by:)
      cli_exec(as: by, key: :delete, object_type: self.class::RESOURCE,
               object_name_or_id: name, namespace: project.name)
    end

    ############### take care of object comparison ###############
    def ==(p)
      p.kind_of?(self.class) && name == p.name && project == p.project
    end
    alias eql? ==

    def hash
      self.class.name.hash ^ name.hash ^ project.hash
    end
  end
end
