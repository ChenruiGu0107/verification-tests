Then /^a web server should be available via the(?: "(.+?)")? route$/ do |route_name|
  @result = CucuShift::Http.get(url: "http://" + route(route_name).dns(by: user))
  unless @result[:success]
    logger.error(@result[:response])
    # you may notice now `route` refers to last called route,
    #   i.e. route(route_name)
    raise "error openning web server on route '#{route.name}'"
  end
end

Given /^I wait(?: up to ([0-9]+) seconds)? for a server to become available via the(?: "(.+?)")? route$/ do |seconds, route_name|
  success = wait_for(seconds || 15*60) {
    @result = CucuShift::Http.get(url: "http://" + route(route_name).dns(by: user))
    @result[:success]
  }


  unless success
    logger.error(@result[:response])
    # you may notice now `route` refers to last called route,
    #   i.e. route(route_name)
    raise "error openning web server on route '#{route.name}'"
  end
end

When /^I open web server via the (?: "(.+?)")? route$/ do |route_name|
  @result = CucuShift::Http.get(url: "http://" + route(route_name).dns(by: user))
end
