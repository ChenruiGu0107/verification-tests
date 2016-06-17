# nodes related steps

# select a random node from a cluster.
Given /^I select a random node's host$/ do
  @host = env.node_hosts.sample
end

Given /^I store the schedulable nodes in the#{OPT_SYM} clipboard$/ do |cbname|
  cbname = 'nodes' unless cbname
  cb[cbname] =
    CucuShift::Node.get_matching(user: admin) { |n, n_hash| n.schedulable? }
end

# @host from World will be used.
Given /^I run commands on the host:$/ do |table|
  ensure_admin_tagged

  raise "You must set a host prior to running this step" unless host

  @result = host.exec(*table.raw.flatten)
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

Given /^the node service is restarted on the host after scenario$/ do
  _host = @host

  @result = _host.exec_admin("systemctl status atomic-openshift-node")
  unless @result[:success] && @result[:response].include?("active (running)")
    raise "something already wrong with node service, failing early"
  end

  teardown_add {
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
