# nodes related steps

# IMPORTANT: Creating new [Node] objects is discouraged. Access nodes
#   through `env.nodes` when possible. This is to ensure we use the same
#   objects throughout test execution keeping correct status like config file
#   modification state.

# select a random node from a cluster.
Given /^I select a random node's host$/ do
  ensure_admin_tagged
  nodes = env.nodes.select { |n| n.schedulable? }
  @nodes.reject! {|n| nodes.include? n}
  @nodes.concat nodes.shuffle
  @host = node.host
end

Given /^I store the( schedulable)? nodes in the#{OPT_SYM} clipboard$/ do |schedulable, cbname|
  ensure_admin_tagged
  cbname = 'nodes' unless cbname
  cb[cbname] = env.nodes.select { |n| !schedulable || n.schedulable? }
  @nodes.reject! {|n| cb[cbname].include? n}
  @nodes.concat cb[cbname].shuffle
end

Given /^(I|admin) stores? in the#{OPT_SYM} clipboard the nodes backing pods(?: in project #{QUOTED})? labeled:$/ do |who, cbname, project, labels|
  if who == "admin"
    ensure_admin_tagged
    _user = admin
  else
    _user = user
  end

  pods = CucuShift::Pod.get_labeled(*labels.raw.flatten,
                                       project: project(project),
                                       user: _user)

  node_names = pods.map(&:node_name)

  cbname ||= "nodes"
  cb[cbname] = node_names.map { |n| node(n) }
end

Given /^environment has( at least| at most) (\d+)( schedulable)? nodes?$/ do |cmp, num, schedulable|
  ensure_admin_tagged
  nodes = env.nodes.select { |n| !schedulable || n.schedulable?}
  @nodes.concat (nodes.shuffle - @nodes)

  case cmp
  when /at least/
    raise "nodes are #{nodes.size}" unless nodes.size >= num.to_i
  when /at most/
    raise "nodes are #{nodes.size}" unless nodes.size <= num.to_i
  else
    raise "nodes are #{nodes.size}" unless nodes.size == num.to_i
  end
end

# @host from World will be used.
Given /^I run commands on the host:$/ do |table|
  ensure_admin_tagged

  raise "You must set a host prior to running this step" unless host

  @result = host.exec(*table.raw.flatten)
end

Given /^I run commands on the hosts in the#{OPT_SYM} clipboard:$/ do |cbname, table|
  ensure_admin_tagged
  cbname ||= "hosts"

  unless Array === cb[cbname] && cb[cbname].size > 0 &&
      cb[cbname].all? {|e| CucuShift::Host === e}
    raise "You must set a clipboard prior to running this step"
  end

  results = cb[cbname].map { |h| h.exec(*table.raw.flatten) }
  @result = results.find {|r| !r[:success] }
  @result ||= results[0]
  @result[:response] = results.map { |r| r[:response] }
  @result[:exitstatus] = results.map { |r| r[:exitstatus] }
end

Given /^I run commands on the nodes in the#{OPT_SYM} clipboard:$/ do |cbname, table|
  ensure_admin_tagged
  cbname ||= "nodes"

  tmpcb = rand_str(5, "dns")
  cb[tmpcb] = cb[cbname].map(&:host)

  step "I run commands on the hosts in the :#{tmpcb} clipboard:", table

  cb[tmpcb] = nil
end

# use a specific node in cluster
Given /^I use the #{QUOTED} node$/ do | host |
  @host = node(host).host
end

# restore particular file after scenario
Given /^the #{QUOTED} file is restored on host after scenario$/ do |path|
  _host = @host

  # check path sanity
  if ["'", "\n", "\\"].find {|c| path.include? c}
    raise "please specify path with sane characters"
  end

  # tar the file on host so we can restore with permissions later
  @result = _host.exec_admin("find '#{path}' -maxdepth 0 -type f")
  unless @result[:success] && !@result[:response].empty?
    raise "target path not a file"
  end

  @result = _host.exec_admin("tar --selinux --acls --xattrs -cvPf '#{path}.tar' '#{path}'")
  raise "could not archive target file" unless @result[:success]

  teardown_add {
    @result = _host.exec_admin("tar xvPf '#{path}.tar' && rm -f '#{path}.tar'")
    raise "could not restore #{path} on #{_host.hostname}" unless @result[:success]
  }
end

# restore particular file after scenario
Given /^the #{QUOTED} path is( recursively)? removed on the host after scenario$/ do |path, recurse|
  _host = @host
  path = _host.absolutize(path)

  # check path sanity
  if ["'", "\n", "\\"].find {|c| path.include? c}
    raise "please specify path with sane characters"
  end
  # lame check for not removing root directories
  unless path =~ %r{^/\.?[^/.]+.*/\.?[^/.]+.*}
    raise "path must be at least 2 levels deep"
  end

  teardown_add {
    success = _host.delete(path, r: !!recurse)
    raise "can't remove #{path} on #{_host.hostname}" unless success
  }
end

Given /^the node service is restarted on the host( after scenario)?$/ do |after|
  _host = @host

  @result = _host.exec_admin("systemctl status atomic-openshift-node")
  unless @result[:success] && @result[:response].include?("active (running)")
    raise "something already wrong with node service, failing early"
  end

  _op = proc {
    @result = _host.exec_admin("systemctl restart atomic-openshift-node")
    unless @result[:success]
      raise "could not restart node service on #{_host.hostname}"
    end

    sleep 15 # give service some time to fail
    @result = _host.exec_admin("systemctl status atomic-openshift-node")
    unless @result[:success]
      raise "node service not running on #{_host.hostname}"
    end

    # TODO: do we need `oc get node` and check status ready? We'll need a Node
    #   object in such case. Also question is how long to wait before check,
    #   because openshift is not so fast to react on errors.
  }

  if after
    logger.info "Node service to be restarted after scenario on #{_host.hostname}"
    teardown_add _op
  else
    _op.call
  end
end

Given /^label #{QUOTED} is added to the#{OPT_QUOTED} node$/ do |label, node_name|
  ensure_admin_tagged

  _admin = admin
  _node = node(node_name)

  _opts = {resource: :node, name: _node.name}
  label_now = {key_val: label}
  label_clean = {key_val: label.sub(/^(.*?)=.*$/, "\\1") + "-"}

  @result = _admin.cli_exec(:label, **_opts, **label_now)
  raise "cannot add label to node" unless @result[:success]

  teardown_add {
    @result = _admin.cli_exec(:label, **_opts, **label_clean)
    unless @result[:success]
      raise "cannot remove label #{label} from node #{_node.name}"
    end
  }
end

Given /^the#{OPT_QUOTED} node service is verified$/ do |node_name|
  ensure_admin_tagged

  _node = node(node_name)
  _host = _node.host
  _pod_name = "hostname-pod-" + rand_str(5, :dns)
  _pod_obj = <<-eof
    {
      "apiVersion":"v1",
      "kind": "Pod",
      "metadata": {
        "name": "#{_pod_name}",
        "labels": {
          "puspose": "testing-node-validity",
          "name": "hostname-pod"
        }
      },
      "spec": {
        "containers": [{
          "name": "hostname-pod",
          "image": "openshift/hello-openshift",
          "ports": [{
            "containerPort": 8080,
            "protocol": "TCP"
          }]
        }],
        "nodeName" : "#{_node.name}"
      }
    }
  eof

  svc_verify = proc {
    # node service running
    @result = _host.exec_admin('systemctl status atomic-openshift-node')
    unless @result[:success] || @result[:response].include?("active (running)")
      raise "node service not running, see log"
    end
    # pod can be scheduled on node
    step 'I have a project'
    @result = admin.cli_exec(:create, f: "-", _stdin: _pod_obj, n: project.name)
    raise "cannot create verification pod, see log" unless @result[:success]
    step %Q{the pod named "#{_pod_name}" becomes ready}
    unless _node.name == pod(_pod_name).node_name(user: admin, quiet: true)
      raise "verification node not running on correct node"
    end
    ## thought it would be good enough check but we can switch to creating
    #    a route and then accessing it in case this proves not stable enough
    @result = _host.exec("curl -sS #{pod.ip(user: user)}:8080")
    unless @result[:success] || @result[:response].include?("Hello OpenShift!")
      raise "verification pod doesn't serve properly, see log"
    end
    @result = pod(_pod_name).delete(by: user, grace_period: 0)
    raise "can't delete verification pod" unless @result[:success]
  }

  svc_verify.call
  teardown_add svc_verify
end

Given /^the host is rebooted and I wait it(?: up to (\d+) seconds)? to become available$/ do |timeout|
  timeout = timeout ? Integer(timeout) : 300
  @host.reboot_checked(timeout: timeout)
end

Given /^the#{OPT_QUOTED} node labels are restored after scenario$/ do |node_name|
  ensure_admin_tagged
  _node = node(node_name)
  _node_labels = _node.labels
  _admin = admin

  logger.info "Node labels are stored in clipboard"

  teardown_add {
    labels = _node_labels.map {|k,v| [:key_val, k + "=" + v] }
    opts = [ [:resource, 'node'], [:name, _node.name], [:overwrite, true], *labels ]
    _admin.cli_exec(:label, opts)
  }
end

Given /^config of all( schedulable)? nodes is merged with the following hash:$/ do |schedulable, yaml_string|
  ensure_destructive_tagged

  yaml_hash = YAML.load(yaml_string)
  nodes = env.nodes.select { |n| !schedulable || n.schedulable? }
  services = nodes.map(&:service)

  services.each { |service|
    service_config = service.config
    if service_config.exists?
      config_hash = service_config.as_hash()
      CucuShift::Collections.deep_merge!(config_hash, yaml_hash)
      config = config_hash.to_yaml
      logger.info config
      service_config.backup()
      @result = service_config.update(config)

      teardown_add {
        service_config.restore()
      }
    else
      raise "The node config file does not exists on this node!"
    end
  }
end

Given /^node#{OPT_QUOTED} config is merged with the following hash:$/ do |node_name, yaml_string|
  ensure_destructive_tagged
  _node = node(node_name)

  service_config = _node.service.config
  if service_config.exists?
    config_hash = service_config.as_hash()
    CucuShift::Collections.deep_merge!(config_hash, yaml_hash)
    config = config_hash.to_yaml
    logger.info config
    service_config.backup()
    @result = service_config.update(config)

    teardown_add {
      service_config.restore()
    }
  else
    raise "The node config file does not exists on this node!"
  end

end

Given /^all nodes config is restored$/ do
  ensure_admin_tagged
  env.nodes.map(&:service).each { |service|
    @result = service.config.restore()
  }
end


Given /^node#{OPT_QUOTED} config is restored from backup$/ do |node_name|
  ensure_admin_tagged
  @result = node(node_name).service.config.restore()
end

Given /^the value with path #{QUOTED} in node config is stored into the#{OPT_SYM} clipboard$/ do |path, cb_name|
  ensure_admin_tagged
  config_hash = node.service.config.as_hash()
  cb_name ||= "config_value"
  cb[cb_name] = eval "config_hash#{path}"
end

Given /^the node service is restarted on all( schedulable)? nodes$/ do |schedulable|
  ensure_destructive_tagged
  nodes = env.nodes.select { |n| !schedulable || n.schedulable? }
  services = nodes.map(&:service)

  services.each { |service|
    if service.config.exists?
      service.restart_all(raise: true)
    else
      raise "The node config file does not exists on this node!"
    end
  }
end

Given /^the node service is restarted on node#{OPT_QUOTED}$/ do |node_name|
  ensure_destructive_tagged
  node(node_name).service.restart_all(raise: true)
end

Given /^I try to restart the node service on all( schedulable)? nodes$/ do |schedulable|
  ensure_destructive_tagged
  results = []
  nodes = env.nodes.select { |n| !schedulable || n.schedulable? }
  services = nodes.map(&:service)

  services.each { |service|
    if service.config.exists?
      results.push(@result = service.restart_all)
    else
      raise "The node config file does not exists on this node!"
    end
  }

  @result = CucuShift::ResultHash.aggregate_results(results)
end

Given /^I try to restart the node service on node#{OPT_QUOTED}$/ do |node_name|
  ensure_destructive_tagged
  @results = node(node_name).service.restart_all
end
