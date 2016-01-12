#!/usr/bin/env ruby
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")

"""
Utility to launch OpenShift v3 instances
"""

require 'base64'
require 'cgi'
require 'commander'
require 'uri'

require 'collections'
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
      global_option('-s', '--service_name', 'service name to lookup in config')

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
            options.cloud_service ||= ENV['CLOUD_SERVICE_NAME'].to_sym

            # a hack to put puddle tag into instance names
            options.launched_instances_name_prefix =
              process_instance_name(options.launched_instances_name_prefix,
                                     ENV["PUDDLE_REPO"])

            # TODO: allow specifying pre-launched machines

            ## set ansible launch options from environment
            launch_opts = {
              hosts_spec: hosts_spec,
              ssh_key: expand_private_path(ostack.opts[:key_file]),
              # TODO: allow custom ssh username
              ssh_user: 'root',
              set_hostnames: !! config[:services, options.cloud_service, :fix_hostnames]
            }
            el.launcher_env_options(launch_opts)

            ## process user data
            if ENV['INSTANCES_USER_DATA'] && !ENV['INSTANCES_USER_DATA'].empty?
              options.user_data ||= ENV['INSTANCES_USER_DATA']
            end
            if options.user_data
              case options.user_data
              when URI.regexp
                url = URI.parse options.user_data
                if url.scheme == "file"
                  # to specify relative path, do like "file://p1/p2/p3"
                  # to specify absolure path, do like "file:///p1/p2/p3"
                  path = url.host ? File.join(url.host, url.path) : url.path
                  user_data_string =
                    File.read( expand_private_path(path, public_safe: true) )
                elsif url.scheme =~ /http/
                  res = Http.get(url: options.user_data)
                  unless res[:success]
                    raise "failed to get url: #{options.user_data}"
                  end
                  user_data_string = res[:response]
                else
                  raise "dunno how to handle scheme: #{url.scheme}"
                end

                if url.path.end_with? ".erb"
                  url_options = CGI::parse url.query
                  url_options = Collections.map_hash(url_options) { |k, v|
                    # all single value URL params would be de-arrayified
                    [ k, v.size == 1 ? v.first : v ]
                  }
                  erb = ERB.new(user_data_string)
                  # options from url take precenece before lauch options
                  erb_binding = BaseHelper.binding_from_hash(**launch_opts,
                                                             **url_options)
                  user_data_string = erb.result(erb_binding)
                end
              else
                # raw user data
                user_data_string = options.user_data
              end

              # TODO: gzip data?
              user_data_string = Base64.encode64 user_data_string
            else
              user_data_string = ""
            end


            ## launch Cloud instances
            hosts = launch_instances(options, names: hostnames,
                                              user_data: user_data_string)

            ## run ansible setup
            hosts_spec = { "master"=>hosts.values[0..options.master_num - 1],
                           "node"=>hosts.values[options.master_num..-1] }
            el.ansible_install(**launch_opts)
          else
            raise "config keyword '#{options.config}' not implemented"
          end
        end
      end

      run!
    end

    # @return [Array<Host>] the launched and ssh acessible hosts
    def launch_instances(options, names:,
                         user_data: nil)
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

      case config[:services, options.cloud_service, :cloud_type]
      when "aws"
        raise "TODO service choice" unless options.cloud_service == "AWS"
        ec2_image = ENV['CLOUD_IMAGE_NAME'] || ""
        ec2_image = ec2_image.empty? ? :raw : ec2_image
        amz = Amz_EC2.initialize
        amz.launch_instances(tag_name: names, image: ec2_image)
      when "openstack"
        ostack = CucuShift::OpenStack.new(
          service_name: options.cloud_service
        )
        return ostack.launch_instances(names: names,
                                        user_data: user_data_string)
      else
        raise "unknown service type: #{config[:services, options.cloud_service, :cloud_type]}"
      end
    end

    # process instance name prefix to generate an identity tag
    # e.g. "2015-11-10.2" => "11102"
    # If "latest" build is used, then we try to find it on server.
    def process_instance_name(name_prefix, puddle_repo = nil)
      puddle_re = '\d{4}-\d{2}-\d{2}\.\d+'
      return name_prefix.gsub("{tag}") {
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
    end
  end
end

if __FILE__ == $0
  CucuShift::EnvLauncherCli.new.run
end


