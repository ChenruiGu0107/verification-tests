require 'socket'
require 'erb'

require 'common'
require 'host'
require_relative 'openstack'

module CucuShift
  class EnvLauncher
    include Common::Helper

    ALTERNATING_AUTH = ['LDAP', 'KERBEROS']

    # raise on failing [CucuShift::ResultHash]
    private def check_res(res)
      unless res[:success]
        logger.error res[:response]
        raise "last operation failed: #{res[:instruction]}"
      end
    end

    # @param os_opts [Hash] options to pass to [OpenStack::new]
    # @param names [Array<String>] array of names to give to new machines
    # @return [Hash] a hash of name => hostname pairs
    def launch_os_instances(names:, use_hostnames: true, **os_opts)
      os_server = CucuShift::OpenStack.new(**os_opts)
      res = {}
      names.each { |name|
        _, res[name] = os_server.create_instance(name)
        res[name] = reverse_lookup(res[name]) if use_hostnames
        sleep 10 # why?
      }
      sleep 60 # why?
      return res
    end

    # @return single DNS entry for a hostname
    private def dns_lookup(hostname, af: Socket::AF_INET)
      res = Socket.getaddrinfo(hostname, 0, af, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME)

      if res.size < 1
        raise "cannot resolve hostname: #{hostname}"
      end

      return res[0][3]
    end

    private def reverse_lookup(ip)
      res = Socket.getaddrinfo(ip, 0, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME, true)

      if res.size != 1
        raise "not sure how to handle multiple entries, please report to author"
      end

      return res[0][2] # btw this might be same IP if reverse entry missing
    end

    private def spec_to_hosts(spec, ssh_key:, ssh_user:)
      hosts={}
      spec.gsub!(/all:/, 'master:')
      host_opts = {user: ssh_user, ssh_private_key: ssh_key}
      spec.split(',').each do |role_host_pair|
        role, _, hostname = role_host_pair.partition(':')
        (hosts[role] ||= []) << SSHAccessibleHost.new(hostname, host_opts)

      end
    end

    # @param hosts_spec [Hash<String,Array>] role=>[host1, ..,hostN] pairs
    # @param auth_type [String] LDAL, HTTPASSWD, KERBEROS
    # @param ssh_user [String] the username to use for ssh to env hosts
    # @param dns [String] the dns server to use; can be keyword or an IP
    #   address; see the dns case/when construct for available options
    # @param app_domain [String] domain used to generate route dns names;
    #   can be auto-sensed in certain setups, see dns code below
    # @param host_domain [String] domain used to access env hosts; not always
    #   used, see dns code below
    # @param rhel_base_repo [String] rhel/centos base repo URL to configure on
    #   env hosts
    # @param deployment_type [String] ???
    # @param image_pre [String] image pattern (see configure_env.sh)
    #
    def ansible_install(hosts_spec:, auth_type:,
                        ssh_key:, ssh_user:,
                        dns: nil,
                        app_domain: nil, host_domain: nil,
                        rhel_base_repo:,
                        deployment_type:,
                        crt_path:,
                        image_pre:,
                        puddle_repo:,
                        network_plugin:,
                        etcd_num:,
                        registry_ha:,
                        ansible_branch:,
                        ansible_url:,
                        kerberos_kdc: conf[:sercices, :test_kerberos, :kdc],
                        kerberos_keytab_url:
                          conf[:sercices, :test_kerberos, :keytab_url],
                        kerberos_admin_server:
                          conf[:sercices, :test_kerberos, :admin_server],
                        kerberos_docker_base_image:
                          conf[:sercices, :test_kerberos, :docker_base_image])
      hosts = spec_to_hosts(host_spec, ssh_key: ssh_key, ssh_user: ssh_user)
      conf_script_file = File.join(__FILE__, 'env_scripts', 'configure_env.sh')
      hosts_erb = File.join(__FILE__, 'env_scripts', 'hosts.erb')

      conf_script = File.read(conf_script_file)

      conf_script.gsub!(/#CONF_HOST_LIST=.*$/, "CONF_HOST_LIST=#{hosts_spec}")
      conf_script.gsub!(/#CONF_AUTH_TYPE=.*$/, "CONF_AUTH_TYPE=#{auth_type}")
      conf_script.gsub!(/#CONF_IMAGE_PRE=.*$/, "CONF_IMAGE_PRE='#{image_pre}'")
      conf_script.gsub!(/#CONF_CRT_PATH=.*$/) { "CONF_CRT_PATH='#{crt_path}'" }
      conf_script.gsub!(/#CONF_RHEL_BASE_REPO=.*$/,
                        "CONF_RHEL_BASE_REPO=#{rhel_base_repo}")


      conf_script.gsub!(/#(CONF_KERBEROS_ADMIN)=.*$/,
                        "\\1=#{kerberos_admin_server}")
      conf_script.gsub!(/#(CONF_KERBEROS_KEYTAB_URL)=.*$/,
                        "\\1=#{kerberos_keytab_url}")
      conf_script.gsub!(/#(CONF_KERBEROS_BASE_DOCKER_IMAGE)=.*$/,
                        "\\1=#{kerberos_docker_base_image}")
      conf_script.gsub!(/#(CONF_KERBEROS_KDC)=.*$/, "\\1=#{kerberos_kdc}")

      case dns
      when nil, false, "", "none"
        # basically do nothing
        host_domain ||= "cluster.local"
        raise "specify :app_domain and :host_domain" unless app_domain
      when "embedded"
        host_domain ||= "cluster.local"
        app_domain ||= rand_str(5, :dns) + ".example.com"
        conf_script.gsub!(
          /#CONF_DNS_IP=.*$/,
          "CONF_DNS_IP=#{hosts['master'][0].ip}"
        )
        conf_script.gsub!(/#USE_OPENSTACK_DNS=.*$/, "USE_OPENSTACK_DNS=true")
      when "embedded_skydns"
        host_domain ||= "cluster.local"
        app_domain = "router.cluster.local"
        conf_script.gsub!(
          /#CONF_DNS_IP=.*$/,
          "CONF_DNS_IP=#{hosts['master'][0].ip}"
        )
      when /^shared/
        host_domain ||= "cluster.local"
        app_domain ||= rand_str(5, :dns) + ".example.com"
        shared_dns_config = conf[:services, :shared_dns]
        conf_script.gsub!(
          /#CONF_DNS_IP=.*$/,
          "CONF_DNS_IP=#{shared_dns_config[:ip]}"
        )
        host_opts = {user: shared_dns_config[:user],
                     ssh_private_key: shared_dns_config[:key_file]}
        dns_host = SSHAccessibleHost.new(shared_dns_config[:ip], host_opts)
        begin
          check_res \
            dns_host.exec_admin('cat > configure_env.sh',
                                stdin: conf_script)
          check_res \
            dns_host.exec_admin('sh configure_env.sh configure_shared_dns')
        ensure
          dns_host.clean_up
        end
      else
        host_domain ||= "cluster.local"
        raise "specify :app_domain and :host_domain" unless app_domain
        conf_script.gsub!(/#CONF_DNS_IP=.*$/, dns)
      end

      conf_script.gsub!(/#CONF_HOST_DOMAIN=.*$/,
                        "CONF_HOST_DOMAIN=#{host_domain}")
      conf_script.gsub!(/#CONF_APP_DOMAIN=.*$/,
                        "CONF_APP_DOMAIN=#{app_domain}")

      case auth_type
      when "HTPASSWD"
        identity_providers = "[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/openshift/htpasswd'}]"
      else
        identity_providers = "[{'name': 'basicauthurl', 'login': 'true', 'challenge': 'true', 'kind': 'BasicAuthPasswordIdentityProvider', 'url': 'https://<serviceIP>:8443/validate', 'ca': '#{crt_path}master/ca.crt'}]"
      end

      hosts_str = ERB.new(File.read(hosts_erb)).result binding
      etcd_cur_num = 0
      node_index = 1

      hosts.each do |role, hosts|
        hosts.each do |host|
          # upload to host with cat
          check_res \
            host.exec_admin('cat > configure_env.sh', stdin: conf_script)

          check_res host.exec_admin("sh configure_env.sh configure_repos")
          if dns.start_with?("embedded")
            check_res host.exec_admin("sh configure_env.sh configure_hosts")
          end

          if etcd_num < etcd_cur_num
            etcd_cur_num = etcd_cur_num + 1
            hosts_str.gsub!(/(\[etcd\])/, "\\1\n" + host.hostname + "\n")
          end

          case role
          when "master"
            # TODO: assumption is only one master
            if dns == "embedded"
              check_res host.exec_admin('sh configure_env.sh configure_dns')
            elsif dns
              check_res \
                host.exec_admin('sh configure_env.sh configure_dns_resolution')
            end

            if dns == "embedded_skydns"
              hosts_str.gsub!(/(\[masters\])/, "\\1\n#{host.hostname} openshift_hostname=master.#{host_domain}\n")
            else
              hosts_str.gsub!(/(\[masters\])/, "\\1\n" + host.hostname + "\n")
            end

            if hosts.size > 1
              hosts_str.gsub!(/(\[nodes\])/, %Q*\\1\n#{host.hostname} openshift_scheduleable=False"\n*)
            else
              hosts_str.gsub!(/(\[nodes\])/, %Q*\\1\n#{host.hostname} openshift_node_labels="{'region': 'primary', 'zone': 'default'}"\n*)
            end
          else
            if dns == "embedded_skydns"
              hosts_str.gsub!(/(\[nodes\])/, %Q*\\1\n#{host.hostname} openshift_node_labels="{'region': 'primary', 'zone': 'default'}" openshift_hostname=minion#{node_index}.#{host_domain}\n*)
            else
              hosts_str.gsub!(/(\[nodes\])/, %Q*\\1\n#{host.hostname} openshift_node_labels="{'region': 'primary', 'zone': 'default'}"\n*)
            end
            if dns
              check_res \
                host.exec_admin('sh configure_env.sh configure_dns_resolution')
            end
          end
        end
      end

      if registry_ha
        check_res hosts['master'][0].exec_admin(
          'sh configure_env.sh configure_nfs_service'
        )
      end

      # finally run download repo and run ansible (this is in workdir)
      # we need git and ansible available pre-installed
      check_res Host.loalhost.exec(
        "git clone #{ansible_url} -b #{ansible_branch}"
      )
      res = nil
      Dir.chdir(Host.loalhost.workdir) {
        File.write("hosts", hosts_str)
        # want to see output in real-time
        res = system("ansible-playbook -i hosts openshift-ansible/playbooks/byo/config.yml -v --private-key #{expand_private_path ssh_key}")
      }
      raise "ansible failed" unless res

      check_res hosts['master'][0].exec_admin(
        "sh configure_env.sh replace_template_domain"
      )
      check_res hosts['master'][0].exec_admin(
        "sh configure_env.sh create_router_registry"
      )

      if registry_ha
        check_res hosts['master'][0].exec_admin(
          'sh configure_env.sh configure_registry_to_ha'
        )
      end
      if dns == "embedded_skydns"
        check_res hosts['master'][0].exec_admin(
          "sh configure_env.sh add_skydns_hosts"
        )
      end
      unless auth_type == "HTPASSWD"
        check_res hosts['master'][0].exec_admin(
          'sh configure_env.sh configure_auth'
        )
      end
    ensure
      # Host clean_up
      if defined?(hosts) && hosts.kind_of?(Hash)
        hosts.each do |role, hosts|
          if hosts.kind_of? Array
            hosts.each do |host|
              if host.kind_of? Host
                host.clean_up
              end
            end
          end
        end
      end # Host clean_up
      Host.localhost.clean_up
    end

    # update launch options from ENV (used usually by jenkins jobs)
    # @param opts [Hash] instance launch opts to modify based on ENV
    # @return [Hash] the modified hash options
    def launcher_env_options(opts)
      if ENV["AUTH_TYPE"] && !ENV["AUTH_TYPE"].empty?
        if ENV["AUTH_TYPE"] == "RANDOM"
          ## each day we want to use different auth type ignoring weekends
          time = Time.now
          day_of_year = time.yday
          passed_weeks_of_year = time.strftime('%W').to_i - 1
          opts[:auth_type] = ALTERNATING_AUTH[
            (day_of_year - 2 * passed_weeks_of_year) % ALTERNATING_AUTH.size
          ]
        else
          opts[:auth_type] = ENV["AUTH_TYPE"]
        end
      end

      keys = [:crt_path, :deployment_type,
              :hosts_spec, :auth_type,
              :ssh_key, :ssh_user,
              :app_domain, :host_domain,
              :rhel_base_repo,
              :dns, :deployment_type,
              :crt_path, :image_pre,
              :puddle_repo, :network_plugin,
              :etcd_num, :registry_ha,
              :ansible_branch, :ansible_url,
              :kerberos_docker_base_image,
              :kerberos_kdc, :kerberos_keytab_url,
              :kerberos_docker_base_image,
              :kerberos_admin_server]

      #when "OSE"
      #  crt_path = '/etc/openshift/'
      #  deployment_type="enterprise"
      #else
      #  crt_path = '/etc/origin/'
      #  deployment_type="atomic-enterprise"
      #end

      keys.each do |key|
        if ENV[key.to_s.upcase] && !ENV[key.to_s.upcase].empty?
          opts[key] = ENV[key.to_s.upcase]
        end
      end
    end

    #def launch(**opts)
    #  # set OPENSTACK_SERVICE_NAME
    #  launch_os_instances(names:)
    #
    #  opts = launcher_env_options()
    #  ansible_install(**opts)
    #end

  end
end
