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

#This is a step to create nfs-provisioner pod or dc in the project
Given /^I have a nfs-provisioner (pod|service) in the(?: "([^ ]+?)")? project$/ do |deploymode, project_name|
  ensure_admin_tagged
  _service = deploymode == "service" ? true : false
  _project = project(project_name)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end
  _deployment = deployment("nfs-provisioner", _project)
  _scc= security_context_constraints("nfs-provisioner")
  _deployment.ensure_deleted(user: admin)
  _scc.ensure_deleted(user: admin)
  # Create sc, scc, clusterrole and etc    
  step 'I create the serviceaccount "nfs-provisioner"'
  step %Q{the following scc policy is created: https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/auth/openshift-scc.yaml}
  step %Q/SCC "nfs-provisioner" is added to the "system:serviceaccount:<%= project.name %>:nfs-provisioner" service account/
  step %Q{I download a file from "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/auth/clusterrole.yaml"}
  cr = YAML.load(@result[:response])
  path = @result[:abs_path]
  cr["apiVersion"] = "v1"
  File.write(path, cr.to_yaml)
  @result = admin.cli_exec(:create, f: path)
  raise "could not create nfs-provisioner ClusterRole" unless @result[:success]
  step %Q/admin ensures "nfs-provisioner-runner" clusterrole is deleted after scenario/
  step %Q/cluster role "nfs-provisioner-runner" is added to the "system:serviceaccount:<%= project.name %>:nfs-provisioner" service account/
  env.nodes.map(&:host).each do |host|
    setup_commands = [
      "mkdir -p /srv/",
      "chcon -Rt svirt_sandbox_file_t /srv/"
    ]
    res = host.exec_admin(*setup_commands)
    raise "Set up hostpath for nfs-provisioner failed" unless @result[:success]
  end
  if _service 
    @result = user.cli_exec(:create, f: "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/auth/deployment-sa.yaml")
    raise "could not create nfs-provisioner deployment" unless @result[:success]
    step %Q/a pod becomes ready with labels:/, table(%{
      | app=nfs-provisioner |
      })
  else
    cb.nfsprovisioner = rand_str(5, :dns)
    step %Q{I run oc create over "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/pod.yaml" replacing paths:}, table(%{
      | ["spec"]["serviceAccount"] | nfs-provisioner                          |
      | ["metadata"]["name"]       | nfs-provisioner-<%= cb.nfsprovisioner %> |
      })
    step %Q/the pod named "nfs-provisioner-<%= cb.nfsprovisioner %>" becomes ready/
  end
  unless storage_class("nfs-provisioner-"+project.name).exists?(user: admin, quiet: true)
    step %Q{admin creates a StorageClass from "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/class.yaml" where:}, table(%{
      | ["metadata"]["name"] | nfs-provisioner-<%= project.name %> |
      })
    step %Q/the step should succeed/
  end
end

#The following helper step will create a squid proxy, and
#save the service ip of the proxy pod for later use in the scenario.
Given /^I have a proxy configured in the project$/ do
  step %Q/I run the :new_app client command with:/, table(%{
    | docker_image | aosqe/squid-proxy |
    })
  step %Q/the step should succeed/
  step %Q/a pod becomes ready with labels:/, table(%{
    | app=squid-proxy |
    })
  step %Q/I wait for the "squid-proxy" service to become ready/
  step %Q/evaluation of `service.ip` is stored in the :proxy_ip clipboard/
end

Given /^I have LDAP service in my project$/ do
    ###
    # The original idea is trying to put ldap server in the openshift to make this flexy.
    # Since we run the scenario in jenkins slave which is not in sdn, then two choices come to me:
    # 1, Create a route for the ldapserver pod, but blocked by this us https://trello.com/c/9TXvMeS2 is done.
    # 2, Port forward the ldap server pod to the jenkins slave.
    # So take the second one since this one can be implemented currently
    ###
    step %Q/I run the :run client command with:/, table(%{
      | name  |ldapserver                             |
      | image |openshift/openldap-2441-centos7:latest |
      })
    step %Q/the step should succeed/
    step %Q/I wait until replicationController "ldapserver-1" is ready/

    cb.ldap_pod = CucuShift::Pod.get_labeled(["run", "ldapserver"], user: user, project: project).first
    cb.ldap_pod_name = cb.ldap_pod.name
    cache_pods cb.ldap_pod

    # Init the test data in ldap server.
    @result = cb.ldap_pod.exec("bash", "-c", "curl -Ss https://raw.githubusercontent.com/openshift/origin/master/images/openldap/contrib/init.ldif | ldapadd -x -h 127.0.0.1 -p 389 -D cn=Manager,dc=example,dc=com -w admin", as: user)
    step %Q/the step should succeed/

    # Port forword ldapserver to local
    step %Q/evaluation of `rand(32000...65536)` is stored in the :ldap_port clipboard/
    step %Q/I run the :port_forward background client command with:/, table(%{
      | pod       | <%= cb.ldap_pod_name %> |
      | port_spec | <%= cb.ldap_port %>:389 |
      })
    step %Q/the step should succeed/
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

Given /^I have a git client pod in the#{OPT_QUOTED} project$/ do |project_name|
  project(project_name, switch: true)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  #@result = user.cli_exec(:create, f: "https://raw.githubusercontent.com/openshift/origin/master/examples/gitserver/gitserver-ephemeral.yaml")
  @result = user.cli_exec(:run, name: "git-client", image: "openshift/origin-gitserver", env: 'GIT_HOME=/var/lib/git')
  raise "could not create the git client pod" unless @result[:success]

  @result = CucuShift::Pod.wait_for_labeled("run=git-client", count: 1,
                                            user: user, project: project, seconds: 300)
  raise "#{pod.name} pod did not become ready" unless @result[:success]

  cache_pods(*@result[:matching])

  @result = pod.wait_till_ready(user, 300)

  unless @result[:success]
    logger.error(@result[:response])
    raise "#{pod.name} pod did not become ready"
  end

  # for ssh-git : only need to add private key on git-client pod
  unless cb.ssh_private_key.nil? then
    @result = pod.exec(
        "bash", "-c",
        "echo '#{cb.ssh_private_key.to_pem}' >> /home/git/.ssh/id_rsa && chmod 600 /home/git/.ssh/id_rsa && ssh-keyscan -H #{cb.git_svc_ip}>> ~/.ssh/known_hosts",
        as: user
    )
    raise "cannot add private key to git client server pod" unless @result[:success]
  end

  # for http-git : only need to config credential
  # due to this bug: https://bugzilla.redhat.com/show_bug.cgi?id=1353407
  # currently we use user token instead of service account
  if cb.ssh_private_key.nil? then
    @result = pod.exec(
        "bash", "-c",
        "git config --global credential.http://#{cb.git_svc_ip}:8080.helper '!f() { echo \"username=#{user.name}\"; echo \"password=#{user.get_bearer_token.token}\"; }; f'",
        as: user
    )
    raise "cannot set git client pod global config" unless @result[:success]
  end

  # only set pod name to clipboards
  cb.git_client_pod = pod
end

# pod-for-ping is a pod that has curl, wget, telnet and ncat
Given /^I have a pod-for-ping in the(?: "([^ ]+?)")? project$/ do |project_name|
  project(project_name, switch: true)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  @result = user.cli_exec(:create, f: "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/aosqe-pod-for-ping.json")
  raise "could not create a pod-for-ping" unless @result[:success]

  cb.ping_pod = pod("hello-pod")
  @result = pod("hello-pod").wait_till_ready(user, 300)
  raise "pod-for-ping did not become ready in time" unless @result[:success]

end

# skopeo is a pod that has skopeo clients tools
Given /^I have a skopeo pod in the(?: "([^ ]+?)")? project$/ do |project_name|
  project(project_name, switch: true)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  @result = user.cli_exec(:create, f: "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/imagestream/skopeo.json")
  raise "could not create a skopeo" unless @result[:success]

  @result = pod("skopeo").wait_till_ready(user, 300)
  raise "skopeo pod did not become ready in time" unless @result[:success]

end

# Download the ca.pem to pod-for ping
Given /^CA trust is added to the pod-for-ping$/ do
  @result = cb.ping_pod.exec(
    "bash", "-c",
    "wget https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem -O /tmp/ca.pem",
    as: user
  )
  raise "cannot get ca cert" unless @result[:success]
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

# Configure CephFS server in current environment
Given /^I have a CephFS pod in the(?: "([^ ]+?)")? project$/ do |project_name|
  ensure_admin_tagged

  project(project_name)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  @result = admin.cli_exec(:create, n: project.name, f: 'https://raw.githubusercontent.com/openshift-qe/docker-ceph/master/cephfs-server.json')
  raise "could not create CephFS pod" unless @result[:success]

  @result = user.cli_exec(:create, n: project.name, f: 'https://raw.githubusercontent.com/openshift-qe/docker-ceph/master/cephfs-secret.yaml')
  raise "could not create CephFS secret" unless @result[:success]

  step 'the pod named "cephfs-server" becomes ready'

  # now you have CephFS running, to get IP, call `pod.ip` or
  #   `pod("cephfs-server").ip(user: user)`
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

Given /^default router is disabled and replaced by a duplicate$/ do
  ensure_destructive_tagged
  orig_project = project(0) rescue nil
  _project = project("default")

  step 'I store master image version in the clipboard'
  @result = dc("router", _project).ready?(user: admin)
  unless @result[:success]
    raise "default router not ready before scenario, fix it first"
  end
  step 'default router replica count is stored in the :router_num clipboard'
  step 'default router replica count is restored after scenario'
  step 'admin ensures "testroute" dc is deleted after scenario'
  step 'admin ensures "testroute" service is deleted after scenario'
  step 'admin ensures "router-testroute-role" clusterrolebinding is deleted after scenario'
  @result = admin.cli_exec(:scale,
                           resource: "dc",
                           name: "router",
                           replicas: "0",
                           n: "default")
  step 'the step should succeed'
  # cmd fails, see https://bugzilla.redhat.com/show_bug.cgi?id=1381378
  @result = admin.cli_exec(:oadm_router,
                           name: "testroute",
                           replicas: cb.router_num.to_s,
                           n: "default",
                           images: product_docker_repo + "openshift3/ose-haproxy-router:" + cb.master_version)

  cb.new_router_dc = dc("testroute", _project)
  @result = dc.wait_till_status(:complete, admin, 300)
  unless @result[:success]
    user.cli_exec(:logs,
                  resource_name: "dc/#{resource_name}",
                  n: "default")
    raise "dc 'testroute' never completed"
  end

  project(orig_project.name) if orig_project
end

Given /^I have a registry in my project$/ do
  ensure_admin_tagged
  if CucuShift::Project::SYSTEM_PROJECTS.include?(project(generate: false).name)
    raise "I refuse create registry in a system project: #{project.name}"
  end
  @result = admin.cli_exec(:new_app, docker_image: "registry:2.5.1", namespace: project.name)
  step %Q/the step should succeed/
  @result = admin.cli_exec(:set_probe, resource: "dc/registry", readiness: true, liveness: true, get_url: "http://:5000/v2",namespace: project.name)
  step %Q/the step should succeed/
  step %Q/a pod becomes ready with labels:/, table(%{
       | deploymentconfig=registry |
  })
  cb.reg_svc_ip = "#{service("registry").ip(user: user)}"
  cb.reg_svc_port = "#{service("registry").ports(user: user)[0].dig("port")}"
  cb.reg_svc_url = "#{cb.reg_svc_ip}:#{cb.reg_svc_port}"
  cb.reg_svc_name = "registry"
end

Given /^I have a registry with htpasswd authentication enabled in my project$/ do
  ensure_admin_tagged
  if CucuShift::Project::SYSTEM_PROJECTS.include?(project(generate: false).name)
    raise "I refuse create registry in a system project: #{project.name}"
  end
  @result = admin.cli_exec(:new_app, docker_image: "registry:2", namespace: project.name)
  step %Q/the step should succeed/
  step %Q/a pod becomes ready with labels:/, table(%{
       | deploymentconfig=registry |
  })
  step %Q{I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/registry/htpasswd"}
  @result = user.cli_exec(:new_secret, secret_name: "htpasswd-secret", credential_file: "./htpasswd", namespace: project.name)
  step %Q/I run the :volume client command with:/, table(%{
    | resource    | dc/registry     |
    | add         | true            |
    | mount-path  | /auth           |
    | type        | secret          |
    | secret-name | htpasswd-secret |
    | namespace   | #{project.name} |
  })
  step %Q/the step should succeed/
  step %Q/I run the :env client command with:/, table(%{
    | resource  | dc/registry                                 |
    | e         | REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd  |
    | e         | REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm |
    | e         | REGISTRY_AUTH=htpasswd                      |
    | namespace | #{project.name}                             |
  })
  step %Q/the step should succeed/
  step %Q/a pod becomes ready with labels:/, table(%{
       | deploymentconfig=registry |
  })
  cb.reg_svc_ip = "#{service("registry").ip(user: user)}"
  cb.reg_svc_port = "#{service("registry").ports(user: user)[0].dig("port")}"
  cb.reg_svc_url = "#{cb.reg_svc_ip}:#{cb.reg_svc_port}"
  cb.reg_svc_name = "registry"
  cb.reg_user = "testuser"
  cb.reg_pass = "testpassword"
  step %Q/I run the :set_probe client command with:/, table(%{
    | resource  | dc/registry               |
    | readiness |                           |
    | get_url   | http://:5000/ |
  })
  step %Q/the step should succeed/
end
