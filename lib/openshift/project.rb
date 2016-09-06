require 'yaml'

require_relative 'build'
require_relative 'cluster_resource'
require_relative 'pod'

module CucuShift
  # @note represents an OpenShift environment project
  class Project < ClusterResource
    RESOURCE = "projects".freeze
    SYSTEM_PROJECTS = [ "openshift-infra".freeze,
                        "default".freeze,
                        "management-infra".freeze,
                        "openshift".freeze ]

    attr_reader :props, :name, :env

    # @override
    def visible?(user:, result: {}, quiet: false)
      result.clear.merge!(get(user: user, quiet: quiet))
      if result[:success]
        return true
      else
        case  result[:response]
        when /cannot get projects in project/, /not found/
          return false
        else
          raise "error getting project '#{name}' existence: #{result[:response]}"
        end
      end
    end
    alias exists? visible?

    def empty?(user:)
      res = cli_exec(as: user, key: :status, n: name)

      res[:success] = res[:response] =~ /ou have no.+services.+deployment.+configs/
      return res
    end

    # @note call without parameters only when props are loaded
    # @return a Ruby Range object i.e. the API returns a string 10120000/1000, string transformed into a ruby Range object
    def uid_range(user:, cached: true, quiet: false)
      range_string = get_cached_prop(prop: :scc_uid_range, user: user, cached: cached, quiet: quiet)
      uids = range_string.split('/').map { |n| Integer(n) }
      uid_range = (uids[0]...uids[0] + uids[1])
      return uid_range
    end

    # scc's mcs (https://www.centos.org/docs/5/html/Deployment_Guide-en-US/sec-mcs-ov.html)
    def mcs(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :scc_mcs, user: user, cached: cached, quiet: quiet)
    end

    # @return a Ruby Range object i.e. the API returns a string 10120000/1000, string transformed into a ruby Range object
    def supplemental_groups(user:, cached: true, quiet: false)
      range_string = get_cached_prop(prop: :scc_supplemental_groups, user: user, cached: cached, quiet: quiet)
      groups = range_string.split('/').map { |n| Integer(n) }
      group_range = (groups[0]...groups[0] + groups[1])
      return group_range
    end
    # creates a new project
    # @param by [CucuShift::User, CucuShift::ClusterAdmin] the user to create project as
    # @param name [String] the name of the project
    # @return [CucuShift::ResultHash]
    def self.create(by:, name: nil, **opts)
      if name
        res = self.new(name: name, env: by.env).create(by: by, **opts)
        res[:resource] = res[:project]
      else
        res = super(by: by, **opts)
        res[:project] = res[:resource]
      end
      return res
    end

    def update_from_api_object(project_hash)
      h = project_hash["metadata"]
      props[:uid] = h["uid"]
      props[:description] = h["annotations"]["openshift.io/description"]
      props[:display_name] = h["annotations"]["openshift.io/display-name"]
      props[:scc_uid_range] = h["annotations"]["openshift.io/sa.scc.uid-range"]
      props[:scc_mcs] = h["annotations"]["openshift.io/sa.scc.mcs"]
      props[:scc_supplemental_groups] = h["annotations"]["openshift.io/sa.scc.supplemental-groups"]
      props[:status] = project_hash["status"]

      return self # mainly to help ::from_api_object
    end

    def active?(user:, cached: false)
      phase(user: user, cached: cached) == :active
    end

    # creates project as defined in this object
    def create(by:, **opts)
      # note that search for users is only done inside the set of users
      #   currently used by scenario; we don't expect scenario to know
      #   usernames before a user is actually requested from the user_manager
      if by.kind_of?(ClusterAdmin) && ! env.users.by_name(opts[:admin])
        raise "creating project as admin without administrators may easily lead to project leaks in the test framework, avoid doing so"
      elsif opts.delete(:_via) == :web
        res = webconsole_exec(as: by, action: :new_project, project_name: name, **opts)
      else
        res = cli_exec(as: by, key: :new_project, project_name: name, **opts)
      end
      res[:project] = self
      return res
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
  end
end
