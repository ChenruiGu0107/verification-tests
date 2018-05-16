# nodes related steps

# IMPORTANT: Creating new [Node] objects is discouraged. Access nodes
#   through `env.nodes` when possible. This is to ensure we use the same
#   objects throughout test execution keeping correct status like config file
#   modification state.

# select a random node from a cluster.
Given /^I select a random node's host$/ do
  ensure_admin_tagged
  nodes = env.nodes.select { |n| n.schedulable? }
  cache_resources *nodes.shuffle
  @host = node.host
end

Given /^I store the( schedulable| ready and schedulable)? nodes in the#{OPT_SYM} clipboard$/ do |state, cbname|
  ensure_admin_tagged
  cbname = 'nodes' unless cbname

  if !state
    cb[cbname] = env.nodes.dup
  elsif state.strip == "schedulable"
    cb[cbname] = env.nodes.select { |n| n.schedulable? }
  else
    cb[cbname] = env.nodes.select { |n| n.ready? && n.schedulable? }
  end

  cache_resources *cb[cbname].shuffle
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
  cache_resources *nodes.shuffle

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
Given /^I run( background)? commands on the host:$/ do |bg, table|
  ensure_admin_tagged

  raise "You must set a host prior to running this step" unless host
  @result = host.exec(*table.raw.flatten, background: !!bg)
end

Given /^I run commands on the host after scenario:$/ do |table|
  _host = @host
  _command = *table.raw.flatten
  logger.info "Will run the command #{_command} after scenario on #{_host.hostname}"
  teardown_add {
    @result = _host.exec_admin(_command)
    unless @result[:success]
      raise "could not execute comands #{_command} on #{_host.hostname}"
    end
  }
end

Given /^I run( background)? commands on the hosts in the#{OPT_SYM} clipboard:$/ do |bg, cbname, table|
  ensure_admin_tagged
  cbname ||= "hosts"

  unless Array === cb[cbname] && cb[cbname].size > 0 &&
      cb[cbname].all? {|e| CucuShift::Host === e}
    raise "You must set a clipboard prior to running this step"
  end

  results = cb[cbname].map { |h| h.exec(*table.raw.flatten, background: !!bg) }
  @result = results.find {|r| !r[:success] }
  @result ||= results[0]
  @result[:channel_object] = results.map { |r| r[:channel_object] }
  @result[:response] = results.map { |r| r[:response] }
  @result[:exitstatus] = results.map { |r| r[:exitstatus] }
end

Given /^I run( background)? commands on the nodes in the#{OPT_SYM} clipboard:$/ do |bg, cbname, table|
  ensure_admin_tagged
  cbname ||= "nodes"

  tmpcb = rand_str(5, "dns")
  cb[tmpcb] = cb[cbname].map(&:host)

  step "I run#{bg} commands on the hosts in the :#{tmpcb} clipboard:", table

  cb[tmpcb] = nil
end

# use a specific node in cluster
Given /^I use the #{QUOTED} node$/ do | host |
  @host = node(host).host
end

# restore particular file after scenario; if missing, then removes it
Given /^the #{QUOTED} file is restored on host after scenario$/ do |path|
  _host = @host

  # check path sanity
  if ["'", "\n", "\\"].find {|c| path.include? c}
    raise "please specify path with sane characters"
  end

  # tar the file on host so we can restore with permissions later
  @result = _host.exec_admin("find '#{path}' -maxdepth 0 -type f")
  if @result[:success]
    if @result[:response].empty?
      raise "target path not a file"
    else
      # file exist
      @result = _host.exec_admin("tar --selinux --acls --xattrs -cvPf '#{path}.tar' '#{path}'")
      raise "could not archive target file" unless @result[:success]
      _restore_command = "tar xvPf '#{path}.tar' && rm -f '#{path}.tar'"
    end
  else
    # file does not exist
    _restore_command = "rm -f '#{path}'"
  end


  teardown_add {
    @result = _host.exec_admin(_restore_command)
    unless @result[:success]
      raise "could not restore #{path} on #{_host.hostname}"
    end
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
  ensure_destructive_tagged
  _node = env.nodes.find { |n| n.host.hostname == @host.hostname }

  unless _node
    raise "cannot find node for host #{@host.hostname}"
  end

  _op = proc {
    _node.service.restart(raise: true)
  }

  if after
    logger.info "Node service will be restarted after scenario on #{_node.name}"
    teardown_add _op
  else
    _op.call
  end
end

# the step does not register clean-ups because these usually are properly
#   ordered in scenario itself, we don't want automatic extra restarts
Given /^the#{OPT_QUOTED} node service is stopped$/ do |node_name|
  ensure_destructive_tagged
  node(node_name).service.stop(raise: true)
end

Given /^label #{QUOTED} is added to the#{OPT_QUOTED} node$/ do |label, node_name|
  ensure_admin_tagged

  _admin = admin
  _node = node(node_name)

  _opts = {resource: :node, name: _node.name, overwrite: true}
  label_now = {key_val: label}
  label_key = label.sub(/^(.*?)=.*$/, "\\1")
  label_clean = {key_val:  label_key + "-"}

  if _node.labels.has_key?(label_key)
    step %Q/the "#{_node.name}" node labels are restored after scenario/
  else
    teardown_add {
      @result = _admin.cli_exec(:label, **_opts, **label_clean)
      unless @result[:success]
        raise "cannot remove label #{label} from node #{_node.name}"
      end
    }
  end

  @result = _admin.cli_exec(:label, **_opts, **label_now)
  raise "cannot add label to node" unless @result[:success]

end

Given /^the#{OPT_QUOTED} node service is verified$/ do |node_name|
  ensure_admin_tagged

  _node = node(node_name)
  _host = _node.host

  # to reduce test execution time we stop creating a pod to verify node
  # if this turns out to be a problem, before reenable, make sure we
  # use a project without node selector. Otherwise things break on 3.9+
  # see OPENSHIFTQ-12320
  #
  #_pod_name = "hostname-pod-" + rand_str(5, :dns)
  #_pod_obj = <<-eof
  #  {
  #    "apiVersion":"v1",
  #    "kind": "Pod",
  #    "metadata": {
  #      "name": "#{_pod_name}",
  #      "labels": {
  #        "puspose": "testing-node-validity",
  #        "name": "hostname-pod"
  #      }
  #    },
  #    "spec": {
  #      "containers": [{
  #        "name": "hostname-pod",
  #        "image": "openshift/hello-openshift",
  #        "ports": [{
  #          "containerPort": 8080,
  #          "protocol": "TCP"
  #        }]
  #      }],
  #      "nodeName" : "#{_node.name}"
  #    }
  #  }
  #eof

  svc_verify = proc {
    # node service running
    @result = _host.exec_admin('systemctl status atomic-openshift-node')
    unless @result[:success] || @result[:response].include?("active (running)")
      raise "node service not running, see log"
    end
    # pod can be scheduled on node
    #step 'I have a project'
    #@result = admin.cli_exec(:create, f: "-", _stdin: _pod_obj, n: project.name)
    #raise "cannot create verification pod, see log" unless @result[:success]
    #step %Q{the pod named "#{_pod_name}" becomes ready}
    #unless _node.name == pod(_pod_name).node_name(user: admin, quiet: true)
    #  raise "verification node not running on correct node"
    #end
    ## thought it would be good enough check but we can switch to creating
    #    a route and then accessing it in case this proves not stable enough
    #@result = _host.exec("curl -sS #{pod.ip(user: user)}:8080")
    #unless @result[:success] || @result[:response].include?("Hello OpenShift!")
    #  raise "verification pod doesn't serve properly, see log"
    #end
    #@result = pod(_pod_name).delete(by: user, grace_period: 0)
    #raise "can't delete verification pod" unless @result[:success]
  }

  svc_verify.call
  teardown_add svc_verify
end

Given /^the host is rebooted and I wait it(?: up to (\d+) seconds)? to become available$/ do |timeout|
  timeout = timeout ? Integer(timeout) : 300
  @host.reboot_checked(timeout: timeout)
end

Given /^the#{OPT_QUOTED} node labels are restored after scenario$/ do |node_name|
  ensure_destructive_tagged
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

  service_config = node(node_name).service.config
  if service_config.exists?
    config_hash = service_config.as_hash()
    CucuShift::Collections.deep_merge!(config_hash, YAML.load(yaml_string))
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
      service.restart(raise: true)
    else
      raise "The node config file does not exists on this node!"
    end
  }
end

Given /^the#{OPT_QUOTED} node service is restarted$/ do |node_name|
  ensure_destructive_tagged
  node(node_name).service.restart(raise: true)
end

Given /^I try to restart the node service on all( schedulable)? nodes$/ do |schedulable|
  ensure_destructive_tagged
  results = []
  nodes = env.nodes.select { |n| !schedulable || n.schedulable? }
  services = nodes.map(&:service)

  services.each { |service|
    if service.config.exists?
      results.push(@result = service.restart)
    else
      raise "The node config file does not exists on this node!"
    end
  }

  @result = CucuShift::ResultHash.aggregate_results(results)
end

Given /^I try to restart the node service on node#{OPT_QUOTED}$/ do |node_name|
  ensure_destructive_tagged
  @result = node(node_name).service.restart
end

Given /^I have (?:(at least ))?(\d+) nodes?$/ do |quantifier, nodes|
  num_of_nodes = nodes.to_i
  nodes_found = env.nodes.count
  @result = {}
  if quantifier
    @result[:success] = nodes_found >= num_of_nodes
  else
    @result[:success] = nodes_found == num_of_nodes
  end
  raise "number of nodes '#{nodes_found}' in the setup does not meet the criteria of #{quantifier}#{nodes} nodes" unless @result[:success]
end

# use oc rsync to copy files from node to a pod
# required table params are src_dir and dst_dir
Given /^I rsync files from node named #{QUOTED} to pod named #{QUOTED} using parameters:$/ do | node_name, pod_name, table |
  ensure_admin_tagged
  opts = opts_array_to_hash(table.raw)
  raise "Not all requried parameters given, expected #{opts.keys}" if opts.keys.sort != [:dst_dir, :src_dir]
  step %Q/I run commands on the host:/, table(%{
    | oc rsync "#{opts[:src_dir]}" "#{opts[:dst_dir]}" --namespace "#{project.name}" |
  })
  step %Q/the step should succeed/
end

Given /^the taints of the nodes in the#{OPT_SYM} clipboard are restored after scenario$/ do |nodecb|
  ensure_destructive_tagged

  nodecb ||= :nodes
  _admin = admin
  _nodes = cb[nodecb].dup
  _original_taints = _nodes.map { |n| [n,n.taints] }.to_h

  teardown_add {
    CucuShift::Resource.bulk_update(user: admin, resources: _nodes)
    _current_taints = _nodes.map { |n| [n,n.taints] }.to_h
    _diff_taints = _nodes.map do |node|
      [node, _current_taints[node] - _original_taints[node]]
    end.reject {|node, diff_taints| diff_taints.empty?}

    _taint_updates = _diff_taints.map do |node, diff|
      [
        node,
        diff.map do |taint|
          if original = _original_taints[node].find{|t| t.conflicts?(taint)}
            original.cmdline_string
          else
            taint.delete_str
          end
        end
      ]
    end

    _taint_groups = _taint_updates.group_by {|node, updates| updates}.map(&:last)
    _taint_groups.each do |group|
      @result = _admin.cli_exec(
        :oadm_taint_nodes,
        node_name: group.map(&:first).map(&:name),
        overwrite: true,
        key_val: group[0][1]
      )
      raise("failed to revert tainted nodes, see logs") unless @result[:success]
    end

    # verify if the restoration process was succesfull
    CucuShift::Resource.bulk_update(user: admin, resources: _nodes)
    _current_taints = _nodes.map { |n| [n,n.taints] }.to_h
    _diff_taints = _nodes.map do |node|
      [node, _current_taints[node] - _original_taints[node]]
    end.reject {|node, diff_taints| diff_taints.empty?}
    unless _diff_taints.empty?
      raise "nodes didn't have taints properly restored: " \
        "#{_diff_taints.map(&:first).map(&:name).join(", ")}"
    end
  }
end

Given /^I run commands on all nodes:$/ do |table|
  ensure_admin_tagged
  @result = CucuShift::ResultHash.aggregate_results env.node_hosts.map { |host|
    host.exec_admin(table.raw.flatten)
  }
end

Given /^node schedulable status should be restored after scenario$/ do
  ensure_destructive_tagged
  _org_schedulable = env.nodes.map {|n| [n, n.schedulable?]}
  _admin = admin
  teardown_add {
    _org_schedulable.each do |node, schedulable|
      opts = { :node_name =>  node.name, :schedulable => schedulable  }
      _admin.cli_exec(:oadm_manage_node, opts)
    end
  } 
end
