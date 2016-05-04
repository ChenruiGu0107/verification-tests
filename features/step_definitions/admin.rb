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

# returns a hash that maps each service's name as keys
Given /^the openshift service information is stored in the#{OPT_SYM} clipboard$/ do |cb_name|
  ensure_admin_tagged
  _admin = admin

  cb_name = ':svc' unless cb_name
  res = _admin.cli_exec(:get, resource: 'services', output: "yaml")

  if res[:success]
    res[:parsed] = YAML.load res[:response]
  end

  services = {}
  res[:parsed]['items'].map { |r| services[r['metadata']['name']] = r}
  cb[cb_name] = services
end

