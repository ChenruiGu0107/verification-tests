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

Given /^the etcd version is stored in the#{OPT_SYM} clipboard$/ do |cb_name|
  ensure_admin_tagged
  cb_name ||= :etcd_version
  @result = env.master_hosts.first.exec("openshift version")
  etcd_version = @result[:response].match(/etcd (.+)$/)[1]
  raise "Can not retrieve the etcd version" if etcd_version.nil?
  cb[cb_name] = etcd_version
end

# store the default registry scheme type by doing 'oc get dc/docker-registry -o yaml'
Given /^I store the default registry scheme to the#{OPT_SYM} clipboard$/ do |cb_name|
  ensure_admin_tagged
  cb_name ||= :registry_scheme
  @result = admin.cli_exec(:get, resource: 'dc', resource_name: 'docker-registry', o: 'yaml')
  @result[:parsed] = YAML.load(@result[:response])
  cb[cb_name] = @result[:parsed].dig('spec', 'template', 'spec', 'containers')[0].dig('livenessProbe','httpGet','scheme').downcase
end
