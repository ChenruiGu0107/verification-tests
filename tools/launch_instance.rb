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
require 'launchers/amz'
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

      global_option('-c', '--config KEY', 'command specific; for OSE launcher selects config source, for ec2_instance it selects custom setup script')
      global_option('-l', '--launched_instances_name_prefix PREFIX', 'prefix instance names; use string `{tag}` to have it replaced with MMDDb where MM in month, DD is day and b is build number; tag works only with PUDDLE_REPO')
      global_option('-d', '--user_data SPEC', "file containing user instances' data")
      global_option('-s', '--service_name', 'service name to lookup in config')
      global_option('-i', '--image_name IMAGE', 'image to launch instance with')

      command :launch do |c|
        c.syntax = 'env_launcher_cli.rb launch -c [ENV|<conf keyword>]'
        c.description = 'launch an instance'
        c.option('-n', '--node_num', "number of nodes to launch")
        c.option('-m', '--master_num', "number of nodes to launch")
        c.action do |args, options|
          say 'launching..'
          case options.config
          when 'env', 'ENV'
            el = EnvLauncher.new

            ## set some opts based on Environment Variables
            options.master_num ||= Integer(ENV['MASTER_NUM']) rescue 1
            options.node_num ||= ENV['NODE_NUM'].to_i
            options.launched_instances_name_prefix ||= ENV['INSTANCE_NAME_PREFIX']
            options.service_name ||= ENV['CLOUD_SERVICE_NAME']
            options.service_name = options.service_name.to_sym

            # a hack to put puddle tag into instance names
            options.launched_instances_name_prefix =
              process_instance_name(options.launched_instances_name_prefix,
                                     ENV["PUDDLE_REPO"])

            # TODO: allow specifying pre-launched machines

            ## set ansible launch options from environment
            launch_opts = host_opts(options)
            el.launcher_env_options(launch_opts)

            user_data_string = user_data(options.user_data, erb_vars: launch_opts)

            ## launch Cloud instances
            hosts = launch_instances(options, user_data: user_data_string)

            ## run ansible setup
            hosts_spec = { "master"=>hosts.map(&:last)[0..options.master_num - 1],
                           "node"=>hosts.map(&:last)[options.master_num..-1] }
            launch_opts[:hosts_spec] = hosts_spec
            el.ansible_install(**launch_opts)
          else
            raise "config keyword '#{options.config}' not implemented"
          end
        end
      end

      command :ec2_instance do |c|
        c.syntax = 'env_launcher_cli.rb ec2_instance -l <instance name>'
        c.description = 'launch an instance with possibly an ansible playbook'
        c.action do |args, options|
          say 'launching..'
          options.service_name ||= :AWS
          options.service_name = options.service_name.to_sym
          unless options.service_name == :AWS
            raise "for the time being only AWS is supported"
          end

          launch_ec2_instance(options)
        end
      end

      run!
    end

    def host_opts(options)
      {
        # hosts_spec will be ready only after actual instance launch
        # TODO: allow custom ssh username and key (hosts_opts actually)
        ssh_key: expand_private_path(conf[:services, options.service_name, :key_file] || conf[:services, options.service_name, :hosts_opts, :ssh_private_key]),
        ssh_user: conf[:services, options.service_name, :hosts_opts, :user] || 'root',
        set_hostnames: !! conf[:services, options.service_name, :fix_hostnames]
      }
    end

    # @param erb_vars [Hash] additional variales for ERB user_data processing
    # @param spec [String] user data specification
    # @return [String] user data to pass to instance
    def user_data(spec = nil, erb_vars = {})
      ## process user data
      if ENV['INSTANCES_USER_DATA'] && !ENV['INSTANCES_USER_DATA'].empty?
        spec ||= ENV['INSTANCES_USER_DATA']
      end
      if spec
        case spec
        when URI.regexp
          url = URI.parse spec
          if url.scheme == "file"
            # to specify relative path, do like "file://p1/p2/p3"
            # to specify absolure path, do like "file:///p1/p2/p3"
            path = url.host ? File.join(url.host, url.path) : url.path
            user_data_string =
              File.read( expand_private_path(path, public_safe: true) )
          elsif url.scheme =~ /http/
            res = Http.get(url: spec)
            unless res[:success]
              raise "failed to get url: #{spec}"
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
                                                       **erb_vars)
            user_data_string = erb.result(erb_binding)
          end
        else
          # raw user data
          user_data_string = spec
        end

        # TODO: gzip data?
        user_data_string = Base64.encode64 user_data_string
      else
        user_data_string = ""
      end

      return user_data_string
    end

    # @return [Array<Host>] the launched and ssh acessible hosts
    def launch_instances(options,
                         user_data: nil)
      host_names = []
      if options.master_num > 1
        options.master_num.times { |i|
          host_names << options.launched_instances_name_prefix +
            "_master_#{i+1}"
        }
      else
        host_names << options.launched_instances_name_prefix + "_master"
      end
      options.node_num.times { |i|
        host_names << options.launched_instances_name_prefix +
          "_node_#{i+1}"
      }

      case conf[:services, options.service_name, :cloud_type]
      when "aws"
        raise "TODO service choice" unless options.service_name == :AWS
        ec2_image = options.image_name || ENV['CLOUD_IMAGE_NAME'] || ""
        ec2_image = ec2_image.empty? ? :raw : ec2_image
        amz = Amz_EC2.new
        amz.launch_instances(tag_name: host_names, image: ec2_image,
                             create_opts: {user_data: user_data})
      when "openstack"
        ostack = CucuShift::OpenStack.new(
          service_name: options.service_name
        )
        create_opts = {}
        create_opts[:image] = options.image_name if options.image_name
        return ostack.launch_instances(names: host_names,
                                        user_data: user_data,
                                          **create_opts)
      else
        raise "unknown service type: #{conf[:services, options.service_name, :cloud_type]}"
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

    def launch_ec2_instance(options)
      image = options.image_name || ENV['CLOUD_IMAGE_NAME']
      image = nil if image && image.empty?
      instance_name = options.launched_instances_name_prefix
      if instance_name.nil? || instance_name.empty?
        raise "you must specify instance name with -l"
      end
      user_data = user_data(options.user_data)
      amz = Amz_EC2.new
      res = amz.launch_instances(tag_name: [instance_name], image: image,
                           create_opts: {user_data: user_data})

      instance, host = res[0]
      unless host.kind_of? CucuShift::Host
        raise "bad return value: #{host.inspect}"
      end

      ## setup instance if there is a setup script
      setup = options.config
      unless setup
        # see if we have a setup script in config based on instance name
        scripts = conf[:services, options.service_name, :setup_scripts]
        if scripts
          image_name = instance.image.name
          setup = scripts.find { |e|
            image_name =~ e[:re]
          }
          setup = setup[:script] if setup
        end
      end
      if setup
        url = URI.parse setup
        path = expand_private_path(url.path, public_safe: true)
        query = url.query
        params = query ? CGI::parse(query) : {}
        Collections.map_hash!(params) { |k, v| [k, v.last] }
        setup_binding = Common::BaseHelper.binding_from_hash(binding, params)
        eval(File.read(path), setup_binding, path)
      end
    end
  end
end

if __FILE__ == $0
  CucuShift::EnvLauncherCli.new.run
end


