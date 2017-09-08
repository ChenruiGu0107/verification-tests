# helper step for logging and metrics scenarios
require 'configparser'
require 'oga'

# since the logging and metrics module can be deployed and used in any namespace, this step is used to determine
# under what namespace the logging/metrics module is deployed under by getting all of the projects as admin and
And /^I save the (logging|metrics) project name to the#{OPT_SYM} clipboard$/ do |svc_type, clipboard_name|
  ensure_destructive_tagged

  if clipboard_name.nil?
    cb_name = svc_type
  else
    cb_name = clipboard_name
  end
  if svc_type == 'logging'
    expected_rc_name = "logging-kibana-1"
  else
    expected_rc_name = "hawkular-metrics"
  end
  found_proj = CucuShift::Project.get_matching(user: admin) { |project, project_hash|
    rc(expected_rc_name, project).exists?(user: admin, quiet: true)
  }
  if found_proj.count != 1
    raise ("Found #{found_proj.count} #{svc_type} services installed in the cluster, expected 1")
  else
    cb[cb_name] = found_proj[0].name
  end
end

Given /^there should be (\d+) (logging|metrics) services? installed/ do |count, svc_type|
  ensure_destructive_tagged

  if svc_type == 'logging'
    expected_rc_name = "logging-kibana-1"
  else
    expected_rc_name = "hawkular-metrics"
  end

  found_proj = CucuShift::Project.get_matching(user: admin) { |project, project_hash|
    rc(expected_rc_name, project).exists?(user: admin, quiet: true)
  }
  if found_proj.count != Integer(count)
    raise ("Found #{found_proj.count} #{svc_type} services installed in the cluster, expected #{count}")
  end
end

# short-hand for the generic uninstall step if we are just using the generic install
Given /^I remove (logging|metrics) service installed in the#{OPT_QUOTED} project using ansible$/ do | svc_type, proj_name|
  proj_name = project.name if proj_name.nil?
  step %Q/#{svc_type} service is uninstalled from the "#{proj_name}" project with ansible using:/, table(%{
    | inventory| https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/generic_uninstall_inventory |
  })
end

# helper step that does the following:
# 1. figure out project and route information
Given /^I login to kibana logging web console$/ do
  step %Q/I save the logging project name to the :logging clipboard/
  step %Q/admin save the hostname of route "logging-kibana" in project "<%= cb['logging'] %>" to the :logging_route clipboard/
  step %Q/I have a browser with:/, table(%{
    | rules    | lib/rules/web/images/logging/   |
    | rules    | lib/rules/web/console/base/     |
    | base_url | https://<%= cb.logging_route %> |
    })
  step %Q/I perform the :kibana_login web action with:/, table(%{
    | username   | <%= user.name %>                |
    | password   | <%= user.password %>            |
    | kibana_url | https://<%= cb.logging_route %> |
    })
end

# ##  curl
# -H "Authorization: Bearer $USER_TOKEN"
# -H "Hawkular-tenant: $PROJECT"
# -H "Content-Type: application/json"
# -X POST/GET https://hawkular-metrics.$SUBDOMAIN/hawkular/metrics/{gauges|metrics|counters}
### https://hawkular-metrics.0227-ep7.qe.rhcloud.com/hawkular/metrics/metrics
# acceptable parameters are:
# 1. | project_name | name of project |
# 2. | type  | type of metrics you want to query {gauges|metrics|counters} |
# 3. | payload | for POST only, local path or url |
# 4. | metrics_id | for single POST payload that does not have 'id' specified and user want an id other than the default of 'datastore'
# NOTE: for GET operation, the data retrieved are stored in cb.metrics_data which is an array
# NOTE: if we agree to use a fixed name for the first part of the metrics URL, then we don't need admin access privilege to run this step.
When /^I perform the (GET|POST) metrics rest request with:$/ do | op_type, table |
  if !env.opts[:admin_cli]
    # for Online/STG/INT, we just get the URL from env
    cb['metrics'] = env.metrics_console_url
  else
    unless cb[:metrics]
      unless cb.subdomain
        cb.subdomain = env.router_default_subdomain(user: user, project: project)
      end
      cb[:metrics] = 'https://hawkular-metrics.' + cb[:subdomain] + '/hawkular'
    end
    # if cb.metrics does not have the proper form, we need to set it.
    cb[:metrics] = 'https://hawkular-metrics.' + cb.metrics + '/hawkular' unless cb.metrics.start_with? "https://"
  end
  opts = opts_array_to_hash(table.raw)
  raise "required parameter 'path' is missing" unless opts[:path]

  bearer_token = opts[:token] ? opts[:token] : user.get_bearer_token.token

  https_opts = {}
  https_opts[:headers] ||= {}
  https_opts[:headers][:accept] ||= "application/json"
  https_opts[:headers][:content_type] ||= "application/json"
  https_opts[:headers][:hawkular_tenant] ||= opts[:project_name]
  https_opts[:headers][:authorization] ||= "Bearer #{bearer_token}"
  https_opts[:headers].delete(:hawkular_tenant) if opts[:project_name] == ":false"
  metrics_url = cb.metrics + opts[:path]

  if op_type == 'POST'
    file_name = opts[:payload]
    if %w(http https).include? URI.parse(opts[:payload]).scheme
      # user given a http source as a parameter
      step %Q/I download a file from "#{opts[:payload]}"/
      file_name = @result[:file_name]
    end
    https_opts[:payload] = File.read(expand_path(file_name))

    # the payload JSON does not have 'id' specified, so we need to look for
    # metrics_id to be specified in the table or if not there, then we
    # default the id to 'datastore'
    unless YAML.load(https_opts[:payload]).first.keys.include? 'id'
      metrics_id = opts[:metrics_id].nil?  ? "datastore" : opts[:metrics_id]
      metrics_url = metrics_url + "/" + metrics_id
    end
    url = metrics_url + "/raw"
  else
    url = opts[:metrics_id] ? metrics_url + "/" + opts[:metrics_id] : metrics_url
  end
  cb.metrics_data = []

  @result = CucuShift::Http.request(url: url, **https_opts, method: op_type)

  @result[:parsed] = YAML.load(@result[:response]) if @result[:success]
  if (@result[:parsed].is_a? Array) and (op_type == 'GET') and opts[:metrics_id].nil?
    @result[:parsed].each do | res |
      logger.info("Getting data from metrics id #{res['id']}...")
      query_url = url + "/" + res['id']
      # get the id to construct the metric_url to do the QUERY operation
      result = CucuShift::Http.request(url: query_url, **https_opts, method: op_type)
      result[:parsed] = YAML.load(result[:response])
      cb.metrics_data << result
    end
  else
    cb.metrics_data << @result
  end
end
# unless project name is given we assume all logging pods are installed under the current project
Given /^all logging pods are running in the#{OPT_QUOTED} project$/ do | proj_name |
  proj_name = project.name if proj_name.nil?
  org_proj_name = project.name
  org_user = user
  if proj_name == 'logging'
    ensure_destructive_tagged
    step %Q/I switch to cluster admin pseudo user/
    project(proj_name)
  end
  begin
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=curator,logging-infra=curator |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=es,logging-infra=elasticsearch |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=fluentd,logging-infra=fluentd |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=kibana, logging-infra=kibana |
      })
  ensure
    @user = org_user
    project(org_proj_name)
  end
end

## for OCP <= 3.4, the labels and number of pods are different so going to
#  use a different step name to differentiate
Given /^all deployer logging pods are running in the#{OPT_QUOTED} project$/ do | proj_name |
  proj_name = project.name if proj_name.nil?
  org_proj_name = project.name
  org_user = user
  if proj_name == 'logging'
    ensure_destructive_tagged
    step %Q/I switch to cluster admin pseudo user/
    project(proj_name)
  end
  begin
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=curator |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=curator-ops |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=es |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=es-ops |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=fluentd |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=kibana |
      })
     step %Q/all existing pods are ready with labels:/, table(%{
      | component=kibana-ops |
      })
  ensure
    @user = org_user
    project(org_proj_name)
  end
end

# we force all metrics pods to be installed under the project 'openshift-infra'
Given /^all metrics pods are running in the#{OPT_QUOTED} project$/ do | proj_name |

  target_proj = proj_name.nil? ? project.name : proj_name
  raise ("Metrics must be installed into the 'openshift-infra") if target_proj != 'openshift-infra'

  org_proj_name = project.name
  org_user = user
  ensure_destructive_tagged
  step %Q/I switch to cluster admin pseudo user/
  project(target_proj)
  begin
    step %Q/I wait until replicationController "hawkular-cassandra-1" is ready/
    step %Q/I wait until replicationController "hawkular-metrics" is ready/
    step %Q/I wait until replicationController "heapster" is ready/
  ensure
    @user = org_user
    project(org_proj_name)
  end
end
# Parameters in the inventory that need to be replaced should be in ERB format
# if no project name is given, then we assume will use the project mapping of
# logging ==> current_project_name , metrics ==> 'openshift-infra'
# step will raise exception if metrics name is not 'openshift-infra'
Given /^(logging|metrics) service is (installed|uninstalled) (?:in|from) the#{OPT_QUOTED} project with ansible using:$/ do |svc_type, op, proj, table|
  ensure_destructive_tagged

  if op == 'installed'
    step %Q/there should be 0 #{svc_type} service installed/
  end

  # check tht logging/metric is not installed in the target cluster already.
  ansible_opts = opts_array_to_hash(table.raw)

  target_proj = proj.nil? ? project.name : proj
  # we are enforcing that metrics to be installed into 'openshift-infra'
  target_proj = 'openshift-infra' if svc_type == 'metrics'
  cb.metrics_route_prefix = "metrics"
  cb.logging_route_prefix = "logs"

  if svc_type == 'metrics' and target_proj != 'openshift-infra'
    raise ("Metrics must be installed into the 'openshift-infra")
  end

  logger.info("Performing operation '#{op[0..-3]}' to #{target_proj}...")
  if op == 'installed'
    step %Q/I register clean-up steps:/, table(%{
      | I remove #{svc_type} service installed in the "#{target_proj}" project using ansible |
      })
  end

  raise "Must provide inventory option!" unless ansible_opts.keys.include? 'inventory'.to_sym
  # use ruby instead of step to bypass user restriction
  cb.subdomain = env.router_default_subdomain(user: user, project: project)
  step %Q/I store master major version in the :master_version clipboard/
  step %Q/I create the "tmp" directory/

  # prep the inventory file.
  cb.master_url = env.master_hosts.first.hostname
  cb.api_port = '8443' if cb.api_port.nil?

  step %Q/I download a file from "<%= "#{ansible_opts[:inventory]}" %>" into the "tmp" dir/

  if op == 'installed'
    new_path = "tmp/install_inventory"
  else
    new_path = "tmp/uninstall_inventory"
  end
  cb.target_proj = target_proj
  org_user = user
  # we may not have the minor version of the image loaded. so just use the
  # major version label
  cb.master_version = cb.master_version[0..2]
  loaded = ERB.new(File.read(@result[:abs_path])).result binding
  File.write(new_path, loaded)
  # create a tmp directory which will store the following files to be 'oc rsync to the pod created
  # 1. inventory
  # 2. libra.pem
  # 3. admin.kubeconfig from the master node
  pem_file_path = expand_path(env.master_hosts.first[:ssh_private_key])
  FileUtils.copy(pem_file_path, "tmp/")
  @result = admin.cli_exec(:oadm_config_view, flatten: true, minify: true)
  File.write(File.expand_path("tmp/admin.kubeconfig"), @result[:response])

  if ansible_opts[:copy_custom_cert]
    key_name = "cucushift_custom.key"
    cert_name = "cucushift_custom.crt"
    if svc_type == 'metrics'
      hostname = "#{cb.metrics_route_prefix}.#{cb.subdomain}"
    else
      hostname = "#{cb.logging_route_prefix}.#{cb.subdomain}"
    end
    # base_path corresponds to the inventory, for example https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12186/inventory
    base_path = "/tmp/#{File.basename(host.workdir)}/"
    cb.key_path = "#{base_path}/#{key_name}"
    cb.cert_path = "#{base_path}/#{cert_name}"
    cb.ca_crt_path = "#{base_path}/ca.crt"
  end

  begin
    step %Q/I switch to cluster admin pseudo user/
    step %Q/I have a pod with openshift-ansible playbook installed/
    # we need to scp the key and crt and ca.crt to the ansible installer pod
    # prior to the ansible install operation
    if ansible_opts[:copy_custom_cert]
      step %Q/the custom certs are generated with:/, table(%{
        | key       | #{key_name}  |
        | cert      | #{cert_name} |
        | hostnames | #{hostnames} |
        })

      @result = host.exec_admin("cp -f /etc/origin/master/ca.crt #{host.workdir}")
      step %Q/the step should succeed/
      sync_certs_cmd = "oc project #{project.name}; oc rsync #{host.workdir} base-ansible-pod:/tmp"
      @result = host.exec_admin(sync_certs_cmd)
      step %Q/the step should succeed/
    end
    if svc_type == 'logging'
      ansible_template_path = "/usr/share/ansible/openshift-ansible/playbooks/byo/openshift-cluster/openshift-logging.yml"
    else
      ansible_template_path = "/usr/share/ansible/openshift-ansible/playbooks/byo/openshift-cluster/openshift-metrics.yml"
    end
    step %Q/I execute on the pod:/, table(%{
      | ansible-playbook | -i | /tmp/#{new_path} | #{conf[:ansible_log_level]} | #{ansible_template_path} |
      })
    step %Q/the step should succeed/

    # the openshift-ansible playbook restarts master at the end, we need to run the following to just check the master is ready.
    step %Q/the master is operational/

    if op == 'installed'
      if svc_type == 'logging'
        # there are 4 pods we need to verify that should be running  logging-curator,
        # logging-es, logging-fluentd, and logging-kibana
        step %Q/all logging pods are running in the "#{target_proj}" project/
      else
        step %Q/all metrics pods are running in the "#{target_proj}" project/
      end
    else
      if svc_type == 'logging'
        step %Q/there should be 0 logging service installed/
      else
        step %Q/there should be 0 metrics service installed/
      end
    end
  ensure
    @user = org_user
  end
end

# download the deployer config file and translate the ERB and store the result
# into the clipboard index :deployer_config
Given /^I parse the INI file #{QUOTED}$/ do |deployer_config_file|
  # use ruby instead of step to bypass user restriction
  step %Q/I download a file from "<%= "#{deployer_config_file}" %>"/
  step %Q/the step should succeed/
  config = ConfigParser.new(@result[:file_name])
  cb.deployer_config = config
end

Given /^logging service is installed in the#{OPT_QUOTED} project using deployer:$/ do |proj, table|
  ensure_destructive_tagged
  deployer_opts = opts_array_to_hash(table.raw)
  raise "Must provide deployer configuration file!" unless deployer_opts.keys.include? 'deployer_config'.to_sym
  logger.info("Performing logging installation using deployer")
  # step %Q/the first user is cluster-admin/
  step %Q/I switch to cluster admin pseudo user/
  step %Q/I use the "<%= project.name %>" project/
  step %Q/I store master major version in the :master_version clipboard/
  cb.master_url = env.master_hosts.first.hostname
  cb.subdomain = env.router_default_subdomain(user: user, project: project)

  unless cb.deployer_config
    step %Q/I download a file from "<%= "#{deployer_opts[:deployer_config]}" %>"/
    cb.deployer_config = YAML.load(ERB.new(File.read(@result[:abs_path])).result binding)
  end
  step %Q/I register clean-up steps:/, table(%{
    | I remove logging service installed in the project using deployer |
    })
  # create the configmap
  step %Q|I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/logging_deployer_configmap.yaml|
  step %Q/the step should succeed/
  # must create a label or else installation will fail
  registry_nodes = CucuShift::Node.get_labeled(["registry"], user: user)
  registry_nodes.each do |node|
    step %Q/label "logging-infra-fluentd=true" is added to the "#{node.name}" node/
    step %Q/the step should succeed/
  end

  # create new secret
  step %Q/I run the :new_secret client command with:/, table(%{
    | secret_name     | logging-deployer  |
    | credential_file | nothing=/dev/null |
  })
  step %Q/the step should succeed/

  # create necessary accounts
  step %Q/I run the :new_app client command with:/, table(%{
    | app_repo | logging-deployer-account-template |
    })
  #step %Q/the step should succeed/
  step %Q/cluster role "oauth-editor" is added to the "system:serviceaccount:<%= project.name %>:logging-deployer" service account/
  step %Q/SCC "privileged" is added to the "system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd" service account/
  step %Q/cluster role "cluster-reader" is added to the "system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd" service account/
  raise "Unable to get master version" if cb.master_version.nil?
  if cb.master_version >= "3.4"
    step %Q/cluster role "rolebinding-reader" is added to the "system:serviceaccounts:<%= project.name %>:aggregated-logging-elasticsearch" service account/
  end

  step %Q/I run the :new_app client command with:/, table(%{
      | app_repo | logging-deployer-template |
                                                         })
  step %Q/the step should succeed/
  # we need to wait for the deployer to be completed first
  step %Q/status becomes :succeeded of 1 pod labeled:/, table(%{
    | app=logging-deployer-template |
    | logging-infra=deployer        |
    | provider=openshift            |
    })
  step %Q/I wait for the container named "deployer" of the "#{pod.name}" pod to terminate with reason :completed/
  # verify logging is installed
  step %Q/all deployer logging pods are running in the project/
end

# following instructions here:
# we must use the project 'openshift-infra'
Given /^metrics service is installed in the project using deployer:$/ do |table|
  ensure_destructive_tagged
  org_proj_name = project.name
  org_user = user
  target_proj = 'openshift-infra'
  deployer_opts = opts_array_to_hash(table.raw)
  raise "Must provide deployer configuration file!" unless deployer_opts.keys.include? 'deployer_config'.to_sym
  logger.info("Performing metrics installation by deployer")
  step %Q/I switch to cluster admin pseudo user/
  project(target_proj)

  step %Q/I store master major version in the :master_version clipboard/
  cb.subdomain = env.router_default_subdomain(user: user, project: project)

  # sanity check, fail early if we can't get the master version
  raise "Unable to get subdomain" if cb.subdomain.nil?

  unless cb.deployer_config
    step %Q/I download a file from "<%= "#{deployer_opts[:deployer_config]}" %>"/
    cb.deployer_config = YAML.load(ERB.new(File.read(@result[:abs_path])).result binding)
  end
  metrics_deployer_params = [
    "HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.#{cb.subdomain}",
    "IMAGE_PREFIX=#{product_docker_repo}openshift3/",
    "IMAGE_VERSION=#{cb.master_version}",
    "MASTER_URL=#{env.api_endpoint_url}",
  ]
  # check to see what the user specified any parameters to be different from default values
  # We are treating all UPCASE params as metrics deployer specific parameter
  user_defined_params = []
  deployer_opts.each do |k, v|
    if k.upcase == k
      user_defined_params << k
      metrics_deployer_params << "#{k}=#{v}"
    end
  end
  # XXX: for automation testing, we are overriding the following default config unless user specified them in the top level step call
  cb.deployer_config['metrics'].keys.each do | k |
    # make sure we are only adding user defined
    if k.upcase == k
      unless user_defined_params.include? k
        metrics_deployer_params << "#{k}=#{cb.deployer_config['metrics'][k]}"
      end
    end

  end
  #   the param is set by user
  step %Q/I register clean-up steps:/, table(%{
    | I remove metrics service installed in the project using deployer |
    })
  # create new secret
  step %Q/I run the :new_secret client command with:/, table(%{
    | secret_name     | metrics-deployer  |
    | credential_file | nothing=/dev/null |
    | n               | #{target_proj}    |
  })
  step %Q/the step should succeed/

  # create necessary accounts
  step %Q/I run the :create client command with:/, table(%{
    | f | <%= cb.deployer_config['metrics']['serviceaccount_metrics_deployer'] %> |
    | n | <%= project.name %>                                                     |
    })
  step %Q/the step should succeed/
  step %Q/cluster role "edit" is added to the "system:serviceaccount:<%= project.name %>:metrics-deployer" service account/
  step %Q/the step should succeed/
  step %Q/cluster role "view" is added to the "system:serviceaccount:<%= project.name %>:hawkular" service account/
  step %Q/the step should succeed/
  step %Q/cluster role "cluster-reader" is added to the "heapster" service account/
  step %Q/the step should succeed/
  @result = user.cli_exec(:new_app, template: "metrics-deployer-template",
    n: project.name, param: metrics_deployer_params)

  step %Q/the step should succeed/
  # we need to wait for the deployer to be completed first
  step %Q/status becomes :running of 1 pod labeled:/, table(%{
    | app=metrics-deployer-template |
    | logging-infra=deployer        |
    | provider=openshift            |
    })
  step %Q/I wait for the container named "deployer" of the "#{pod.name}" pod to terminate with reason :completed/
  # verify metrics is installed
  step %Q/all metrics pods are running in the project/
  # we need to switch back to normal user and the original project
  @user = org_user
  project(org_proj_name)
end

Given /^I remove logging service installed in the#{OPT_QUOTED} project using deployer$/ do |proj|
  ensure_destructive_tagged
  if env.version_ge("3.2", user: user)
    step %Q/I run the :new_app admin command with:/, table(%{
      | app_repo | logging-deployer-template |
      | param    | MODE=uninstall            |
                                                            })
    # due to bug https://bugzilla.redhat.com/show_bug.cgi?id=1467984 we need to
    # do manual cleanup on some of the resources that are not deleted by
    # project removal
    @result = admin.cli_exec(:delete, {object_type: 'clusterrole', object_name_or_id: 'oauth-editor', n: 'default'})
    @result = admin.cli_exec(:delete, {object_type: 'clusterrole', object_name_or_id: 'daemonset-admin ', n: 'default'})
    @result = admin.cli_exec(:delete, {object_type: 'clusterrole', object_name_or_id: 'rolebinding-reader', n: 'default'})
    @result = admin.cli_exec(:delete, {object_type: 'oauthclients', object_name_or_id: 'kibana-proxy', n: 'default'})
  end
end

# the requirement has always been metrics is installed under the project
# openshift-infra
Given /^I remove metrics service installed in the#{OPT_QUOTED} project using deployer$/ do |proj_name|
  ensure_destructive_tagged
  proj_name = 'openshift-infra' if proj_name.nil?
  @result = admin.cli_exec(:delete, object_name_or_id: 'all,secrets,sa,templates', l: 'metrics-infra', 'n': 'openshift-infra')
  @result = admin.cli_exec(:delete, {object_type: 'sa', object_name_or_id: 'metrics-deployer', 'n': 'openshift-infra'})
  @result = admin.cli_exec(:delete, {object_type: 'secrets', object_name_or_id: 'metrics-deployer', 'n': 'openshift-infra'})
end


# check openshift-ansible is installed in a node, if not, then do rpm or yum
# installation
Given /^openshift-ansible is installed in the #{QUOTED} node$/ do | node_name |
  ensure_admin_tagged
  # switch to use the target node
  host = node(node_name).host
  check_host = host.exec("cat /etc/redhat-release")
  raise "No release information in node" unless check_host[:success]

  if check_host[:response].include? "Atomic Host" and !conf[:openshift_ansible_installer].start_with? 'git'
    raise "Installation method not support currently in Atomic Host"
  end

  res = host.exec_admin("ls /usr/share/ansible/openshift-ansible/")
  unless res[:success]
    if conf[:openshift_ansible_installer] == 'yum'
      logger.info("Installing openshift-ansible via yum")
      yum_install_cmd = "yum -y install openshift-ansible*"
      res = host.exec_admin(yum_install_cmd)
      has_playbooks = host.exec_admin("ls /usr/share/ansible/openshift-ansible/playbooks")
      raise "Unable to install openshift-ansible via yum" unless has_playbooks[:success]
    elsif conf[:openshift_ansible_installer] == 'git'
      pass
    else
      raise "Unsupported installation method"
    end
  end
end

# wrapper step to
# 1. spin up a openshift-ansible pod
# 2. install openshift-ansible playbook (via yum or git)
Given /^I have a pod with openshift-ansible playbook installed$/ do
  ensure_admin_tagged
  # we need to save the original project name for post test cleanup
  cb.org_project_for_ansible ||= project
  # to save time we are going to check if the base-ansible-pod already exists
  # use admin user to get the information so we don't need to swtich user.
  unless pod("base-ansible-pod", cb.org_project_for_ansible).exists?(user: admin)
    step %Q/I run the :create admin command with:/, table(%{
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/base_fedora_pod.yaml |
      | n | <%= project.name %>                                                                                     |
    })
    step %Q/the step should succeed/
    step %Q/the pod named "base-ansible-pod" becomes ready/
    # save it for future use
    cb.ansible_runner_pod = pod

    if conf[:openshift_ansible_installer].start_with? 'git#'
      branch_name = conf[:openshift_ansible_installer][4..-1]
    end
    step %Q`I save the rpm names matching /openshift-ansible/ from puddle to the :openshift_ansible_rpms clipboard`
    cb.repo_url = cb.puddle_url.split('x86_64')[0] + "puddle.repo"
    # extract the commit id for git checkout later
    commit_id = cb.openshift_ansible_rpms[0].match(/git.\d+.(\w+)/)[1]

    download_cmd = "cd /etc/yum.repos.d/; curl -L -O #{cb.repo_url}"

    @result = pod.exec("bash", "-c", download_cmd, as: user)
    step %Q/the step should succeed/
    install_ansible_cmd = 'yum -y install ansible'
    @result = pod.exec("bash", "-c", install_ansible_cmd, as: user)
    step %Q/the step should succeed/
    # openshift-ansible via rpm or just do git clone from branch name
    if conf[:openshift_ansible_installer] == "yum" or conf[:openshift_ansible_installer] == "rpm"
      install_openshift_ansible_cmd = 'yum -y install openshift-ansible*'
      step %Q/I execute on the pod:/, table(%{
        | bash                             |
        | -c                               |
        | #{install_openshift_ansible_cmd} |
        })
      step %Q/the step should succeed/
    elsif conf[:openshift_ansible_installer].start_with? "git"
      if branch_name
        git_cmd = "cd /usr/share/ansible && git clone https://github.com/openshift/openshift-ansible/ -b #{branch_name}"
      else
        git_cmd = "cd /usr/share/ansible && git clone https://github.com/openshift/openshift-ansible/ && cd openshift-ansible && git checkout #{commit_id}"
      end

      @result = pod.exec("bash", "-c", git_cmd, as: user)
      step %Q/the step should succeed/
    else
      raise "Installation method '#{conf[:openshift_ansible]}' is currently not supported"
    end
  end
  @result = admin.cli_exec(:rsync, source: localhost.absolutize("tmp"), destination: "base-ansible-pod:/tmp", loglevel: 5, n: cb.org_project_for_ansible.name)
  step %Q/the step should succeed/
end



Given /^I save installation inventory from master to the#{OPT_SYM} clipboard$/ do | cb_name |
  ensure_admin_tagged

  cb_name ||= :installation_inventory
  host = env.master_hosts.first
  qe_inventory_file = 'qe-inventory-host-file'
  @result = host.exec("cat /tmp/#{qe_inventory_file}")
  if @result[:success]
    config = ConfigParser.new
    config.parse(@result[:response].each_line)
    cb[cb_name] = config
  else
    raise "'#{qe_inventory_file}' does not exists"
  end
end

# get the puddle information from master's /tmp/qe-inventory-host-file
# @returns a copule of clipboard informaiton:
#  1. :installation_inventory contains the installation inventory
#  2. :rpms contains an array of all the rpms for the puddle
#  3. :puddle_url
#  4. :rpm_name
Given /^I save the rpm names? matching #{RE} from puddle to the#{OPT_SYM} clipboard$/ do | package_pattern, cb_name |
  ensure_admin_tagged

  cb_name ||= :rpm_names
  step %Q/I save installation inventory from master to the clipboard/
  rpm_repos_key = cb[:installation_inventory].keys.include?('openshift_playbook_rpm_repos') ? 'openshift_playbook_rpm_repos' : 'openshift_additional_repos'
  puddle_url = eval(cb[:installation_inventory][rpm_repos_key])[0][:baseurl]
  cb.puddle_url = puddle_url
  @result = CucuShift::Http.get(url: puddle_url + "/Packages")

  doc = Oga.parse_html(@result[:response])
  rpms = (doc.css('a').select { |l| l.attributes[0].value if l.attributes[0].value.end_with? 'rpm'  }).map { |r| r.children[0].text}
  cb.rpms = rpms
  rpm_names = rpms.select { |r| r =~ /#{package_pattern}/ }
  raise "No matching rpm found for #{package_pattern}" if rpm_names.count == 0
  cb[cb_name] = rpm_names
end


### mother of all logging/metrics steps: Call this regardless of master version
### assume we already have called the following step to create a project name
### I create a project with non-leading digit name
# use this step if we just want to use default values
Given /^(logging|metrics) service is installed in the system$/ do | svc |
  if env.version_ge("3.5", user: user)
    param_name = 'inventory'
    param_value = "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_inventory"
  else
    param_name = 'deployer_config'
    param_value = "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_deployer.yaml"
  end
  step %Q/#{svc} service is installed in the system using:/, table(%{
    | #{param_name} | #{param_value} |
    })

end

Given /^(logging|metrics) service is installed in the system using:$/ do | svc, table |
  ensure_destructive_tagged

  params = opts_array_to_hash(table.raw) unless table.nil?
  if env.version_ge("3.5", user: user)
    # use ansible
    inventory = params[:inventory]
    logger.info("Installing #{svc} using ansible")
    step %Q/#{svc} service is installed in the project with ansible using:/, table(%{
      | inventory | #{inventory} |
      })
  else
    # use deployer
    deployer_config = params[:deployer_config]
    logger.info("Installing #{svc} using deployer")
    step %Q/#{svc} service is installed in the project using deployer:/, table(%{
      | deployer_config | #{deployer_config}|
      })
  end
end

