Given /^the "([^"]*)" was created$/ do |build_name|
  @result = build(build_name).wait_to_appear(user, 30)

  unless @result[:success]
    raise "build #{build_name} never created"
  end
end

# success when build finish regardless of completion status
Given /^the "([^"]*)" build finished$/ do |build_name|
  @result = build(build_name).wait_till_finished(user, 60*15)

  unless @result[:success]
    raise "build #{build_name} never finished"
  end
end

# success if build completed successfully
Given /^the "([^"]*)" build completed$/ do |build_name|
  @result = build(build_name).wait_till_completed(user, 60*15)

  unless @result[:success]
    raise "build #{build_name} never completed or failed"
  end
end

# success if build completed with a failure
Given /^the "([^"]*)" build failed$/ do |build_name|
  @result = build(build_name).wait_till_failed(user, 60*15)

  unless @result[:success]
    raise "build #{build_name} completed with success or never finished"
  end
end

Given /^the "([^"]*)" build becomes running$/ do |build_name|
  @result = build(build_name).wait_till_running(user, 30)

  unless @result[:success]
    raise "build #{build_name} never started or failed fast"
  end
end
