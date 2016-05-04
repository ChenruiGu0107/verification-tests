# nodes related steps

# select a random node from a cluster...if
Given /^I select a node$/ do
  if env.node_hosts.count > 1
    index = rand(0..env.node_host.count-1)
  else
    index = 0
  end
  # update the world variable
  @target_node = env.node_hosts[index]
end

# target_node from World will be used
Given /^I run commands on a node:$/ do |table|
  step %Q/I select a node/
  table.raw.flatten.map do |cmd|
    @result = target_node.exec(cmd)
  end
end
