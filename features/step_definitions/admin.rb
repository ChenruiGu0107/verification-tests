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

Given /^default registry route is stored in the#{OPT_SYM} clipboard$/ do |cb_name|
  # save the orignial project name
  org_proj_name = project.name
  cb_name ||= :registry_route
  cb[cb_name] = route("docker-registry", service("docker-registry",project('default'))).dns(by: :admin)
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

# pod_info is the user pod, for example.... deployment-example
# the step will do 'docker ps | grep deployment-example' to filter out a target
Given /^the system container id for the#{OPT_QUOTED} pod is stored in the#{OPT_SYM} clipboard$/ do | pod_name, cb_name |
  cb_name ||= :system_pod_container_id
  system_pod_container_id_regexp=/^(.*)\s+.*(ose|origin)-pod:.+\s+"\/pod"/
  pod_name = pod(pod_name).name
  res = host.exec("docker ps | grep #{pod_name}")
  system_pod_container_id = nil
  if res[:success]
    res[:response].split("\n").each do | line |
      system_pod_container_id = system_pod_container_id_regexp.match(line)
      break unless system_pod_container_id.nil?
    end
  else
    raise "Can't find matching docker information for #{pod_name}"
  end
  raise "Can't find containter id for system pod" if system_pod_container_id.nil?
  cb[cb_name] = system_pod_container_id[1].strip
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
