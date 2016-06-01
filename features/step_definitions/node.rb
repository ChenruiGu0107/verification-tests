# nodes related steps

# select a random node from a cluster.
Given /^I select a random node's host$/ do
  @host = env.node_hosts.sample
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
