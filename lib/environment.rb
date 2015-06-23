require 'cli_executor'
require 'admin_cli_executor'
require 'user_manager'
require 'host'

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

    # @param name [String] just a human readable identifier
    def initialize(**opts)
      @opts = opts
      @hosts = []
    end

    def user_manager
      @user_manager ||= CucuShift.const_get(opts[:user_manager]).new(self, **opts)
    end
    alias users user_manager

    def cli_executor
      @cli_executor ||= CucuShift.const_get(opts[:cli]).new(self, **opts)
    end

    def admin_cli_executor
      @admin_cli_executor ||= CucuShift.const_get(opts[:admin_cli]).new(self, **opts)
    end

    def clean_up
      @user_manager.clean_up if @user_manager
      @hosts.each {|h| h.clean_up } if @hosts
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
          raise "environment should have hosts with all openshift roles"
        end
      end
      return @hosts
    end
  end
end
