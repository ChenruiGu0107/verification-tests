# helper step for logging and metrics scenarios

# since the logging and metrics module can be deployed and used in any namespace, this step is used to determine
# under what namespace the logging/metrics module is deployed under by getting all of the projects as admin and
And /^I save the (logging|metrics) project name to the#{OPT_SYM} clipboard$/ do |svc_type, clipboard_name|
  ensure_admin_tagged

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
    raise ("Found #{found_proj.count} logging services installed in the cluster, expected 1")
  else
    cb[cb_name] = found_proj[0].name
  end
end

Given /^there should be (\d+) (logging|metrics) services? installed/ do |count, svc_type|
  ensure_admin_tagged

  if svc_type == 'logging'
    expected_rc_name = "logging-kibana-1"
  else
    expected_rc_name = "hawkular-metrics"
  end

  found_proj = CucuShift::Project.get_matching(user: admin) { |project, project_hash|
    rc(expected_rc_name, project).exists?(user: admin, quiet: true)
  }
  raise ("Found #{found_proj.count} logging services installed in the cluster, expected #{count}") if found_proj.count != Integer(count)
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
# NOTE: if we agree to use a fixed name for the first part of the metrics URL, then we don't need admin access privilege to run this step.
When /^I perform the (GET|POST) metrics rest request with:$/ do | op_type, table |
  if !env.opts[:admin_cli]
    # for Online/STG/INT, we just get the URL from env
    cb['metrics'] = env.metrics_console_url
  else
    unless cb[:metrics]
      step %Q/I store default router subdomain in the :metrics clipboard/
      cb[:metrics] = 'https://hawkular-metrics.' + cb[:metrics] + '/hawkular'
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
    datastore_url = metrics_url + '/datastore'
    file_name = opts[:payload]
    if %w(http https).include? URI.parse(opts[:payload]).scheme
      # user given a http source as a parameter
      step %Q/I download a file from "#{opts[:payload]}"/
      file_name = @result[:file_name]
    end
    https_opts[:payload] = File.read(expand_path(file_name))
    url = datastore_url + "/raw"
  else
    url = metrics_url
  end

  @result = CucuShift::Http.request(url: url, **https_opts, method: op_type)
  @result[:parsed] = YAML.load(@result[:response])
end

# unless project name is given we assume all logging pods are installed under the current project
Given /^all logging pods are running in the#{OPT_QUOTED} project$/ do | proj_name |
  proj_name = project.name if proj_name.nil?
  org_proj_name = project.name
  org_user = user
  if proj_name == 'logging'
    ensure_admin_tagged
    step %Q/I switch to cluster admin pseudo user/
    project(proj_name)
  end
  begin
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=curator     |
      | logging-infra=curator |
      | provider=openshift    |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=es                |
      | logging-infra=elasticsearch |
      | provider=openshift          |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=fluentd     |
      | logging-infra=fluentd |
      | provider=openshift    |
      })
    step %Q/all existing pods are ready with labels:/, table(%{
      | component=kibana     |
      | logging-infra=kibana |
      | provider=openshift   |
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

  ensure_admin_tagged
  step %Q/I switch to cluster admin pseudo user/
  project(target_proj)
  begin
    step %Q/all existing pods are ready with labels:/, table(%{
      | metrics-infra=hawkular-cassandra |
      | type=hawkular-cassandra          |
      })

    step %Q/all existing pods are ready with labels:/, table(%{
      | metrics-infra=hawkular-metrics |
      | name=hawkular-metrics          |
      })

    step %Q/all existing pods are ready with labels:/, table(%{
      | metrics-infra=heapster |
      | name=heapster          |
      })
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
  ensure_admin_tagged
  if op == 'installed'
    step %Q/there should be 0 #{svc_type} service installed/
  end

  # check tht logging/metric is not installed in the target cluster already.
  ansible_opts = opts_array_to_hash(table.raw)
  target_proj = proj.nil? ? project.name : proj
  if svc_type == 'metrics' and target_proj != 'openshift-infra'
    raise ("Metrics must be installed into the 'openshift-infra")
  end

  logger.info("Performing operation '#{op[0..-3]}' to #{target_proj}...")

  step %Q/I register clean-up steps:/, table(%{
    | I remove #{svc_type} service installed in the "#{target_proj}" project using ansible |
    })

  raise "Must provide inventory option!" unless ansible_opts.keys.include? 'inventory'.to_sym

  step %Q/I store default router subdomain in the :subdomain clipboard/
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

  # to save time we are going to check if the base-ansible-pod already exists
  # use admin user to get the information so we don't need to swtich user.
  unless pod("base-ansible-pod").exists?(user: admin)
    step %Q/I run the :create client command with:/, table(%{
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/base_ansible_pod.json |
    })
    step %Q/the step should succeed/
    step %Q/the pod named "base-ansible-pod" becomes ready/
    # fix uid to match the correct value
    cb.sed_cmd = 'echo -e ",s/1234321/`id -u`/g\\012 w" | ed -s /etc/passwd'
    step %Q/I execute on the pod:/, table(%{
      | bash              |
      | -c                |
      | <%= cb.sed_cmd %> |
    })
  end
  step %Q/I run the :rsync client command with:/, table(%{
    | source      | <%= localhost.absolutize("tmp") %> |
    | destination | base-ansible-pod:/tmp              |
    | loglevel    | 5                                  |
    })
  # checkout the openshift-anisble.  XXX: note, master has issues will need to
  # checkout from 1.5 for the time being
  if pod("base-ansible-pod").exists?(user: admin)
    step %Q/I execute on the pod:/, table(%{
      | bash                                                                                                                 |
      | -c                                                                                                                   |
      | cd /tmp/tmp/ && rm -rf openshift-ansible && git clone https://github.com/openshift/openshift-ansible/ |
      })
    step %Q/the step should succeed/
  end

  if svc_type == 'logging'
    ansible_template_path = "openshift-ansible/playbooks/byo/openshift-cluster/openshift-logging.yml"
  else
    ansible_template_path = "openshift-ansible/playbooks/common/openshift-cluster/openshift_metrics.yml"
  end
  step %Q/I execute on the pod:/, table(%{
    | bash                                                                                                |
    | -c                                                                                                  |
    | cd /tmp/tmp && ansible-playbook -i /tmp/<%= "#{new_path}" %> -vvv <%= "#{ansible_template_path}" %> |
    })
  step %Q/the step should succeed/

  # the openshift-ansible playbook restarts master at the end, we need to run the following to just check the master is ready.
  step %Q/I wait for the steps to pass:/,
    """
      And I store master major version in the :tmp clipboard
    """
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
end
