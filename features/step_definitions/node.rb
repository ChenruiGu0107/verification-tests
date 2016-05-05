# nodes related steps

# select a random node from a cluster.
Given /^I select a random node's host$/ do
  @host = env.node_hosts.sample
end

# target_node from World will be used
Given /^I run commands on a node:$/ do |table|
  step %Q/I select a random node's host/
  table.raw.flatten.map do |cmd|
    @result = host.exec(cmd)
  end
end
