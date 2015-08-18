require 'json'

require 'cli_executor'
require 'admin_cli_executor'
require 'cluster_admin'
require 'user_manager'
require 'host'
require 'rest'
require 'http'

module CucuShift
  # @note this class represents an OpenShift test environment and allows setting it up and in some cases creating and destroying it
  class Environment
    attr_reader :opts

    # :master represents register, scheduler, etc.
    OPENSHIFT_ROLES = [:node, :etcd, :master]

    # e.g. you call `#node_hosts to get hosts with the node service`
    OPENSHIFT_ROLES.each do |role|
      define_method("#{role}_hosts") do
        hosts.select {|h| h.has_role?(role)}
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

    def user_manager
      @user_manager ||= CucuShift.const_get(opts[:user_manager]).new(self, **opts)
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
      opts[:api_host] || master_hosts.first
    end

    def api_endpoint_url
      opts[:api_url] || "#{api_proto}://#{api_hostname}#{api_port_str}"
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

    def clean_up
      @user_manager.clean_up if @user_manager
      @hosts.each {|h| h.clean_up } if @hosts
      @cli_executor.clean_up if @cli_executor
      @admin_cli_executor.clean_up if @admin_cli_executor
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
        # generate hosts based on spec like: hostname1:role1:role2,hostname2:r3
        opts[:hosts].split(",").each do |host|
          # TODO: might do convenience type to class conversion
          # TODO: we might also consider to support setting type per host
          host_type = opts[:hosts_type]
          hostname, garbage, roles = host.partition(":")
          roles = roles.split(":").map(&:to_sym)
          @hosts << CucuShift.const_get(host_type).new(hostname, **opts, roles: roles)
        end

        unless OPENSHIFT_ROLES.all? {|r| @hosts.find {|h| h.has_role?(r)}}
          raise "environment does not have hosts with roles: " +
            "#{OPENSHIFT_ROLES.select{|r| @hosts.find {|h| h.has_role?(r)}}}"
        end
      end
      return @hosts
    end
  end
end
