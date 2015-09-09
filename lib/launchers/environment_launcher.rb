require 'socket'

require 'common'
require_relative 'openstack'

module CucuShift
  class EnvironmentLauncher
    include Common::Helper

    # @param os_opts [Hash] options to pass to [OpenStack::new]
    # @param names [Array<String>] array of names to give to new machines
    # @return [Hash] a hash of name => hostname pairs
    def launch_os_instances(names:, use_hostnames: true, **os_opts)
      os_server = CucuShift::OpenStack.new(**os_opts)
      res = {}
      names.each { |name|
        _, res[name] = os_server.create_instance(name)
        res[name] = reverse_lookup(res[name]) unless use_hostnames
        sleep 10 # why?
      }
      sleep 60 # why?
      return res
    end

    def reverse_lookup(ip)
      res = Socket.getaddrinfo(ip, 0, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME, true)

      if res.size != 1
        raise "not sure how to handle multiple entries, please report to author"
      end

      return res[0][1] # btw this might be same IP if reverse entry missing
    end

    def ansible_install(hosts_spec)
      # TODO:
    end

    def launch(**opts)
      # TODO:
    end

    # update launch options from ENV
    def env_options(opts)
      # TODO:
    end
  end
end
