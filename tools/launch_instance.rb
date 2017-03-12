#!/usr/bin/env ruby
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")

"""
Utility to launch OpenShift v3 instances
"""

require 'base64'
require 'cgi'
require 'commander'
require 'uri'
require 'yaml'

require 'collections'
require 'common'
require 'http'

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
      default_command :template

      global_option('-c', '--config KEY',
                    "command specific:\n\t" <<
                    "* for OSE launcher selects config source\n\t" <<
                    "* for ec2_instance it selects custom setup script\n\t" <<
                    "* for template it specifies a file with YAML variables")
      global_option('-l', '--launched_instances_name_prefix PREFIX', 'prefix instance names; use string `{tag}` to have it replaced with MMDDb where MM in month, DD is day and b is build number; tag works only with PUDDLE_REPO')
      global_option('-d', '--user_data SPEC', "file containing user instances' data")
      global_option('-s', '--service_name', 'service name to lookup in config')
      global_option('-i', '--image_name IMAGE', 'image to launch instance with')
      global_option('--it', '--instance_type TYPE', 'instance flavor to launch')

      command :template do |c|
        c.syntax = "#{File.basename __FILE__} template -l <instance name>"
        c.description = 'launch instances according to template'
        c.action do |args, options|
          say 'launching..'
          launch_template(**options.default)
        end
      end

      command :ec2_instance do |c|
        c.syntax = "#{File.basename __FILE__} ec2_instance -l <instance name>"
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

    def get_dyn
      CucuShift::Dynect.new()
    end

    # @param erb_vars [Hash, Binding] additional variales for ERB user_data
    #   processing
    # @param spec [String] user data specification
    # @return [String] user data to pass to instance
    def user_data(spec = nil, erb_vars = {})
      ## process user data
      spec ||= getenv('INSTANCES_USER_DATA')
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
            # options from url take precenece over launch options
            if Binding === erb_vars
              erb_binding = Common::BaseHelper.binding_from_hash(erb_vars.dup,
                                                                 **url_options)

            else
              erb_binding = Common::BaseHelper.binding_from_hash(**erb_vars,
                                                                 **url_options)
            end
            user_data_string = erb.result(erb_binding)
          end
        else
          # raw user data
          user_data_string = spec
        end

        # TODO: gzip data?
      else
        user_data_string = ""
      end

      return user_data_string
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

    # path and basepath can be URLs
    def readfile(path, basepath=nil)
      case path
      when %r{\Ahttps?://}
        return Http.get(url: path, raise_on_error: true)[:response]
      when %r{\A/}
        return File.read path
      else
        if ! basepath
          return File.read expand_private_path(path, public_safe: true)
        else
          with_base = File.join(basepath, path)
          return (readfile(with_base) rescue readfile(path))
        end
      end
    end

    def basename(path_or_url)
      File.basename(URI.parse(path_or_url).path)
    end

    def localize(path, basepath=nil)
      case path
      when %r{\Ahttps?://}
        filename = basename(path)
        unless filename =~ /\A[-a-zA-Z0-9._]+\z/
          raise "bad filename '#{filename}' for URL: #{path}"
        end
        filename = Host.localhost.absolutize(filename)
        File.write(filename, Http.get(url: path,
                                      raise_on_error: true)[:response])
        return filename
      when %r{\A/}
        return path
      else
        if ! basepath
          return expand_private_path(path, public_safe: true)
        else
          with_base = File.join(basepath, path)
          return (localize(with_base) rescue localize(path))
        end
      end
    end

    def merged_launch_opts(common, overrides)
      common ||= {}
      overrides ||= {}
      service_name = overrides[:service_name] || common[:service_name]
      if service_name
        service_name = service_name.to_sym
      else
        raise "no service name specified for host launch options"
      end

      common_launch_opts = common[service_name] || {}
      overrides_launch_opts = overrides[service_name] || {}
      return service_name,
        Collections.deep_merge(common_launch_opts, overrides_launch_opts)
    end

    def dns_component
      @dns_component ||= CucuShift::Dynect.gen_timed_random_component
    end

    def dns_component=(value)
      if value =~ /^\d{4}-|^fixed-/ &&
         ( !value.include?(".") || value.end_with?(".") )
        @dns_component = value
        logger.warn "User specified DNS component: #{value}"
      else
        raise "got '#{value}' but allowed only FQDN ending with dot or a single DNS component without any dots; both matching /^\d{4}-|^fixed-/"
      end
    end

    # @return [Array<Host>]
    def launch_host_group(host_group, common_launch_opts,
                          user_data_vars: {}, existing_hosts: nil)

      # generate instance names
      existing_hosts ||= []
      host_name_prefix = common_launch_opts[:name_prefix]
      host_roles = host_group[:roles]
      full_name_prefix = "#{host_name_prefix}#{host_roles.join("-")}-"
      index_offset = existing_hosts.select { |h|
        h[:cloud_instance_name] =~ /^#{Regexp.escape full_name_prefix}\d+$/
      }.map { |h|
        Integer(h[:cloud_instance_name][full_name_prefix.size..-1])
      }.max
      index_offset ||= 0
      host_names = host_group[:num].times.map { |i|
        "#{full_name_prefix}#{(i + index_offset + 1)}"
      }

      # get launch instances config
      service_name, launch_opts = merged_launch_opts(common_launch_opts, host_group[:launch_opts])

      # get user data
      if launch_opts[:user_data]
        user_data_string = user_data(launch_opts[:user_data], user_data_vars)
      else
        user_data_string = ""
      end
      launch_opts.delete(:user_data)

      service_type = conf[:services, service_name, :cloud_type]
      launched = case service_type
      when "aws"
        raise "TODO service choice" unless service_name == :AWS
        amz = Amz_EC2.new
        launch_opts[:user_data] = Base64.encode64(user_data_string)
        res = amz.launch_instances(tag_name: host_names,
                                   image: launch_opts.delete(:image),
                                   create_opts: launch_opts)
      when "openstack"
        ostack = CucuShift::OpenStack.new(service_name: service_name)
        create_opts = {}
        res = ostack.launch_instances(
          names: host_names,
          user_data: Base64.encode64(user_data_string),
          **launch_opts
        )
      when "gce"
        gce = CucuShift::GCE.new
        res = gce.create_instances(host_names, user_data: user_data_string,
                                   **launch_opts )
      else
        raise "unknown service type #{service_type} for cloud #{service_name}"
      end

      # set hostnames if cloud has broken defaults
      fix_hostnames = conf[:services, service_name, :fix_hostnames]
      launched = launched.map(&:last)
      launched.each do |host|
        host[:fix_hostnames] = fix_hostnames
        host.roles.concat host_group[:roles]
      end

      return launched
    end

    def launcher_binding
      binding
    end

    # symbolize keys in launch templates
    def normalize_template(template)
      template = Collections.deep_hash_symkeys template
      template[:hosts][:list].map! {|hg| Collections.deep_hash_symkeys hg}
      # insert helper reference name to help implicit node creation at start
      template[:hosts][:list].each {|hg| hg[:ref] ||= rand_str(5, :dns)}

      template[:install_sequence].map! {|is| Collections.deep_hash_symkeys is}
      template[:install_sequence].each do |task|
        if task[:type] == "launch_host_groups" && Array === task[:list]
          task[:list].map! {|hg| Collections.deep_hash_symkeys hg}
        end
      end
      return template
    end

    def run_ansible_playbook(playbook, inventory, env: nil, retries: 1)
      env ||= {}
      env = env.reduce({}) { |r,e| r[e[0].to_s] = e[1].to_s; r }
      env["ANSIBLE_FORCE_COLOR"] = "true"
      env["ANSIBLE_CALLBACK_WHITELIST"] = 'profile_tasks'
      retries.times do |attempt|
        id_str = (attempt == 0 ? ': ' : " (try #{attempt + 1}): ") + playbook
        say "############ ANSIBLE RUN#{id_str} ############################"
        res = Host.localhost.exec(
          'ansible-playbook', '-v', '-i', inventory,
          playbook,
          env: env, single: true, stderr: :out, stdout: STDOUT, timeout: 36000
        )
        say "############ ANSIBLE END#{id_str} ############################"
        if res[:success]
          break
        elsif attempt >= retries - 1
          raise "ansible failed execution, see logs" unless res[:success]
        end
      end
    end

    # performs an installation task
    def installation_task(task, template:, erb_binding:, config_dir: nil)
      case task[:type]
      when "force_domain"
        self.dns_component = task[:name]
      when "dns_hostnames"
        begin
          changed = false
          dyn = get_dyn
          erb_binding.local_variable_get(:hosts).each do |host|
            if !host.has_hostname?
              changed = true
              dns_record = host[:cloud_instance_name] || rand_str(3, :dns)
              dns_record = dns_record.gsub("_","-")
              dns_record = "#{dns_record}.#{dns_component}"
              host.update_hostname dyn.dyn_create_a_records(dns_record, host.ip)
              host[:fix_hostnames] = true
            end
          end
          dyn.publish if changed
        ensure
          dyn.close if changed
        end
      when "wildcard_dns"
        begin
          dyn = get_dyn
          ips = []

          if task[:roles]
            hosts = erb_binding.local_variable_get(:hosts)
            ips.concat(hosts.select{|h| h.has_any_role? task[:roles]}.map(&:ip))
          end
          if task[:ips]
            ips.concat task[:ips]
          end

          dns_record = "*.#{dns_component}"
          dyn.dyn_delete_matching_records(dns_record) if task[:overwrite]
          fqdn = dyn.dyn_create_a_records(dns_record, ips)
          if task[:store_in]
            erb_binding.local_variable_set task[:store_in].to_sym, fqdn
          end
          dyn.publish
        ensure
          dyn.close
        end
      when "playbook"
        inventory_erb = ERB.new(readfile(task[:inventory], config_dir))
        inventory_erb.filename = task[:inventory]
        inventory_str = inventory_erb.result(erb_binding)
        inventory = Host.localhost.absolutize basename(task[:inventory])
        puts "Ansible inventory #{File.basename inventory}:\n#{inventory_str}"
        File.write(inventory, inventory_str)
        run_ansible_playbook(localize(task[:playbook]), inventory,
                             retries: (task[:retries] || 1), env: task[:env])
      when "launch_host_groups"
        existing_hosts = erb_binding.local_variable_get(:hosts)
        hosts = []
        hosts_spec = template[:hosts]
        common_launch_opts = hosts_spec[:common_launch_opts]

        task[:list].each do |req|
          host_group = hosts_spec[:list].find {|hg| hg[:ref] == req[:ref]}
          if host_group
            hosts.concat launch_host_group(
              host_group.merge({num: req[:num]}),
              common_launch_opts,
              user_data_vars: erb_binding,
              existing_hosts: existing_hosts
            )
          else
            raise "no host group #{req[:ref].inspect} defined"
          end
        end

        # wait each host to become accessible
        existing_hosts.concat hosts
        hosts.each {|h| h.wait_to_become_accessible(600)}
      else
        raise "unsupported installation task: '#{task[:type]}'"
      end
    end

    # @param config [String] an YAML file to read variables from
    # @param launched_instances_name_prefix [String]
    def launch_template(config:, launched_instances_name_prefix:)
      vars = YAML.load(readfile(config))
      if ENV["LAUNCHER_VARS"] && !ENV["LAUNCHER_VARS"].empty?
        launcher_vars = YAML.load ENV["LAUNCHER_VARS"]
        if Hash === launcher_vars
          Collections.deep_merge!(vars, launcher_vars)
        else
          raise "LAUNCHER_VARS not a mapping but #{launcher_vars.inspect}"
        end
      end
      vars = Collections.deep_hash_symkeys vars
      vars[:instances_name_prefix] = launched_instances_name_prefix
      raise "specify 'template' in variables" unless vars[:template]

      # this can be a URL or a PATH
      config_dir = File.dirname config
      config_dir = nil if config_dir == "."
      hosts = []
      erb_binding = Common::BaseHelper.binding_from_hash(launcher_binding,
                                                         hosts: hosts, **vars)
      template = ERB.new(readfile(vars[:template], config_dir))
      template = YAML.load(template.result(erb_binding))
      template = normalize_template(template)

      ## implicit launch of hosts
      implicit_launch_task = { type: "launch_host_groups", list: [] }
      template[:hosts][:list].each do |host_group|
        if host_group[:num] && host_group[:num] > 0
          implicit_launch_task[:list] << {ref: host_group[:ref], num: host_group[:num]}
        end
      end
      unless implicit_launch_task[:list].empty?
        template[:install_sequence].unshift implicit_launch_task
      end

      ## perform provisioning steps
      template[:install_sequence].each do |task|
        installation_task(
          task,
          erb_binding: erb_binding,
          template: template,
          config_dir: config_dir
        )
      end

      ## help users persist home info
      hosts_spec = hosts.map{|h| "#{h.hostname}:#{h.roles.join(':')}"}.join(',')
      logger.info "HOSTS SPECIFICATION: #{hosts_spec}"
      host_spec_out = ENV["CUCUSHIFT_HOSTS_SPEC_FILE"]
      if host_spec_out && !File.exist?(host_spec_out)
        begin
          File.write(host_spec_out, hosts_spec)
        rescue => e
          logger.error("could not save host specification: #{e}")
        end
      end
    end

    def launch_ec2_instance(options)
      image = options.image_name || getenv('CLOUD_IMAGE_NAME')
      image = nil if image && image.empty?
      instance_name = options.launched_instances_name_prefix
      options.instance_type ||= getenv('CLOUD_INSTANCE_TYPE')
      if options.instance_type && !options.instance_type.empty?
        create_opts[:instance_type] = options.instance_type
      end
      if instance_name.nil? || instance_name.empty?
        raise "you must specify instance name with -l"
      end
      user_data = user_data(options.user_data)
      amz = Amz_EC2.new
      res = amz.launch_instances(tag_name: [instance_name], image: image,
                           create_opts: {user_data: Base64.encode64(user_data)},
                           wait_accessible: true)

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
