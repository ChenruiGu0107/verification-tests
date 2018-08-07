
Given /^I deploy local storage provisioner(?: with "([^ ]+?)" version)?$/ do |img_version|
  ensure_admin_tagged
  ensure_destructive_tagged

  config_hash = env.master_services[0].config.as_hash()
  imgformat = config_hash["imageConfig"]["format"]
  img_registry = imgformat.split("\/")[0]
  ose_version = env.get_version(user:admin)
  img_version = "v#{ose_version[0]}" unless img_version
  namespace="local-storage"
  serviceaccount="local-storage-admin"
  configmap="local-volume-config"
  template="local-storage-provisioner"
  image="#{img_registry}/openshift3/local-storage-provisioner:#{img_version}"
  path ||="/mnt/local-storage"

  project(namespace)
  if project.exists?(user: admin)
    raise "project #{namespace} exists already."
  end

  ns_cmd = "oc adm new-project #{namespace} --node-selector=''"
  @result = env.master_hosts.first.exec(ns_cmd)
  step %Q/the step should succeed/

  env.hosts.each do |host|
    setup_commands = [
      "mkdir -p #{path}/fast/vol1",
      "mount -t tmpfs fvol1 #{path}/fast/vol1",
      "mkdir -p #{path}/fast/vol2",
      "mount -t tmpfs fvol2 #{path}/fast/vol2",
      "mkdir -p #{path}/slow/vol1",
      "mount -t tmpfs svol1 #{path}/slow/vol1",
      "mkdir -p #{path}/slow/vol2",
      "mount -t tmpfs svol2 #{path}/slow/vol2",
      "mkdir -p #{path}/fast/dir1",
      "chcon -R unconfined_u:object_r:svirt_sandbox_file_t:s0 #{path}"
    ]
    res = host.exec_admin(*setup_commands)
    raise "error preaparing subdirs for local storage provisioner" unless res[:success]
  end

  step %Q{I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/localvolume/configmap.yaml"}
  cfm = YAML.load(@result[:response])
  filepath = @result[:abs_path]
  scmap = cfm["data"]["storageClassMap"].gsub("/mnt/local-storage", path)
  cfm["data"]["storageClassMap"] = scmap
  File.write(filepath, cfm.to_yaml)
  res = admin.cli_exec(:create, n: namespace, f: filepath)
  raise "error creating configmap for local storage provisioner" unless res[:success]

  sa = service_account(serviceaccount)
  @result =  sa.create(by: admin)
  step %Q/the step should succeed/

  _opts = {scc: "privileged", user_name: "system:serviceaccount:local-storage:#{serviceaccount}"}
  add_command = :oadm_policy_add_scc_to_user
  @result = admin.cli_exec(add_command, **_opts)
  step %Q/the step should succeed/

  step %Q/I run the :create admin command with:/, table(%{
      | f | https://raw.githubusercontent.com/openshift/origin/release-3.9/examples/storage-examples/local-examples/local-storage-provisioner-template.yaml |
      | n | #{namespace}                                                                                                                                    |
  })
  step %Q/the step should succeed/

  step 'admin ensures "local-storage:provisioner-node-binding" clusterrolebinding is deleted'
  step 'admin ensures "local-storage:provisioner-pv-binding" clusterrolebinding is deleted'
  step %Q/I run the :new_app admin command with:/, table(%{
      | param    | CONFIGMAP=#{configmap}            |
      | param    | SERVICE_ACCOUNT=#{serviceaccount} |
      | param    | NAMESPACE=#{namespace}            |
      | param    | PROVISIONER_IMAGE=#{image}        |
      | template | #{template}                       |
      | n        | #{namespace}                      |
  })
  step %Q/the step should succeed/

  nodes = env.nodes.select { |n| n.schedulable? }
  step %Q/I switch to cluster admin pseudo user/
  step %/#{nodes.size} pods become ready with labels:/, table(%{
      | app=local-volume-provisioner|
  })

  pv_count = 0
  CucuShift::PersistentVolume.list(user: admin).each { |pv|
    if pv.name.start_with?("local-pv-") && pv.local_path&.start_with?(path)
      pv_count += 1
    end
  }

  raise "error creating PVs with local storage provisioner" unless (pv_count == nodes.size * 4)
end
