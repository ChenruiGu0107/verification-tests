# frozen_string_literal: true

require "stomp"
require "json"
require 'io/console' # for reading password without echo
require 'timeout' # to avoid freezes waiting for user input

require_relative "../common/load_path"
require 'common'

class STOMPBus
  include CucuShift::Common::Helper

  HOST_OPTS = [:login, :passcode, :host, :port, :ssl].freeze

  attr_reader :opts, :default_queue

  def initialize(**opts)
    service_name = opts.delete(:service_name) || :stomp_bus
    service_opts = conf[:services, service_name].dup
    service_hosts = service_opts.delete(:hosts)

    default_hosts = [{}]
    # see http://www.rubydoc.info/github/stompgem/stomp/Stomp/Client#initialize-instance_method
    default_opts = {:connect_timeout => 15, :start_timeout => 15, :reliable => false}
    param_hosts = opts.delete(:hosts) if Array === opts[:hosts]

    pile_of_opts = {}
    pile_of_opts.merge! self.class.load_env_vars
    pile_of_opts.merge! opts

    @default_queue = pile_of_opts.delete(:default_queue) ||
      service_opts.delete(:default_queue)

    if param_hosts
      hosts = param_hosts
    elsif pile_of_opts[:host] || pile_of_opts[:hosts]
      if pile_of_opts[:host]
        hosts = [{host: pile_of_opts.delete(:host)}]
      elsif pile_of_opts[:hosts]
        hosts = pile_of_opts.delete(:hosts).split(",").map(&:strip).map {|h|
          {host: h}
        }
      end
      if pile_of_opts[:port]
        hosts.each { |h|
          h[:port] = pile_of_opts[:port]
          h[:port] = Integer(h[:port]) if String === h[:port]
        }
      end
      if pile_of_opts[:ssl]
        hosts.each { |h|
          h[:ssl] = pile_of_opts[:ssl]
          h[:ssl] = to_bool(h[:ssl]) if String === h[:ssl]
        }
      end

      if service_hosts
        hosts.map! { |h| service_hosts.first.merge h }
      end
    elsif service_hosts
      hosts = service_hosts
    else
      raise "hosts not specified"
    end
    pile_of_opts.delete(:hosts)
    pile_of_opts.delete(:host)
    raise "bad hosts specification: #{hosts.inspect}" unless Array === hosts
    hosts.each { |h|
      raise "bad host specification: #{h.inspect}" unless Hash === h
    }

    common_host_opts = {}
    HOST_OPTS.each do |opt|
      common_host_opts[opt] = pile_of_opts.delete(opt) if pile_of_opts[opt]
    end
    unless common_host_opts[:login] && common_host_opts[:passcode] ||
        hosts.all? {|h| h[:login] && h[:passcode]}
      common_host_opts.merge! get_credentials
    end

    final_opts = default_opts.merge(service_opts).merge(pile_of_opts)
    final_opts[:hosts] = hosts.map { |h| h.merge common_host_opts }

    ## SSL options
    #  see https://docs.ruby-lang.org/en/2.4.0/OpenSSL/SSL/SSLContext.html
    if final_opts.dig(:sslctx_newparm, :ca_path)
      final_opts[:sslctx_newparm] = expand_private_path(
                                      final_opts[:sslctx_newparm][:ca_path])
    end

    # check if we have all the required options
    self.class.check_opts(final_opts)
    @opts = final_opts
  end

  def new_client
    Stomp::Client.new(opts)
  end

  def self.msg_to_str(msg)
    %{
    ------------------------------
    Headers:
#{JSON.pretty_generate msg.headers}
    Body:
#{msg.body}
    ------------------------------
    }
  end

  # method checks if all required options are in place
  def self.check_opts(opts)
    opts[:hosts].each do |host|
      miss_host_opts = HOST_OPTS - host.keys

      unless miss_host_opts.empty?
        raise "Your configuration is missing following host options: " \
          "#{miss_host_opts.join(", ")} Run the script with --help argument " \
          "for help"
      end
    end
  end

  private def get_credentials()
    opts = {}
    Timeout::timeout(120) {
      STDERR.puts "STOMP username (timeout in 2 minutes): "
      opts[:login] = STDIN.gets.chomp
    }
    STDERR.puts "STOMP Password: "
    opts[:passcode] = STDIN.noecho(&:gets).chomp

    return opts
  end

  # loads all the ENV variables if they exist
  def self.load_env_vars
    env_opts = {}
    env_prefix = "STOMP_BUS_"
    ENV.each do |var, value|
      if var.start_with?(env_prefix) && !value.empty?
        env_opt = var[env_prefix.length..-1].downcase.to_sym
        env_opts[env_opt] = value == "false" ? false : value
      end
    end

    if ENV["STOMP_BUS_CREDENTIALS"] && !ENV["STOMP_BUS_CREDENTIALS"].empty?
      opts[:login],opts[:passcode] = env_opts.delete(:credentials).split(":", 2)
    end

    return env_opts
  end
end
