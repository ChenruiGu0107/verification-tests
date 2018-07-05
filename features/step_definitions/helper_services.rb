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

  step %Q{I run oc create over "https://github.com/openshift-qe/v3-testfiles/raw/master/storage/nfs/nfs-server.yaml" replacing paths:}, table(%{
      | ["items"][0]["spec"]["volumes"][0]["hostPath"]["path"] | /mnt/#{project.name} |
  })
  step %Q/the step should succeed/

  step 'I wait for the "nfs-service" service to become ready up to 300 seconds'
  # now you have NFS running, to get IP, call `service.ip` or
  #   `service("nfs-service").ip`

  cb.nfs_pod = pod("nfs-server")
  teardown_add {
    step %/I use the "#{cb.nfs_pod.node_name(user: user)}" node/
    step %Q{I run commands on the host:}, table(%{
        | rm -rf /mnt/#{project.name} |
     })
    step %Q/the step should succeed/
  }
  @result = cb.nfs_pod.exec("bash", "-c", "chmod g+w /mnt/data", as: user)
  step %Q/the step should succeed/
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
  # To make sure the nfs-provisioner role is deleted which is created mannually by user
  step %Q/admin ensures "nfs-provisioner-runner" clusterrole is deleted/
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
      | ["spec"]["serviceAccount"]         | nfs-provisioner                                     |
      | ["metadata"]["name"]               | nfs-provisioner-<%= cb.nfsprovisioner %>            |
      | ["spec"]["containers"][0]["image"] | quay.io/kubernetes_incubator/nfs-provisioner:v1.0.9 |
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

#This is a step to create efs-provisioner service in the project
Given /^I have a efs-provisioner(?: with fsid "(.+)")?(?: of region "(.+)")? in the(?: "([^ ]+?)")? project$/ do |fsid, region, project_name|
  ensure_admin_tagged
  _project = project(project_name)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end
  _deployment = deployment("efs-provisioner", _project)
  _deployment.ensure_deleted(user: admin)
  #Create configmap,secret,sa,deployment
  step %Q{I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/efsconfigm.yaml"}
  cm = YAML.load(@result[:response])
  path = @result[:abs_path]
  cm["data"]["file.system.id"] = fsid if fsid
  cm["data"]["aws.region"] = region if region
  fsid ||= cm["data"]["file.system.id"]
  region ||= cm["data"]["aws.region"]
  File.write(path, cm.to_yaml)
  @result = user.cli_exec(:create, f: path)
  raise "Could not create efs-provisioner configmap" unless @result[:success]
  step 'I create the serviceaccount "efs-provisioner"'
  step %Q/SCC "hostmount-anyuid" is added to the "system:serviceaccount:<%= project.name %>:efs-provisioner" service account/
  # To make sure the efs-provisioner role is deleted which is created mannually by user
  step %Q/admin ensures "efs-provisioner-runner" clusterrole is deleted/
  @result = admin.cli_exec(:create, f: "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/auth/openshift-clusterrole.yaml")
  raise "could not create efs-provisioner ClusterRole" unless @result[:success]
  step %Q/admin ensures "efs-provisioner-runner" clusterrole is deleted after scenario/
  step %Q/cluster role "efs-provisioner-runner" is added to the "system:serviceaccount:<%= project.name %>:efs-provisioner" service account/
  step %Q{I run oc create over "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/deployment.yaml" replacing paths:}, table(%{
    | ["spec"]["template"]["spec"]["serviceAccount"]              | efs-provisioner                     |
    | ["spec"]["template"]["spec"]["containers"][0]["image"]      | openshift3/efs-provisioner          |
    | ["spec"]["template"]["spec"]["volumes"][0]["nfs"]["server"] | #{fsid}.efs.#{region}.amazonaws.com |
    | ["spec"]["template"]["spec"]["volumes"][0]["nfs"]["path"]   | /                                   |
    })
  step %Q/a pod becomes ready with labels:/, table(%{
    | app=efs-provisioner |
    })
end

#The following helper step will create a squid proxy, and
#save the service ip of the proxy pod for later use in the scenario.
Given /^I have a(n authenticated)? proxy configured in the project$/ do |use_auth|
  if use_auth
    step %Q/I run the :new_app client command with:/, table(%{
      | docker_image | aosqe/squid-proxy  |
      | env          | USE_AUTH=1         |
      })
  else
    step %Q/I run the :new_app client command with:/, table(%{
      | docker_image | aosqe/squid-proxy  |
      })
  end
  step %Q/the step should succeed/
  step %Q/a pod becomes ready with labels:/, table(%{
    | app=squid-proxy |
    })
  step %Q/I wait for the "squid-proxy" service to become ready/
  step %Q/evaluation of `service.ip` is stored in the :proxy_ip clipboard/
  step %Q/evaluation of `pod` is stored in the :proxy_pod clipboard/
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
        "git config --global credential.http://#{cb.git_svc_ip}:8080.helper '!f() { echo \"username=#{user.name}\"; echo \"password=#{user.cached_tokens.first}\"; }; f'",
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

# headertest is a service that returns all HTTP request headers used by client
Given /^I have a header test service in the#{OPT_QUOTED} project$/ do |project_name|
  project(project_name)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  @result = user.cli_exec(:create, f: "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/dc.json")
  raise "could not create header test dc" unless @result[:success]
  cb.header_test_dc = dc("header-test")

  @result = user.cli_exec(:create, f: "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/insecure-service.json")
  raise "could not create header test svc" unless @result[:success]
  cb.header_test_svc = service("header-test-insecure")

  @result = user.cli_exec(:expose,
                          name: "header-test-insecure",
                          resource: "service",
                          resource_name: "header-test-insecure"
                         )
  raise "could not expose header test svc" unless @result[:success]
  cb.header_test_route = route("header-test-insecure",
                               service("header-test-insecure"))

  @result = CucuShift::Pod.wait_for_labeled(
    "deploymentconfig=header-test",
    count: 1, user: user, project: project, seconds: 300)
  raise "timeout waiting for header test pod to start" unless @result[:success]
  cache_pods(*@result[:matching])
  cb.header_test_pod = pod

  step 'I wait for a web server to become available via the route'
  cb.req_headers = @result[:response].scan(/^\s+(.+?): (.+)$/).to_h
end

# skopeo is a pod that has skopeo clients tools
Given /^I have a skopeo pod in the(?: "([^ ]+?)")? project$/ do |project_name|
  project(project_name, switch: true)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  @result = user.cli_exec(:create, f: "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/skopeo-deployment.json")
  raise "could not create a skopeo" unless @result[:success]

  step %Q/a pod becomes ready with labels:/, table(%{
        | name=skopeo |
    })

  cb.skopeo_pod = pod
  cb.skopeo_dc = dc("skopeo")
end

# Download the ca.pem to pod-for ping
Given /^CA trust is added to the pod-for-ping$/ do
  @result = cb.ping_pod.exec(
    "bash", "-c",
    "wget https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem -O /tmp/ca.pem -T 10 -t 3",
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
  elsif _pod.exists?(user: admin, quiet: true)
    logger.warn "broken iSCSI pod, will try to recreate keeping other config"
    @result = admin.cli_exec(:delete, n: _project.name, object_type: "pod", object_name_or_id: _pod.name)
    raise "could not delete broken iSCSI pod" unless @result[:success]
  else
    @result = admin.cli_exec(:create, n: _project.name, f: 'https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/iscsi-target.json')
    raise "could not create iSCSI pod" unless @result[:success]
  end

  if !_service.exists?(user:admin, quiet: true)
    @result = admin.cli_exec(:create, n: _project.name, f: 'https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/service.json')
    raise "could not create iSCSI service" unless @result[:success]
  end

  # setup to work with service
  @result = _pod.wait_till_ready(admin, 120)
  raise "iSCSI pod did not become ready" unless @result[:success]
  iscsi_ip = cb.iscsi_ip = _service.ip(user: admin)
  @result = _pod.exec("targetcli", "/iscsi/iqn.2016-04.test.com:storage.target00/tpg1/portals", "create", iscsi_ip, as: admin)
  raise "could not create portal to iSCSI service" unless @result[:success] unless @result[:stderr].include?("This NetworkPortal already exists in configFS")

  env.hosts.each do |host|
    setup_commands = [
      "echo 'InitiatorName=iqn.2016-04.test.com:test.img' > /etc/iscsi/initiatorname.iscsi",
      "sed -i '/^node.session.auth./'d  /etc/iscsi/iscsid.conf",
      "cat >> /etc/iscsi/iscsid.conf << EOF\n" +
        "node.session.auth.authmethod = CHAP\n" +
        "node.session.auth.username = 5f84cec2\n" +
        "node.session.auth.password = b0d324e9\n" +
        "EOF\n",
      "systemctl enable iscsid",
      "systemctl restart iscsid",
      "iscsiadm -m discovery -t sendtargets -p #{iscsi_ip}",
      "iscsiadm -m node -p #{iscsi_ip}:3260 -T iqn.2016-04.test.com:storage.target00 -I default --login"
    ]

    res = host.exec_admin(*setup_commands)
    raise "iSCSI initiator setup commands error" unless res[:success]
  end
end

# Using after step: I have a iSCSI setup in the environment
Given /^I create a second iSCSI path$/ do
  ensure_admin_tagged

  _project = project("default", switch: false)
  step %Q{I download a file from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/service.json"}
  service_content = JSON.load(@result[:response])
  path = @result[:abs_path].rpartition(".")[0] + ".yaml"
  service_content["metadata"]["name"] = "iscsi-target-2"
  File.write(path, service_content.to_yaml)
  @result = admin.cli_exec(:create, f: path, namespace: _project.name)
  raise "could not create iSCSI service" unless @result[:success]
  _service_2 = service("iscsi-target-2", _project)
  cb.iscsi_ip_2 = _service_2.ip(user: admin)
  teardown_add {
    _service_2.ensure_deleted(user: admin)
  }
end

Given /^I disable the second iSCSI path$/ do
  ensure_destructive_tagged

  _project = project("default", switch: false)
  _service_2 = service('iscsi-target-2', _project)
  _service_2.ensure_deleted(user: admin)
end

Given /^default router is disabled and replaced by a duplicate$/ do
  ensure_destructive_tagged
  orig_project = project(0) rescue nil
  _project = project("default")

  step 'default router image is stored into the :default_router_image clipboard'
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
                           images: cb.default_router_image)

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
  step %Q/I run the :patch client command with:/, table(%{
      | resource      | dc                                                                                                                                                                                                                                 |
      | resource_name | registry                                                                                                                                                                                                                           |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"registry","readinessProbe":{"httpGet":{"httpHeaders":[{"name":"Authorization","value":"Basic dGVzdHVzZXI6dGVzdHBhc3N3b3Jk"}],"path":"/v2/","port":5000,"scheme":"HTTP"}}}]}}}} |
  })
  step %Q/the step should succeed/
  step %Q/a pod becomes ready with labels:/, table(%{
       | deploymentconfig=registry |
  })
end

Given /^I deploy local storage provisioner(?: under path #{QUOTED})?$/ do |path|
  ensure_admin_tagged
  ensure_destructive_tagged

  ose_version = env.get_version(user:admin)
  namespace="local-storage"
  serviceaccount="local-storage-admin"
  configmap="local-volume-config"
  template="local-storage-provisioner"
  image="openshift3/local-storage-provisioner:v#{ose_version[1]}.#{ose_version[2]}"
  path ||="/mnt/local-storage"

  env.hosts.each do |host|
    teardown_add {
      clean_commands = [
        "umount #{path}/fast/vol1",
        "umount #{path}/fast/vol2",
        "umount #{path}/slow/vol1",
        "umount #{path}/slow/vol2",
        "rm -rf #{path}"
      ]
      res = host.exec_admin(*clean_commands)
      raise "error cleaning up subdirs for local storage provisioner" unless res[:success]
    }
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

  step %/I switch to cluster admin pseudo user/
  step %Q/admin ensures "#{namespace}" project is deleted/
  step %Q/I run the :oadm_new_project admin command with:/, table(%{
      | node_selector | role=node    |
      | project_name  | #{namespace} |
  })
  step %Q/the step should succeed/

  step %Q{I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/localvolume/configmap.yaml"}
  cfm = YAML.load(@result[:response])
  filepath = @result[:abs_path]
  scmap = cfm["data"]["storageClassMap"].gsub("/mnt/local-storage", path)
  cfm["data"]["storageClassMap"] = scmap
  File.write(filepath, cfm.to_yaml)
  res = admin.cli_exec(:create, n: namespace, f: filepath)
  raise "error creating configmap for local storage provisioner" unless res[:success]

  step %Q/I run the :create_serviceaccount admin command with:/, table(%{
      | serviceaccount_name | #{serviceaccount} |
      | n                   | #{namespace}      |
  })
  step %Q/the step should succeed/

  step %Q/SCC "privileged" is added to the "system:serviceaccount:local-storage:#{serviceaccount}" service account/

  step %Q/I run the :create admin command with:/, table(%{
      | f | https://raw.githubusercontent.com/openshift/origin/release-3.9/examples/storage-examples/local-examples/local-storage-provisioner-template.yaml |
      | n | #{namespace}                                                                                                                                    |
  })
  step %Q/the step should succeed/

  step 'admin ensures "local-storage:provisioner-node-binding" clusterrolebinding is deleted after scenario'
  step 'admin ensures "local-storage:provisioner-pv-binding" clusterrolebinding is deleted after scenario'
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
  step %/#{nodes.size} pods become ready with labels:/, table(%{
      | app=local-volume-provisioner|
  })

  pv_count = 0
  CucuShift::PersistentVolume.list(user: admin).each { |pv|
    if pv.name.start_with?("local-pv-") && pv.local_path&.start_with?(path)
      pv_count += 1
      teardown_add { pv.ensure_deleted }
    end
  }

  step %Q/admin ensures "#{namespace}" project is deleted after scenario/

  raise "error creating PVs with local storage provisioner" unless (pv_count == nodes.size * 4)
end

