require 'json'

require 'cli_executor'
require 'admin_cli_executor'
require 'cluster_admin'
require 'user_manager'
require 'host'
require 'http'
require 'net'
require 'rest'
require 'openshift/node'
require 'webauto/webconsole_executor'

module CucuShift
  # @note this class represents an OpenShift test environment and allows setting it up and in some cases creating and destroying it
  class Environment
    include Common::Helper

    attr_reader :opts

    # :master represents register, scheduler, etc.
    MANDATORY_OPENSHIFT_ROLES = [:master, :node]
    OPENSHIFT_ROLES = MANDATORY_OPENSHIFT_ROLES + [:lb, :etcd]

    # e.g. you call `#node_hosts to get hosts with the node service`
    OPENSHIFT_ROLES.each do |role|
      define_method("#{role}_hosts") do
        hosts.select {|h| h.has_role?(role)}
      end
    end

    # override generated method as etcd role not always defined
    def etcd_hosts
      etcd_list = hosts.select {|h| h.has_role?(:etcd)}
      if etcd_list.empty?
        master_hosts
      else
        etcd_list
      end
    end

    # @param opts [Hash] initialization options
    def initialize(**opts)
      @opts = opts
      @hosts = []
    end

    # return environment key, mainly useful for logging purposes
    def key
      opts[:key]
    end

    # environment may have pre-defined static users used for upgrade testing
    #   or other special purposes like admin user for example
    # @return [Hash<Hash>] a hash of user symbolic names pointing at a hash
    #   of user constructor parameters, e.g.
    #   {u1: {username: "user1", password: "asdf"}, u2: {token: "..."}}
    private def static_users
      opts[:static_users_map] || {}
    end

    # @return [Hash] user constructor parameters
    # @see #static_users
    def static_user(symbolic_name)
      static_users[symbolic_name.to_sym]
    end

    def user_manager
      @user_manager ||= case opts[:user_manager]
      when nil, "", "auto"
        case opts[:user_manager_users]
        when nil, ""
          raise "automatic OCP htpasswd user creaton not implemented yet"
        when /^pool:/
          PoolUserManager.new(self, **opts)
        else
          StaticUserManager.new(self, **opts)
        end
      else
        CucuShift.const_get(opts[:user_manager]).new(self, **opts)
      end
    end
    alias users user_manager

    def cli_executor
      @cli_executor ||= CucuShift.const_get(opts[:cli]).new(self, **opts)
    end

    def admin
      @admin ||= admin? ? ClusterAdmin.new(env: self) : raise("no admin rights")
    end

    def admin_cli_executor
      @admin_cli_executor ||= if admin?
        CucuShift.const_get(opts[:admin_cli]).new(self, **opts)
                              else
        raise "we cannot run as admins in this environment"
                              end
    end

    def webconsole_executor
      @webconsole_executor ||= WebConsoleExecutor.new(self, **opts)
    end

    # @return [Boolean] true if we have means to execute admin cli commands and
    #   rest requests
    def admin?
      opts[:admin_cli] && ! opts[:admin_cli].empty?
    end

    def rest_request_executor
      Rest::RequestExecutor
    end

    def api_proto
      opts[:api_proto] || "https"
    end

    def api_port
      opts[:api_port] || "80"
    end

    def api_port_str
      api_port == '80' ? "" : ":#{opts[:api_port]}"
    end

    def api_hostname
      api_host.hostname
    end

    def api_host
      opts[:api_host] || ((lb_hosts.empty?) ? master_hosts.first : lb_hosts.first)
    end

    def api_endpoint_url
      opts[:api_url] || "#{api_proto}://#{api_hostname}#{api_port_str}"
    end

    def web_console_url
      opts[:web_console_url] || api_endpoint_url
    end

    # naming scheme is https://logs.<cluster_id>.openshift.com
    # only return the predefined url if we don't have admin access.
    def logging_console_url
      opts[:logging_console_url] || web_console_url.gsub('console.', 'logs.')
    end

    # naming scheme is
    # https://metrics.<cluster_id>.openshift.com/hawkular/metrics
    def metrics_console_url
      opts[:metrics_console_url] || web_console_url.gsub('console.', 'metrics.') + "/hawkular/metrics"
    end

    # @return docker repo host[:port] used to launch env by checking one of the
    #   system image streams in the `openshift` project
    # @note dc/router could be used as well but will require admin
    def system_docker_repo
      return @system_docker_repo if @system_docker_repo
      is = ImageStream.new(name: "jenkins",
                           project: Project.new(name: "openshift", env: self))
      image_ref = is.latest_tag_docker_image_reference(user: users[0])
      first_element = image_ref.split("/", 2).first
      if first_element.include? "."
        return @system_docker_repo = first_element + "/"
      else
        return @system_docker_repo = ""
      end
    end

    # helper parser
    def parse_version(ver_str)
      ver = ver_str.sub(/^v/,"")
      if ver !~ /^[\d.]+$/
        raise "version '#{ver}' does not match /^[\d.]+$/"
      end
      ver = ver.split(".").reject(&:empty?).map(&:to_i)
      [ver[0], ver[1]]
    end

    # returns the major and minor version using REST
    # @return raw version, major and minor number
    def get_version(user:)
      obtained = user.rest_request(:version)
      if obtained[:request_opts][:url].include?("/version/openshift") &&
          !obtained[:success]
        # seems like pre-3.3 version, lets hardcode to 3.2
        obtained[:props] = {}
        obtained[:props][:openshift] = "v3.2"
        @major_version = obtained[:props][:major] = 3
        @minor_version = obtained[:props][:minor] = 2
      elsif obtained[:success]
        @major_version = obtained[:props][:major].to_i
        @minor_version = obtained[:props][:minor].to_i
      else
        raise "error getting version: #{obtained[:error].inspect}"
      end
      return obtained[:props][:openshift].sub(/^v/,""), @major_version.to_s, @minor_version.to_s
    end

    # some rules and logic to compare given version to current environment
    # @return [Integer] less than 0 when env is older, 0 when it is comparable,
    #   more than 0 when environment is newer
    # @note for compatibility reasons we only compare only major and minor
    def version_cmp(version, user:)
      # figure out local environment version
      if @major_version && @minor_version
        # all is fine already
      elsif opts[:version]
        # enforced environment version
        @major_version, @minor_version = parse_version(opts[:version])
      else
        # try to obtain version
        raw_version, @major_version, @minor_version = get_version(user: user)
      end

      @major_version = Integer(@major_version)
      @minor_version = Integer(@minor_version)

      major, minor = parse_version(version)

      # presently handle only major ver `3`for OCP and `1` for origin
      bad_majors = [@major_version, major] - [1,3]
      unless bad_majors.empty?
        raise "do not know how to compare major versions #{bad_majors}"
      end

      # lets compare minor version
      return @minor_version - minor
    end

    def version_ge(version, user:)
      version_cmp(version, user: user) >= 0
    end

    def version_gt(version, user:)
      version_cmp(version, user: user) > 0
    end

    def version_le(version, user:)
      version_cmp(version, user: user) <= 0
    end

    def version_lt(version, user:)
      version_cmp(version, user: user) < 0
    end

    def version_eq(version, user:)
      version_cmp(version, user: user).equal? 0
    end

    # obtain router detals like default router subdomain and router IPs
    # @param user [CucuShift::User]
    # @param project [CucuShift::project]
    def get_routing_details(user:, project:)
      clean_project = false

      service_res = Service.create(by: user, project: project, spec: 'https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/service_with_selector.json')
      raise "cannot create service" unless service_res[:success]
      service = service_res[:resource]

      ## create a dummy route
      route = CucuShift::Route.new(name: "selector-service", service: service)
      route_res = route.create(by: user)
      raise "cannot create route" unless route_res[:success]

      fqdn = route.dns(by: user)
      opts[:router_subdomain] = fqdn.split('.',2)[1]
      opts[:router_ips] = Common::Net.dns_lookup(fqdn, multi: true)

      raise unless route.delete(by: user)[:success]
      raise unless service.delete(by: user)[:success]
    end

    def router_ips(user:, project:)
      unless opts[:router_ips]
        get_routing_details(user: user, project: project)
      end

      return opts[:router_ips]
    end

    def router_default_subdomain(user:, project:)
      unless opts[:router_subdomain]
        get_routing_details(user: user, project: project)
      end
      return opts[:router_subdomain]
    end

    # get environment supported API paths
    def api_paths
      return @api_paths if @api_paths

      opts = {:max_redirects=>0,
              :url=>api_endpoint_url,
              :method=>"GET"
      }
      res = Http.http_request(**opts)

      unless res[:success]
        raise "could not get API paths, see log"
      end

      return @api_paths = JSON.load(res[:response])["paths"]
    end

    # get latest API version supported by server
    def api_version
      return @api_version if @api_version
      idx = api_paths.rindex{|p| p.start_with?("/api/v")}
      return @api_version = api_paths[idx][5..-1]
    end

    def nodes(user: admin, refresh: false)
      return @nodes if @nodes && !refresh

      @nodes = Node.list(user: user)
    end

    # selects the correct configured IAAS provider
    def iaas
      # check if we have a ssh connection to the master nodes.
      self.master_hosts.each { |master|
        raise "The master node #{master.hostname}, is not accessible via SSH!" unless master.accessible?[:success]
      }
      @iaas ||= IAAS.select_provider(self)
    end

    def clean_up
      @user_manager.clean_up if @user_manager
      @hosts.each {|h| h.clean_up } if @hosts
      @cli_executor.clean_up if @cli_executor
      @admin_cli_executor.clean_up if @admin_cli_executor
      @webconsole_executor.clean_up if @webconsole_executor
    end
  end

  # a quickly made up environment class for the PoC
  class StaticEnvironment < Environment
    def initialize(**opts)opts[:masters]
      super

      if ! opts[:hosts] || opts[:hosts].empty?
        raise "environment should have at least one host running all services"
      end
    end

    def hosts
      if @hosts.empty?
        hlist = []
        # generate hosts based on spec like: hostname1:role1:role2,hostname2:r3
        opts[:hosts].split(",").each do |host|
          # TODO: might do convenience type to class conversion
          # TODO: we might also consider to support setting type per host
          host_type = opts[:hosts_type]
          hostname, garbage, roles = host.partition(":")
          roles = roles.split(":").map(&:to_sym)
          hlist << CucuShift.const_get(host_type).new(hostname, **opts, roles: roles)
        end

        missing_roles = MANDATORY_OPENSHIFT_ROLES.reject{|r| hlist.find {|h| h.has_role?(r)}}
        unless missing_roles.empty?
          raise "environment does not have hosts with roles: " +
            missing_roles.to_s
        end

        @hosts.concat hlist
      end
      return @hosts
    end
  end
end
