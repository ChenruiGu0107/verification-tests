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
  ensure_admin_tagged
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
      | resource  | dc/docker-registry                                      |
      | e         | REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/registrytmp  |
      | namespace | default                                                 |
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
