# nodes related steps

# select a random node from a cluster.
Given /^I select a random node's host$/ do
  @host = env.node_hosts.sample
end

# @host from World will be used.
Given /^I run commands on the host:$/ do |table|
  raise "You must set a host prior to running this step" if host.nil?
  table.raw.flatten.map do |cmd|
    @result = host.exec(cmd)
  end
end
