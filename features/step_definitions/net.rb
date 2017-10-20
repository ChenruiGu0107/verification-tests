Given /^HTTP cookies from result are used in further request$/ do
  if @result[:cookies]
    cb.http_cookies = @result[:cookies]
  else
    raise "no cookies in result"
  end
end

Given /^HTTP cookies from result are saved in the #{SYM} clipboard$/ do |cbname|
  if @result[:cookies]
    cb[cbname] = @result[:cookies]
  else
    raise "no cookies in result"
  end
end

Given /^HTTP cookies from the #{SYM} clipboard are used in further request$/ do |cbname|
  if cb[cbname]
    cb.http_cookies = cb[cbname]
  else
    raise "no cookies in the :#{cbname} clipboard"
  end
end

Then /^a( secure)? web server should be available via the(?: "(.+?)")? route$/ do |secure, route_name|
  proto = secure ? "https" : "http"
  @result = route(route_name).http_get(by: user, proto: proto,
                                       cookies: cb.http_cookies)
  unless @result[:success]
    logger.error(@result[:response])
    # you may notice now `route` refers to last called route,
    #   i.e. route(route_name)
    raise "error openning web server on route '#{route.name}'"
  end
end

Given /^I wait(?: up to ([0-9]+) seconds)? for a( secure)? web server to become available via the(?: "(.+?)")? route$/ do |seconds, secure, route_name|
  proto = secure ? "https" : "http"
  seconds = seconds.to_i unless seconds.nil?
  @result = route(route_name).wait_http_accessible(by: user, timeout: seconds,
                                                   proto: proto,
                                                   cookies: cb.http_cookies)

  unless @result[:success]
    logger.error(@result[:response])
    # you may notice now `route` refers to last called route,
    #   i.e. route(route_name)
    raise "error openning web server on route '#{route.name}'"
  end
end

When /^I open( secure)? web server via the(?: "(.+?)")? route$/ do |secure, route_name|
  proto = secure ? "https" : "http"
  @result = route(route_name).http_get(by: user, proto: proto,
                                       cookies: cb.http_cookies)
end

When /^I open web server via the(?: "(.+?)")? url$/ do |url|
  @result = CucuShift::Http.get(url: url, cookies: cb.http_cookies)
end

Given /^I download a file from "(.+?)"(?: into the "(.+?)" dir)?$/ do |url, dl_path|
  @result = CucuShift::Http.get(url: url, cookies: cb.http_cookies)
  if @result[:success]
    if dl_path
      file_name = File.join(dl_path, File.basename(URI.parse(url).path))
    else
      file_name = File.basename(URI.parse(url).path)
    end
    File.open(file_name, 'wb') { |f|
      f.write(@result[:response])
    }
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
# TODO: fix! see https://github.com/rest-client/rest-client/issues/452
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
  opts = YAML.load yaml_request
  if Symbol == opts[:cookies]
    opts[:cookies] = cb[opts[:cookies]]
  end
  @result = CucuShift::Http.request(opts)
end

# note that we do not guarantee exact number of invocations, there might be a
#   few more
When /^I perform (\d+) HTTP requests with concurrency (\d+):$/ do |num, concurrency, yaml_request|
  opts = YAML.load yaml_request
  opts[:count] = num.to_i
  opts[:concurrency] = concurrency.to_i
  @result = CucuShift::Http.flood_count(**opts)
end

When /^I perform (\d+) HTTP GET requests with concurrency (\d+) to: (.+)$/ do |num, concurrency, url|
  step "I perform #{num} HTTP requests with concurrency #{concurrency}:",
    """
    :url: #{url}
    :method: :get
    """
end

# Example: I wait for the "www.ruby-lang.org:80" TCP server to start accepting connections
When /^I wait for the #{QUOTED} TCP server to start accepting connections$/ do |hostport|
  seconds = 60

  # TODO: IPv6 support
  host, garbage, port = hostport.rpartition(":")
  port = Integer(port)

  @result = CucuShift::Common::Net.wait_for_tcp(host: host,
                                                port: port,
                                                timeout: seconds)

  stats = @result[:props][:stats]
  logger.info "after #{stats[:seconds]} seconds and #{stats[:iterations]} " <<
    "iterations, #{hostport} is: " <<
    "#{@result[:success] ? "accessible" : @result[:error].inspect}"
end
