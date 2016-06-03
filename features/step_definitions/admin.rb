# admin related steps

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

Given /^default registry service ip is stored in the#{OPT_SYM} clipboard$/ do |cb_name|
  # save the orignial project name
  org_proj_name = project.name
  cb_name ||= :registry_ip
  cb[cb_name] = service("docker-registry", project('default')).url(user: :admin)
  project(org_proj_name)
end
