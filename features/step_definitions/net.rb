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
  @result = route(route_name).wait_http_accessible(by: user, timeout: seconds)

  unless @result[:success]
    logger.error(@result[:response])
    # you may notice now `route` refers to last called route,
    #   i.e. route(route_name)
    raise "error openning web server on route '#{route.name}'"
  end
end

When /^I open web server via the(?: "(.+?)")? route$/ do |route_name|
  @result = CucuShift::Http.get(url: "http://" + route(route_name).dns(by: user))
end
When /^I open web server via the(?: "(.+?)")? url$/ do |url|
  @result = CucuShift::Http.get(url: url)
end

When /^I download a file from "(.+?)"$/ do |url|
  @result = CucuShift::Http.get(url: url)
  if @result[:success]
    file_name = File.basename(URI.parse(url).path)
    File.write(file_name, @result[:response])
    @result[:file_name] = file_name
    @result[:abs_path] = File.absolute_path(file_name)
  else
    raise "Failed to download file from #{url} with HTTP status #{@result[:exitstatus]}"
  end
end

# same as download regular file but here we don't put whole file into memory;
# redirection is also not supported, return status is unreliable
# response headers, cookies, etc. also lost;
# You just get the freakin' big file downloaded without much validation
When /^I download a big file from "(.+?)"$/ do |url|
  file_name = File.basename(URI.parse(url).path)
  File.open(file_name, 'wb') do |file|
    @result = CucuShift::Http.get(url: url) do |chunk|
      file.write chunk
    end
  end
  if @result[:success]
    # File.write(file_name, @result[:response])
    @result[:file_name] = file_name
    @result[:abs_path] = File.absolute_path(file_name)
  else
    raise "Failed to download file from #{url} with HTTP status #{@result[:exitstatus]}"
  end
end

# this step simply delegates to the Http.request method;
# all options are acepted in the form of a YAML or a JSON hash where each
#   option correspond to an option of the said method.
# Example usage:
# When I perform the HTTP request:
#   """
#   :url: <%= env.api_endpoint_url %>/
#   :method: :get
#   :headers:
#     :accept: text/html
#   :max_redirects: 0
#   """
When /^I perform the HTTP request:$/ do |yaml_request|
  @result = CucuShift::Http.request(YAML.load yaml_request)
end

# note that we do not guarantee exact number of invocations, there might be a
#   few more
When /^I perform (\d+) HTTP requests with concurrency (\d+):$/ do |num, concurrency, yaml_request|
  res_queue = Queue.new
  req = YAML.load yaml_request
  req[:quiet] = true unless req.has_key? :quiet
  total_requests = num.to_i
  concurrency = concurrency.to_i
  threads = []

  req_proc = proc do
    begin
      res_queue << CucuShift::Http.request(req)
    end while res_queue.size < total_requests
  end

  started = monotonic_seconds
  concurrency.times { threads << Thread.new(&req_proc) }

  success = wait_for(600) {
    threads.all? { |t| t.join(1) }
  }
  time = monotonic_seconds - started

  unless success
    threads.each { |t| t.terminate }
    raise "concurrent HTTP requests did not complete within timeout"
  end

  results = []
  loop { (results << res_queue.pop(true)) rescue break }

  # TODO: print accumulated time, min, max, std deviation

  @result = results.find {|r| !r[:success]} || results.first
  @result[:response] = results.map {|r| r[:response]}
  @result[:total_time] = results.map {|r| r[:total_time]}
  @result[:min] = @result[:total_time].min
  @result[:max] = @result[:total_time].max
  @result[:accumulated_time] = @result[:total_time].reduce(0) {|s,t| s+t}
  @result[:avg] = @result[:accumulated_time] / results.size.to_f
  @result[:stddev] = Math.sqrt(@result[:total_time].inject(0){|s,t| s+(t-@result[:avg])**2}/(results.size - 1).to_f)
  logger.info "#{results.size} HTTP requests completed in #{'%.3f' % time} seconds, min: #{'%.3f' % @result[:min]}, max: #{'%.3f' % @result[:max]}, avg: #{'%.3f' % @result[:avg]}, std_dev: #{'%.3f' % @result[:stddev]}"
end

When /^I perform (\d+) HTTP GET requests with concurrency (\d+) to: (.+)$/ do |num, concurrency, url|
  step "I perform #{num} HTTP requests with concurrency #{concurrency}:",
    """
    :url: #{url}
    :method: :get
    """
end
