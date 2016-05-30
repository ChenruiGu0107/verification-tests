# store here steps that create test services within OpenShift test env

Given /^I have a NFS service in the(?: "([^ ]+?)")? project$/ do |project_name|
  # at the moment I believe only one such PV we can have without interference
  #ensure_destructive_tagged

  project(project_name)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  # in this policy we use policy name to be #ACCOUNT# name but with bad
  #   characters removed
  step %Q{I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_super_template.yaml"}
  policy = YAML.load(@result[:response])
  path = @result[:abs_path]
  policy["metadata"]["name"] = "super-" + user.name.gsub(/[@]/,"-")
  policy["users"] = [user.name]
  policy["groups"] = ["system:serviceaccounts:" + project.name]
  File.write(path, policy.to_yaml)

  # now we seem to need setting policy on user, not project
  step %Q@the following scc policy is created: #{path}@

  @result = user.cli_exec(:create, n: project.name, f: 'https://github.com/openshift-qe/v3-testfiles/raw/master/storage/nfs/nfs-server.yaml')

  raise "could not create NFS Server service" unless @result[:success]

  step 'I wait for the "nfs-service" service to become ready'

  # now you have NFS running, to get IP, call `service.ip` or
  #   `service("nfs-service").ip`
end

Given /^I have an ssh-git service in the(?: "([^ ]+?)")? project$/ do |project_name|
  project(project_name, switch: true)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  @result = user.cli_exec(:run, name: "git-server", image: "aosqe/ssh-git-server-openshift")
  raise "cannot run the ssh-git-server pod" unless @result[:success]

  @result = user.cli_exec(:set_probe, resource: "dc/git-server", readiness: true, open_tcp: "2022")
  raise "cannot set dc/git-server probe" unless @result[:success]

  @result = user.cli_exec(:expose, resource: "dc", resource_name: "git-server", port: "22", target_port: "2022")
  raise "cannot create git-server service" unless @result[:success]

  # wait to become available
  @result = CucuShift::Pod.wait_for_labeled("deployment-config=git-server",
                                            "run=git-server",
                                            count: 1,
                                            user: user,
                                            project: project,
                                            seconds: 300) do |pod, pod_hash|
    pod_hash.dig("spec", "containers", 0, "readinessProbe", "tcpSocket") &&
      pod.ready?(user: user, cached: true)[:success]
  end
  raise "git-server pod did not become ready" unless @result[:success]

  # Setup SSH key
  cache_pods *@result[:matching]
  ssh_key = CucuShift::SSH::Helper.gen_rsa_key
  @result = pod.exec(
    "bash", "-c",
    "echo '#{ssh_key.to_pub_key_string}' >> /home/git/.ssh/authorized_keys",
    as: user
  )
  raise "cannot add public key to ssh-git server pod" unless @result[:success]

  # to get string private key use cb.ssh_private_key.to_pem in scenario
  cb.ssh_private_key = ssh_key
  # set some clipboards for easy access
  cb.git_svc = "git-server"
  cb.git_pod_ip_port = "#{pod.ip(user: user)}:2022"
  cb.git_pod = pod
  cb.git_svc_ip = "#{service("git-server").ip(user: user)}"
  # put sample repo in clipboard for easy use
  cb.git_repo_pod = "ssh://git@#{pod.ip(user: user)}:2022/repos/sample.git"
  cb.git_repo_ip = "git@#{service("git-server").ip(user: user)}:sample.git"
  cb.git_repo = "git@git-server:sample.git"
end

Given /^I have an http-git service in the(?: "([^ ]+?)")? project$/ do |project_name|
  project(project_name, switch: true)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  @result = user.cli_exec(:create, f: "https://raw.githubusercontent.com/openshift/origin/master/examples/gitserver/gitserver-ephemeral.yaml")
  # @result = user.cli_exec(:run, name: "gitserver", image: "openshift/origin-gitserver", env: 'GIT_HOME=/var/lib/git')
  raise "could not create the http-git-server" unless @result[:success]

  @result = user.cli_exec(:policy_add_role_to_user, role: "edit", serviceaccount: "git")
  raise "error with git service account policy" unless @result[:success]

  @result = service("git").wait_till_ready(user, 300)
  raise "git service did not become ready" unless @result[:success]

  ## we assume to get git pod in the result above, fail otherwise
  cache_pods *@result[:matching]
  unless pod.name.start_with? "git-server-"
    raise("looks like underlying implementation changed and service ready" +
      "status does not return matching pods anymore; report CucuShift bug")
  end

  # set some clipboards
  cb.git_pod = pod
  cb.git_route = route("git").dns(by: user)
  cb.git_svc = "git"
  cb.git_svc_ip = "#{service("git").ip(user: user)}"
  cb.git_pod_ip_port = "#{pod.ip(user: user)}:8080"
end

# pod-for-ping is a pod that has curl on it
Given /^I have a pod-for-ping in the(?: "([^ ]+?)")? project$/ do |project_name|
  project(project_name, switch: true)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  @result = user.cli_exec(:create, f: "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json")
  raise "could not create a pod-for-ping" unless @result[:success]

  @result = pod("hello-pod").wait_till_ready(user, 300)
  raise "pod-for-ping did not become ready in time" unless @result[:success]
end

Given /^I have a Gluster service in the(?: "([^ ]+?)")? project$/ do |project_name|
  ensure_admin_tagged

  project(project_name)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  @result = admin.cli_exec(:create, n: project.name, f: 'https://raw.githubusercontent.com/openshift-qe/docker-gluster/master/glusterd.json')
  raise "could not create glusterd pod" unless @result[:success]

  @result = user.cli_exec(:create, n: project.name, f: 'https://raw.githubusercontent.com/openshift-qe/docker-gluster/master/service.json')
  raise "could not create glusterd service" unless @result[:success]

  step 'I wait for the "glusterd" service to become ready'

  # now you have Gluster running, to get IP, call `service.ip` or
  #   `service("glusterd").ip`
end

Given /^I have a Ceph pod in the(?: "([^ ]+?)")? project$/ do |project_name|
  ensure_admin_tagged

  project(project_name)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  @result = admin.cli_exec(:create, n: project.name, f: 'https://raw.githubusercontent.com/openshift-qe/docker-rbd/master/rbd-server.json')
  raise "could not create Ceph pod" unless @result[:success]

  @result = user.cli_exec(:create, n: project.name, f: 'https://raw.githubusercontent.com/openshift-qe/docker-rbd/master/rbd-secret.yaml')
  raise "could not create Ceph secret" unless @result[:success]

  step 'the pod named "rbd-server" becomes ready'

  # now you have Ceph running, to get IP, call `pod.ip` or
  #   `pod("rbd-server").ip(user: user)`
end
