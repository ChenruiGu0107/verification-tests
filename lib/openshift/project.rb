require 'yaml'

require 'base_helper'
require 'openshift/pod'
require 'openshift/build'

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

    def empty?(user:)
      res = cli_exec(as: user, key: :status, n: name)

      res[:success] = res[:response] =~ /ou have no.+services.+deployment.+configs/
      return res
    end

    def get(user:)
      res = cli_exec(as: user, key: :get,
                resource_name: name,
                resource: "project",
                output: "yaml")

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        update_from_api_object(res[:parsed])
      end

      return res
    end
    alias reload get

    # list projects for a user
    # @param user [CucuShift::User] the user who's projects we want to list
    # @return [Array<Project>]
    # @note raises error on issues
    def self.list(user:)
      res = user.cli_exec(:get, resource: "projects", output: "yaml")
      if res[:success]
        list = YAML.load(res[:response])["items"]
        return list.map { |project_hash|
          self.from_api_object(user.env, project_hash)
        }
      else
        logger.error(res[:response])
        raise "error getting projects for user: '#{user}'"
      end
    end

    # creates a new project
    # @param by [CucuShift::User, CucuShift::ClusterAdmin] the user to create project as
    # @param name [String] the name of the project
    # @return [CucuShift::ResultHash]
    def self.create(by: , name:, **opts)
      self.new(name: name, env: by.env).create(by: by, **opts)
    end

    # creates new project from an OpenShift API Project object
    def self.from_api_object(env, project_hash)
      self.new(env: env, name: project_hash["metadata"]["name"]).
                                update_from_api_object(project_hash)
    end

    def update_from_api_object(project_hash)
      h = project_hash["metadata"]
      props[:uid] = h["uid"]
      props[:description] = h["annotations"]["openshift.io/description"]
      props[:display_name] = h["annotations"]["openshift.io/display-name"]

      return self # mainly to help ::from_api_object
    end

    def delete(by:)
      cli_exec(as: by, key: :delete, object_type: "project", object_name_or_id: name)
    end

    # creates project as defined in this object
    def create(by:, **opts)
      # note that search for users is only done inside the set of users
      #   currently used by scenario; we don't expect scenario to know
      #   usernames before a user is actually requested from the user_manager
      if by.kind_of?(ClusterAdmin) && ! env.users.by_name(opts[:admin])
        raise "creating project as admin without administrators may easily lead to project leaks in the test framework, avoid doing so"
      elsif _via = opts.delete(:_via) == :web 
        res = webconsole_exec(as: by, action: :new_project, project_name: name, **opts)
      else

        res = cli_exec(as: by, key: :new_project, project_name: name, **opts)
      end
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

    ############### related to objects owned by this project ###############
    def get_pods(by:, **get_opts)
      Pod.list(user: by, project: self, **get_opts)
    end
    alias_method :pods, :get_pods

    def get_builds(by:, **get_opts)
      Build.list(user: by, project: self, **get_opts)
    end

    # def get_services
    # end

    #oc delete all -l app=hi -n ie2yc
    #buildconfigs/ruby-hello-world
    #builds/ruby-hello-world-1
    #imagestreams/mysql-55-centos7
    #imagestreams/ruby-20-centos7
    #imagestreams/ruby-hello-world
    #deploymentconfigs/mysql-55-centos7
    #deploymentconfigs/ruby-hello-world
    #services/mysql-55-centos7
    #services/ruby-hello-world
    # @param labels [String, Array<String,String>, read carefully description of
    #   [CucuShift::Common::BaseHelper#selector_to_label_arr]
    # @param by [User] the user to execute operation with
    # @param cmd_opts [**Hash] command line options overrides
    def delete_all_labeled(*labels, by:, **cmd_opts)
      default_opts = {
        object_type: :all,
        l: selector_to_label_arr(*labels),
        n: name
      }
      opts = default_opts.merge cmd_opts

      return cli_exec(as: by, key: :delete, **opts)
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
