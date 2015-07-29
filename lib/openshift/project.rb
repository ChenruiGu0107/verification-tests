require 'yaml'
require 'base_helper'

module CucuShift
  # @note represents an OpenShift environment project
  class Project
    include Common::Helper
    include Common::UserObjectHelper

    attr_reader :props, :name, :env

    def initialize(name:, env:, props: {})

      if name.nil? || env.nil?
        raise "project need name and environment to be identified"
      end

      @name = name.freeze
      @env = env
      @props = props
    end

    def visible?(user:)
      res = cli_exec(as: user, key: :get, resource_name: name, resource: "project")
      case res[:response]
      when /DISPLAY NAME/, /not found/
        return true
      when /cannot get projects in project/
        return false
      else
        raise "error getting project existence: #{res[:response]}"
      end
    end
    alias exists? visible?

    def get(user:)
      res = cli_exec(as: user, key: :get,
                resource_name: name,
                resource: "project",
                output: "yaml")

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        update_from_project_hash(res[:parsed])
      end

      return res
    end
    alias populate_props get

    # list projects for a user
    # @param user [CucuShift::User] the user who's projects we want to list
    # @return [Array<Project>]
    # @note raises error on issues
    def self.list(user:)
      res = user.cli_exec(:get, resource: "projects", output: "yaml")
      if res[:success]
        list = YAML.load(res[:response])["items"]
        return list.map { |project_hash|
          self.from_project_hash(user.env, project_hash)
        }
      else
        logger.error(res[:response])
        raise "error getting projects for user: '#{user}'"
      end
    end

    # creates a new project
    # @param by [CucuShift::User, :admin] the user to create project as
    # @param name [String] the name of the project
    # @return [CucuShift::ResultHash]
    def self.create(by: , name:, **opts)
      self.new(name: name, env: by.env).create(by: by, **opts)
    end

    # creates new project from an OpenShift API Project object
    def self.from_project_hash(env, project_hash)
      self.new(env: env, name: project_hash["metadata"]["name"]).
                                update_from_project_hash(project_hash)
    end

    def update_from_project_hash(project_hash)
      h = project_hash["metadata"]
      props[:uid] = h["uid"]
      props[:description] = h["annotations"]["openshift.io/description"]
      props[:display_name] = h["annotations"]["openshift.io/display-name"]

      return self # mainly to help ::from_project_hash
    end

    def delete(by:)
      cli_exec(as: by, key: :delete, object_type: "project", object_name_or_id: name)
    end

    # creates project as defined in this object
    def create(by:, **opts)
      # note that search for users is only done inside the set of users
      #   currently used by scenario; we don't expect scenario to know
      #   usernames before a user is actually requested from the user_manager
      if by == :admin && ! env.users.by_name(opts[:admin])
        raise "creating project as admin without administrators may easily lead to project leaks in the test framework, avoid doing so"
      end

      res = cli_exec(as: by, key: :new_project, project_name: name, **opts)
      res[:project] = self
      return res
    end

    def wait_to_be_created(user, seconds = 30)
      return wait_for(seconds) {
        exists?(user: user)
      }
    end

    def wait_to_be_deleted(user, seconds = 30)
      return wait_for(seconds) {
        ! exists?(user: user)
      }
    end

    def ==(p)
      p.kind_of?(self.class) && name == p.name && env == p.env
    end
    alias eql? ==

    def hash
      :project.hash ^ name.hash ^ env.hash
    end
  end
end
