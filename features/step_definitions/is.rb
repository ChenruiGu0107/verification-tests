Given /^the(?: "([^"]*)")? image stream was created$/ do |is_name|
  @result = image_stream(is_name).wait_to_appear(user, 30)

  unless @result[:success]
    raise "ImageStream #{is_name} never created"
  end
end

Given /^the(?: "([^"]*)")? image stream becomes ready$/ do |is_name|
  @result = image_stream(is_name).wait_till_ready(user,120)

  unless @result[:success]
    raise "ImageStream #{is_name} did not become ready"
  end
end

Given /^the(?: "([^"]*)")? image stream tag was created$/ do |istag_name|
  @result = image_stream_tag(istag_name).wait_to_appear(user, 30)

  unless @result[:success]
    raise "ImageStreamTag #{istag_name} never created"
  end
end
Given /^all the image layers in the#{OPT_SYM} clipboard were deleted$/ do |layers_board|
  layers = cb[layers_board]
  ensure_admin_tagged
  org_proj_name = project.name
  org_user = @user
  begin
    step %Q/I switch to cluster admin pseudo user/
    step %Q/I use the "default" project/
    step %Q/a pod becomes ready with labels:/, table(%{
        | deploymentconfig=docker-registry |
    })
    layers.each { | layer|
      id =  layer.dig("name").split(':')[1]
      step %Q/I execute on the pod:/,table([["bash","-c","find /registry/docker/registry/v2/blobs/ |grep #{id} | wc -l"]])
      step %Q/the step should succeed/
      layer_no = @result[:response].strip.to_i
      unless layer_no == 0
        raise "ImageStreamTag layer : #{id} is not deleted on the registry pod"
      end
    }
  ensure
    @user = org_user
    project(org_proj_name)
  end
end
