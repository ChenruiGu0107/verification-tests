# This step will clean all the layers in the default registry
#Given /^all the image layers are deleted in the internal registry$/ do
#  ensure_admin_tagged
#  org_proj_name = project.name
#  org_user = @user
#  _regdir =  cb["reg_dir"]
#  _regdir = "/registry" unless _regdir
#  begin
#    step %Q/I switch to cluster admin pseudo user/
#    step %Q/I use the "default" project/
#    step %Q/a pod becomes ready with labels:/, table(%{
#        | deploymentconfig=docker-registry |
#    })
#    step %Q/I execute on the pod:/,table([["bash","-c","rm -rf #{_regdir}/docker/registry/v2/blobs/*"]])
#    step %Q/the step should succeed/
#  ensure
#    @user = org_user
#    project(org_proj_name)
#  end
#end

Given /^I change the internal registry pod to use a new emptyDir volume$/ do
  ensure_destructive_tagged
  cb["reg_dir"] = "/registrytmp"
  begin
    step %Q/I run the :volume admin command with:/, table(%{
      | resource   | dc/docker-registry |
      | add        | true               |
      | mount-path | /registrytmp       |
      | type       | emptyDir           |
      | namespace  | default            |
    })
    step %Q/the step should succeed/
    step %Q/I wait until the latest rc of internal registry is ready/
    step %Q/I run the :env admin command with:/, table(%{
      | resource  | dc/docker-registry                                     |
      | e         | REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/registrytmp |
      | e         | REGISTRY_CONFIGURATION_PATH=/config.yml                |
      | namespace | default                                                |
    })
    step %Q/the step should succeed/
    step %Q/I wait until the latest rc of internal registry is ready/
  end
end

Given /^I wait until the latest rc of internal registry is ready$/ do
  ensure_admin_tagged
  _rc = CucuShift::ReplicationController.get_labeled(
    "docker-registry",
    user: admin,
    project: project("default", switch: false)
  ).max_by {|rc| rc.props[:created]}
  raise "no matching registry rcs found" unless _rc
  @result = _rc.wait_till_ready(admin, 900)
  raise "#{rc_name} didn't become ready" unless @result[:success]
end

Given /^all the image layers in the#{OPT_SYM} clipboard do( not)? exist in the registry$/ do |layers_board,not_exist|
  _regdir =  cb["reg_dir"]
  _regdir = "/registry" unless _regdir
  layers = cb[layers_board]
  ensure_admin_tagged
  org_proj_name = project.name
  org_user = @user
  if not_exist
    expect_layer_no =0
    err_msg = "exist"
  else
    expect_layer_no = 1
    err_msg = "do not exist"
  end
  begin
    step %Q/I switch to cluster admin pseudo user/
    step %Q/I use the "default" project/
    step %Q/a pod becomes ready with labels:/, table(%{
        | deploymentconfig=docker-registry |
    })
    layers.each { | layer|
      id =  layer.dig("name").split(':')[1]
      step %Q/I execute on the pod:/,table([["bash","-c","find #{_regdir}/docker/registry/v2/blobs/ |grep #{id} |grep -v data | wc -l"]])
      step %Q/the step should succeed/
      layer_no = @result[:response].strip.to_i
      unless layer_no == expect_layer_no
        raise "ImageStreamTag layer : #{id} #{err_msg} on the registry pod"
      end
    }
  ensure
    @user = org_user
    project(org_proj_name)
  end
end


Given /^I add the insecure registry to docker config on the node$/ do
  ensure_destructive_tagged
  raise "You need to create a insecure private docker registry first!" unless cb.reg_svc_url
  _node = node

  step 'the node service is verified'
  step 'the node service is restarted on the host after scenario'
  teardown_add {
    err_msg = "The docker service failed to restart and is not active"
    @result = _node.host.exec_admin("systemctl restart docker")
    raise err_msg unless @result[:success]
    sleep 3
    @result = _node.host.exec_admin("systemctl is-active docker")
    raise err_msg unless @result[:success]
  }
  step 'the "/etc/sysconfig/docker" file is restored on host after scenario'
  step 'I run commands on the host:', table(%{
      | sed -i '/^INSECURE_REGISTRY*/d' /etc/sysconfig/docker |
  })
  step 'the step should succeed'
  step 'I run commands on the host:', table(%{
      | echo "INSECURE_REGISTRY='--insecure-registry <%= cb.reg_svc_url%>'" >> /etc/sysconfig/docker |
   })
  step 'the step should succeed'
  step "I run commands on the host:", table(%{
      | systemctl restart docker |
  })
  step "the step should succeed"
  step 'I wait for the "<%= cb.reg_svc_name %>" service to become ready'
end

Given /^I docker push on the node to the registry the following images:$/ do |table|
  ensure_admin_tagged
  table.raw.each do |image|
    step 'I run commands on the host:', table(%Q{
        | docker pull #{ image[0] } |
                                              })
    step 'I run commands on the host:', table(%Q{
        | docker tag #{ image[0] } #{ cb.reg_svc_url }/#{ image[1] } |
                                              })
    step 'I run commands on the host:', table(%Q{
        | docker push #{ cb.reg_svc_url }/#{ image[1] } |})
  end
end

Given /^I log into auth registry on the node$/ do
  ensure_admin_tagged
  step 'I run commands on the host:', table(%{
        | docker login -u <%= cb.reg_user %> -p <%= cb.reg_pass %> <%= cb.reg_svc_url %> |
  })
  step 'the step should succeed'
end
