# helper step to get default router subdomain
# will create a dummy route to obtain that
# somehow hacky in all regardsm hope we obtain a better mechanism after some time
Given /^I store default router subdomain in the#{OPT_SYM} clipboard$/ do |cb_name|
  raise "get router info as regular user" if CucuShift::ClusterAdmin === user

  cb_name = 'tmp' unless cb_name
  cb[cb_name] = env.router_default_subdomain(user: user,
                                             project: project(generate: false))
  logger.info cb[cb_name]
end

Given /^I store default router IPs in the#{OPT_SYM} clipboard$/ do |cb_name|
  raise "get router info as regular user" if CucuShift::ClusterAdmin === user

  cb_name = 'ips' unless cb_name
  cb[cb_name] = env.router_ips(user: user, project: project(generate: false))
  logger.info cb[cb_name]
end

Given /^default (docker-registry|router) replica count is stored in the#{OPT_SYM} clipboard$/ do |resource ,cb_name|
  ensure_admin_tagged

  cb_name = 'replicas' unless cb_name
  _dc = dc(resource, project("default", switch: false))

  cb[cb_name] = _dc.replicas(user: admin)
  logger.info "default #{resource} has replica count of: #{cb[cb_name]}"
end

Given /^I store master (major|image)? version in the#{OPT_SYM} clipboard$/ do |type, cb_name|
  ensure_admin_tagged

  hosts = step "I select a random node's host"
  res = host.exec_admin("docker images")

  cb_name = 'master_version' unless cb_name
  if type == "image"
    cb[cb_name] = res[:response].match(/\w*[origin|ose]-pod\s+(v\d+(?:\.\d+){2,3})/).captures[0]
  elsif type == "major"
    cb[cb_name] = res[:response].match(/\w*[origin|ose]-pod\s+v(\d+.\d+.\d+)/).captures[0]
  else
    raise "unexpected master version type #{type}"
  end

  # for origin, return the :latest as image tag version
  if cb[cb_name].start_with?('1')
    cb[cb_name] = "latest"
  end

  logger.info "Master Version: " + cb[cb_name]
end

# compares environment version to given version string;
# only major and minor version is compared, i.e. "3.3" === "3.3.7";
# Origin style versions (e.g. 1.x) can be compared properly to OCP style
#   versions (e.g. 3.x); Such that "3.4" === "1.4";
# Example: Given the master version >= "3.4"
Given /^the master version ([<>=]=?) #{QUOTED}$/ do |op, ver|
  unless env.version_cmp(ver, user: user).send(op.to_sym, 0)
    raise "master version not #{op} #{ver}"
  end
end

