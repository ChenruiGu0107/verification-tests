require 'socket'
require 'erb'
require 'yaml'

require 'common'
require 'host'

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


    # @param hosts [Hash<String,Array<Host>>] the hosts hash
    # @return [Array<String>] specification like:
    #   `["master:host1,...,node:hostX", "master:ip1,...,node:ipX"]`
    private def hosts_to_specstr(hosts)
      hosts_str = []
      ips_str = []
      hosts.each do |role, role_hosts|
        role_hosts.each do |host|
          hosts_str << "#{role}:#{host.hostname}"
          ips_str << "#{role}:#{host.ip}"
        end
      end
      return hosts_str.join(','), ips_str.join(',')
    end

    # @param spec [String, Hash<String,Array>] the specification.
    #   If [String], then it looks like: `master:hostname1,node:hostname2,...`;
    #   If [Hash], then it's `role=>[host1, ..,hostN] pairs`
    private def spec_to_hosts(spec, ssh_key:, ssh_user:)
      hosts={}

      if spec.kind_of? String
        res = {}
        spec.gsub!(/all:/, 'master:')
        spec.split(',').each { |p|
          role, _, hostname = p.partition(':')
          (res[role] ||= []) << hostname
        }
        spec = res
      end

      host_opts = {user: ssh_user, ssh_private_key: ssh_key}
      spec.each do |role, hostnames|
        hosts[role] = hostnames.map do |hostname|
          SSHAccessibleHost.new(hostname, host_opts)
        end
      end

      return hosts
    end

    # @param hosts_spec [String, Hash<String,Array>] the specification.
    #   If [String], then it looks like: `master:hostname1,node:hostname2,...`;
    #   If [Hash], then it's `role=>[host1, ..,hostN] pairs`
    # @param auth_type [String] LDAP, HTTPASSWD, KERBEROS
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
                        rhel_base_repo: nil,
                        deployment_type:,
                        crt_path:,
                        image_pre:,
                        puddle_repo:,
                        network_plugin:,
                        etcd_num:,
                        registry_ha:,
                        ansible_branch:,
                        ansible_url:,
                        customized_ansible_conf: "",
                        modify_IS_for_testing: "",
                        kerberos_kdc: conf[:sercices, :test_kerberos, :kdc],
                        kerberos_keytab_url:
                          conf[:sercices, :test_kerberos, :keytab_url],
                        kerberos_admin_server:
                          conf[:sercices, :test_kerberos, :admin_server],
                        kerberos_docker_base_image:
                          conf[:sercices, :test_kerberos, :docker_base_image],
                        ldap_url: conf[:services, :test_ldap, :url])
      hosts = spec_to_hosts(hosts_spec, ssh_key: ssh_key, ssh_user: ssh_user)
      hostnames_str, ips_str = hosts_to_specstr(hosts)
      logger.info hosts.to_yaml

      conf_script_dir = File.join(File.dirname(__FILE__), 'env_scripts')
      conf_script_file = File.join(conf_script_dir, 'configure_env.sh')

      hosts_erb = File.join(conf_script_dir, 'hosts.erb')

      conf_script = File.read(conf_script_file)

      conf_script.gsub!(/#CONF_HOST_LIST=.*$/,
                        "CONF_HOST_LIST=#{hostnames_str}")
      conf_script.gsub!(/#CONF_IP_LIST=.*$/, "CONF_IP_LIST=#{ips_str}")
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

      router_dns_type = nil
      dns_subst = proc do
        conf_script.gsub!(/#CONF_HOST_DOMAIN=.*$/,
                          "CONF_HOST_DOMAIN=#{host_domain}")
        conf_script.gsub!(/#CONF_APP_DOMAIN=.*$/,
                          "CONF_APP_DOMAIN=#{app_domain}")
        # relevant currently only for shared DNS config or router endpoints
        conf_script.gsub!(/#CONF_ROUTER_NODE_TYPE=.*$/,
                          "CONF_ROUTER_NODE_TYPE=#{router_dns_type}")
      end

      case auth_type
      when "HTPASSWD"
        identity_providers = "[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '#{crt_path}/htpasswd'}]"
      when "LDAP"
        identity_providers = %Q|[{"name": "LDAPauth", "login": "true", "challenge": "true", "kind": "LDAPPasswordIdentityProvider", "attributes": {"id": ["dn"], "email": ["mail"], "name": ["uid"], "preferredUsername": ["uid"]}, "bindDN": "", "bindPassword": "", "ca": "", "insecure":"true", "url": "#{ldap_url}"}]|
      else
        identity_providers = "[{'name': 'basicauthurl', 'login': 'true', 'challenge': 'true', 'kind': 'BasicAuthPasswordIdentityProvider', 'url': 'https://<serviceIP>:8443/validate', 'ca': '#{crt_path}master/ca.crt'}]"
      end

      ose3_vars = []
      etcd_host_lines = []
      master_host_lines = []
      node_host_lines = []
      lb_host_lines = []

     if !customized_ansible_conf.empty?
       ose3_vars << customized_ansible_conf
     end


      ## lets sanity check auth type
      if auth_type != "LDAP" && hosts["master"].size > 1
        raise "multiple HA masters require LDAP auth"
      end

      ## Setup HA Master opt
      # * if non-HA master => router selector should point at nodes, num_infra should be == number of nodes, DNS should point at nodes
      # * if HA masters => router selector sohuld point at masters (region=infra), num_infra should be == number of masters, DNS should point at masters

      # num infra needed only when creating a router by ansible
      # https://bugzilla.redhat.com/show_bug.cgi?id=1274129
      # I think it selects number of router replicas. Should be same as
      #   masters or nodes number (depending where it is to be run

      ## select load balancer node
      if hosts["master"].size > 1
        lb_node = hosts["node"].sample
        # TODO: can we use one of masters for a load balancer?
        raise "HA masters need a node for load balancer" unless lb_node
      end

      if hosts["master"].size > 1
        master_nodes_labels_str = %Q*openshift_node_labels="{'region': 'infra', 'zone': 'default'}" openshift_scheduleable=True*
        ose3_vars << "openshift_registry_selector='region=infra'"
        ose3_vars << "openshift_router_selector='region=infra'"
        ose3_vars << "num_infra=#{ hosts["master"].size }"
        router_dns_type = "master"
      elsif hosts.values.flatten.size > 1
        master_nodes_labels_str = "openshift_scheduleable=False"
        ose3_vars << "openshift_registry_selector='region=primary'"
        ose3_vars << "openshift_router_selector='region=primary'"
        ose3_vars << "num_infra=#{ hosts["node"].size }"
        router_dns_type = "node"
      else
        # this is all-in-one
        master_nodes_labels_str = %Q*openshift_node_labels="{'region': 'primary', 'zone': 'default'}"*
        ose3_vars << "openshift_registry_selector='region=primary'"
        ose3_vars << "openshift_router_selector='region=primary'"
        ose3_vars << "num_infra=1"
        router_dns_type = "master"
      end
      router_ips = hosts[router_dns_type].map{|h| h.ip}

      ## Setup HA Master opts End

      ## DNS config
      case dns
      when nil, false, "", "none"
        # basically do nothing
        host_domain ||= "cluster.local"
        raise "specify :app_domain and :host_domain" unless app_domain
      #when "embedded"
      #  host_domain ||= "cluster.local"
      #  app_domain ||= rand_str(5, :dns) + ".example.com"
      #  conf_script.gsub!(
      #    /#CONF_DNS_IP=.*$/,
      #    "CONF_DNS_IP=#{hosts['master'][0].ip}"
      #  )
      #  conf_script.gsub!(/#USE_OPENSTACK_DNS=.*$/, "USE_OPENSTACK_DNS=true")
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
          dns_subst.call
          check_res \
            dns_host.exec_admin('cat > configure_env.sh', stdin: conf_script)
          check_res \
            dns_host.exec_admin('sh -x configure_env.sh configure_shared_dns')
        ensure
          dns_host.clean_up
        end
      when /^dyn$/
        require 'launchers/dyn/dynect'
        host_domain ||= "cluster.local"
        dyn = CucuShift::Dynect.new()

        begin
          if app_domain
            # validity of app zone up to the user that has set it
            dyn.dyn_create_a_records("*.#{app_domain}", router_ips)
            dyn.publish
          else
            rec = dyn.dyn_create_random_a_wildcard_records(router_ips)
            dyn.publish
            app_domain = rec.sub(/^\*\./, '')
          end
        ensure
          dyn.close
        end
      else
        host_domain ||= "cluster.local"
        raise "specify :app_domain and :host_domain" unless app_domain
        conf_script.gsub!(/#CONF_DNS_IP=.*$/, dns)
      end

      dns_subst.call # double substritution (if happens) should not hurt
      ## DNS config End

      hosts.each do |role, role_hosts|
        role_hosts.each do |host|
          # upload to host with cat
          check_res \
            host.exec_admin('cat > configure_env.sh', stdin: conf_script)

          ## wait cloud-init setup to finish
          check_res host.exec_admin("sh configure_env.sh wait_cloud_init",
                                    timeout: 1800)

          if rhel_base_repo
            check_res host.exec_admin("sh configure_env.sh configure_repos")
          end
          if dns.start_with?("embedded_skydns")
            check_res host.exec_admin("sh configure_env.sh configure_hosts")
          end

          case role
          when "master"
            # TODO: assumption is only one master
            #if dns == "embedded"
            #  check_res host.exec_admin('sh configure_env.sh configure_dns')
            #elsif dns
            #  check_res \
            #    host.exec_admin('sh configure_env.sh configure_dns_resolution')
            #end

            if dns == "embedded_skydns"
              host_base_line = "#{host.hostname} openshift_hostname=master.#{host_domain} openshift_public_hostname=master.#{host_domain}"
            else
              host_base_line = "#{host.hostname} openshift_hostname=#{host.hostname} openshift_public_hostname=#{host.hostname}"
            end

            host_line = host_base_line.dup
            master_host_lines << host_line.dup

            host_line << " " << master_nodes_labels_str
            node_host_lines << host_line
          else
            if dns == "embedded_skydns"
              node_index = node_host_lines.size + 1
              host_base_line = "#{host.hostname} openshift_hostname=minion#{node_index}.#{host_domain} openshift_public_hostname=minion#{node_index}.#{host_domain}"
            else
              host_base_line = "#{host.hostname} openshift_hostname=#{host.hostname} openshift_public_hostname=#{host.hostname}"
            end
            host_line = %Q*#{host_base_line} openshift_node_labels="{'region': 'primary', 'zone': 'default'}"*
            node_host_lines << host_line

            #if dns
            #  check_res \
            #    host.exec_admin('sh configure_env.sh configure_dns_resolution')
            #end
          end

          # select etcd nodes
          if Integer(etcd_num) > etcd_host_lines.size
            etcd_host_lines << host_base_line
            # etcd_host_lines << host.hostname
          end

          # setup Load Balancer node(s); selected randomly before hosts loop
          if host == lb_node
            lb_host_lines << host_base_line
            ose3_vars << "openshift_master_cluster_public_hostname=#{host.hostname}"
            ose3_vars << "openshift_master_cluster_hostname=#{host.hostname}"
            ose3_vars << "openshift_master_cluster_method=native"
            ose3_vars << "openshift_master_ha=true"
          end
        end
      end

      hosts_str = ERB.new(File.read(hosts_erb)).result binding

      # finally run download repo and run ansible (this is in workdir)
      # we need git and ansible available pre-installed
      check_res Host.localhost.exec(
        "git clone #{ansible_url} -b #{ansible_branch}"
      )
      res = nil
      ENV["ANSIBLE_FORCE_COLOR"] = "true"
      Dir.chdir(Host.localhost.workdir) {
        logger.info("hosts file:\n" + hosts_str)
        File.write("hosts", hosts_str)
        # want to see output in real-time so Host#exec does not work
        # TODO: use new LocalHost exec functionality
        ssh_key_param = expand_private_path(ssh_key)
        File.chmod(0600, ssh_key_param)
        ansible_cmd = "ansible-playbook -i hosts -v --private-key #{Host.localhost.shell_escape(ssh_key_param)} -vvvv openshift-ansible/playbooks/byo/config.yml"
        logger.info("Running: #{ansible_cmd}")
        res = system(ansible_cmd)
      }
      case res
      when false
        raise "ansible failed with status: #{$?}"
      when nil
        raise "ansible failed to execute"
      end

      # check_res hosts['master'][0].exec_admin(
      #   "sh configure_env.sh replace_template_domain"
      # )
      check_res hosts['master'][0].exec_admin(
        "sh configure_env.sh create_router_registry"
      )

      if registry_ha
        check_res hosts['master'][0].exec_admin(
          'sh configure_env.sh configure_nfs_service'
        )
        check_res hosts['master'][0].exec_admin(
          'sh configure_env.sh configure_registry_to_ha'
        )
      end
      if dns == "embedded_skydns"
        check_res hosts['master'][0].exec_admin(
          "sh configure_env.sh add_skydns_hosts"
        )
      end
      if auth_type == "KERBEROS"
        check_res hosts['master'][0].exec_admin(
          'sh configure_env.sh configure_auth'
        )
      end
      if !modify_IS_for_testing.empty?
          check_res hosts['master'][0].exec_admin(
            "sh configure_env.sh modify_IS_for_testing #{modify_IS_for_testing}"
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

      # workaround https://issues.jenkins-ci.org/browse/JENKINS-30719
      # that means to remove extra `\` chars
      ENV['IMAGE_PRE'] = ENV['IMAGE_PRE'].gsub(/\\\${/,'${') if ENV['IMAGE_PRE']

      keys = [:crt_path, :deployment_type,
              :hosts_spec, :auth_type,
              :ssh_key, :ssh_user,
              :app_domain, :host_domain,
              :rhel_base_repo,
              :dns, :deployment_type,
              :image_pre,
              :puddle_repo, :network_plugin,
              :etcd_num, :registry_ha,
              :ansible_branch, :ansible_url,
              :customized_ansible_conf,
              :modify_IS_for_testing,
              :kerberos_docker_base_image,
              :kerberos_kdc, :kerberos_keytab_url,
              :kerberos_docker_base_image,
              :kerberos_admin_server]

      keys.each do |key|
        if ENV[key.to_s.upcase] && !ENV[key.to_s.upcase].empty?
          opts[key] = ENV[key.to_s.upcase]
        end
      end

      opts[:registry_ha] = false unless to_bool(opts[:registry_ha])
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
