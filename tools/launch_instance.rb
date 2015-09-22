#!/usr/bin/env ruby
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")

"""
Utility to launch OpenShift v3 instances
"""

require 'commander'

require 'common'
require 'launchers/env_launcher'

module CucuShift
  class EnvLauncherCli
    include Commander::Methods

    def initialize
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

      command :launch do |c|
        c.syntax = 'env_launcher_cli.rb launcher -c [ENV|<conf keyword>]'
        c.description = 'launch an instance'
        c.action do |args, options|
          say 'launching..'
          case options.config
          when 'env', 'ENV'
            el = EnvLauncher.new
            options.launched_instances_name_prefix ||= ENV['INSTANCE_NAME_PREFIX']
            options.node_num ||= ENV['NODE_NUM'].to_i
            # TODO: allow specifying pre-launched machines
            # TODO: allow choosing other launchers, not only openstack

            ## launch instances
            hostnames = [ options.launched_instances_name_prefix + "_master" ]
            options.node_num.times { |i|
              hostnames << options.launched_instances_name_prefix +
                            "_node_#{i+1}"
            }
            hosts = el.launch_os_instances(names: hostnames)

            # ansible setup
            hosts_spec = {master: hosts.shift[1], node: hosts.values}
            launch_opts = {hosts_spec: hosts_spec}
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


