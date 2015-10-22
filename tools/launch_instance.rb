#!/usr/bin/env ruby
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")

"""
Utility to launch OpenShift v3 instances
"""

require 'base64'
require 'commander'
require 'uri'

require 'common'
require 'launchers/env_launcher'
require 'launchers/openstack'

module CucuShift
  class EnvLauncherCli
    include Commander::Methods
    include Common::Helper

    def initialize
      always_trace!
    end

    def run
      program :name, 'EnvLauncherCli'
      program :version, '0.0.1'
      program :description, 'Tool to launch OpenShift Environment'

      #Commander::Runner.instance.default_command(:gui)
      default_command :launch

      global_option('-c', '--config KEY', 'default config options should be read from?')
      global_option('-l', '--launched_instances_name_prefix', 'if instances are launched, use this prefix')
      global_option('-n', '--node_num', "number of nodes to launch")
      global_option('-d', '--user_data', "file containing user instances' data")

      command :launch do |c|
        c.syntax = 'env_launcher_cli.rb launcher -c [ENV|<conf keyword>]'
        c.description = 'launch an instance'
        c.action do |args, options|
          say 'launching..'
          case options.config
          when 'env', 'ENV'
            el = EnvLauncher.new

            ## set some opts based on Environment Variables
            options.node_num ||= ENV['NODE_NUM'].to_i
            options.launched_instances_name_prefix ||= ENV['INSTANCE_NAME_PREFIX']

            ## process user data
            if ENV['INSTANCES_USER_DATA'] && !ENV['INSTANCES_USER_DATA'].empty?
              options.user_data ||= ENV['INSTANCES_USER_DATA']
            end
            if options.user_data
              case options.user_data
              when URI.regexp
                user_data_string = Base64.encode64(
                  "#include\n#{options.user_data}"
                )
              else
                user_data_string = Base64.encode64(
                  File.read(
                    expand_private_path(options.user_data, public_safe: true)
                  )
                )
              end
            else
              user_data_string = ""
            end

            # TODO: allow specifying pre-launched machines
            # TODO: allow choosing other launchers, not only openstack

            ## launch OpenStack instances
            ostack = CucuShift::OpenStack.new()
            hostnames = [ options.launched_instances_name_prefix + "_master" ]
            options.node_num.times { |i|
              hostnames << options.launched_instances_name_prefix +
                            "_node_#{i+1}"
            }
            hosts = ostack.launch_instances(names: hostnames,
                                            user_data: user_data_string)

            ## run ansible setup
            hosts_spec = { "master"=>[hosts.shift[1]], "node"=>hosts.values }
            # TODO: allow custom ssh username
            launch_opts = {
              hosts_spec: hosts_spec,
              ssh_key: expand_private_path(ostack.opts[:key_file]),
              ssh_user: 'root'
            }
            el.launcher_env_options(launch_opts)
            el.ansible_install(**launch_opts)
          else
            raise "config keyword '#{options.config}' not implemented"
          end
        end
      end

      run!
    end
  end
end

if __FILE__ == $0
  CucuShift::EnvLauncherCli.new.run
end


