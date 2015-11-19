#!/usr/bin/env ruby
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")

"""
Utility to launch OpenShift v3 instances
"""

require 'base64'
require 'commander'
require 'uri'

require 'common'
require 'http'
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
      global_option('-l', '--launched_instances_name_prefix', 'if instances are launched, use this prefix; use string `{tag}` ti have it replaced with MMDDb where MM in month, DD is day and b is build number')
      global_option('-m', '--master_num', "number of nodes to launch")
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
            options.master_num ||= Integer(ENV['MASTER_NUM']) rescue 1
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

            # a hack to put puddle tag into instance names
            process_instance_name!(options.launched_instances_name_prefix,
                                   ENV["PUDDLE_REPO"])

            # TODO: allow specifying pre-launched machines
            # TODO: allow choosing other launchers, not only openstack

            ## launch OpenStack instances
            ostack = CucuShift::OpenStack.new()
            hostnames = []
            if options.master_num > 1
              options.master_num.times { |i|
                hostnames << options.launched_instances_name_prefix +
                  "_master_#{i+1}"
              }
            else
              hostnames << options.launched_instances_name_prefix + "_master"
            end
            options.node_num.times { |i|
              hostnames << options.launched_instances_name_prefix +
                            "_node_#{i+1}"
            }
            hosts = ostack.launch_instances(names: hostnames,
                                            user_data: user_data_string)

            ## run ansible setup
            hosts_spec = { "master"=>hosts.values[0..options.master_num - 1],
                           "node"=>hosts.values[options.master_num..-1] }
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

    # process instance name prefix to generate an identity tag
    # e.g. "2015-11-10.2" => "11102"
    # If "latest" build is used, then we try to find it on server.
    def process_instance_name!(name_prefix, puddle_repo = nil)
      puddle_re = '\d{4}-\d{2}-\d{2}\.\d+'
      name_prefix.gsub!("{tag}") {
        case puddle_repo
        when nil
          raise 'no pudde repo specified, cannot substitute ${tag}'
        when /#{puddle_re}/
          # $& is last match
          $&.gsub(/[-.]/,'')[4..-1]
        when %r{(?<=/)latest/}
          # $` is string before last match
          puddle_base = $`
          res = Http.get(url: puddle_base)
          raise "failed to get puddle base: #{puddle_base}" unless res[:success]
          puddles = []
          res[:response].scan(/href="(#{puddle_re})\/"/) { |m| puddles << m[0] }
          raise "strange puddle base: #{puddle_base}" if puddles.empty?
          puddles.map! { |p| p.gsub!(/[-.]/,'') }
          latest = puddles.map(&:to_str).map(&:to_i).max
          latest.to_s[4..-1]
        else
          raise "cannot find puddle base from url: #{puddle_repo}"
        end
      }
      return name_prefix
    end
  end
end

if __FILE__ == $0
  CucuShift::EnvLauncherCli.new.run
end


