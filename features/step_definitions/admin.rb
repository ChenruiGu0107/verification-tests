# admin related steps

Given /^I have (?:(at least ))?(\d+) nodes?$/ do |quantifier, nodes|
  #ensure_admin_tagged
  num_of_nodes = nodes.to_i
  @nodes = env.nodes
  if quantifier
    res = @nodes.count >= num_of_nodes
  else
    res = @nodes.count == num_of_nodes
  end
  raise "number of nodes '#{@nodes.count}' in the setup does not meet the criteria of #{quantifier} #{nodes} nodes"
  @result = {}
  @result[:success] = res
end
