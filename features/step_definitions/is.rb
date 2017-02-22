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
