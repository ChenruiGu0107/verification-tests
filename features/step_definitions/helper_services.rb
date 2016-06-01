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
  # add the private key to git server pod ,so we can make this pod also as a git client pod to pull/push code to the repo
  @result = pod.exec(
    "bash", "-c",
    "echo '#{ssh_key.to_pem}' >> /home/git/.ssh/id_rsa && chmod 600 /home/git/.ssh/id_rsa && ssh-keyscan -H #{service("git-server").ip(user: user)}>> ~/.ssh/known_hosts",
    as: user
  )
  raise "cannot add private key to ssh-git server pod" unless @result[:success]
  #git config, we should have this when we git clone a repo
  @result = pod.exec(
    "bash", "-c",
    "git config --global user.email \"sample@redhat.com\" &&  git config --global user.name \"sample\"",
    as: user
  )
  raise "cannot set git global config" unless @result[:success]

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
  unless pod.name.start_with? "git-"
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

# pod-for-ping is a pod that has curl, wget, telnet and ncat
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

# configure iSCSI in current environment; if already exists, skip; if pod is
#   not ready, then delete and create it again
Given /^I have a iSCSI setup in the environment$/ do
  ensure_admin_tagged

  _project = project("default", switch: false)
  _pod = cb.iscsi_pod = pod("iscsi-target", _project)
  _service = cb.iscsi_service = service("iscsi-target", _project)

  if _pod.ready?(user: admin, quiet: true)[:success]
    logger.info "found existing iSCSI pod, skipping config"
    cb.iscsi_ip = _service.ip(user: admin)
    next
  elsif _pod.exists?(user: admin, quiet: true)
    logger.warn "broken iSCSI pod, will try to recreate keeping other config"
    pod_only = true
    @result = admin.cli_exec(:delete, n: _project.name, object_type: "pod", object_name_or_id: _pod.name)
    raise "could not delete broken iSCSI pod" unless @result[:success]
  end

  @result = admin.cli_exec(:create, n: _project.name, f: 'https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/iscsi-target.json')
  raise "could not create iSCSI pod" unless @result[:success]

  unless pod_only
    @result = admin.cli_exec(:create, n: _project.name, f: 'https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/service.json')
    raise "could not create iSCSI service" unless @result[:success]
  end

  # setup to work with service
  @result = _pod.wait_till_ready(admin, 120)
  raise "iSCSI pod did not become ready" unless @result[:success]
  iscsi_ip = cb.iscsi_ip = _service.ip(user: admin)
  @result = _pod.exec("targetcli", "/iscsi/iqn.2016-04.test.com:storage.target00/tpg1/portals", "create", iscsi_ip, as: admin)
  raise "could not create portal to iSCSI service" unless @result[:success]

  next if pod_only

  env.hosts.each do |host|
    setup_commands = [
      "echo 'InitiatorName=iqn.2016-04.test.com:test.img' > /etc/iscsi/initiatorname.iscsi",
      "cat >> /etc/iscsi/iscsid.conf << EOF\n" +
        "node.session.auth.authmethod = CHAP\n" +
        "node.session.auth.username = 5f84cec2\n" +
        "node.session.auth.password = b0d324e9\n" +
        "EOF\n",
      "systemctl enable iscsid",
      "systemctl start iscsid",
      "iscsiadm -m discovery -t sendtargets -p #{iscsi_ip}",
      "iscsiadm -m node -p #{iscsi_ip}:3260 -T iqn.2016-04.test.com:storage.target00 -I default --login"
    ]

    res = host.exec_admin(*setup_commands)
    raise "iSCSI initiator setup commands error" unless @result[:success]
  end
end
