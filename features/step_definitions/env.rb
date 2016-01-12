# helper step to get default router subdomain
# will create a dummy route to obtain that
# somehow hacky in all regardsm hope we obtain a better mechanism after some time
Given /^I store default router subdomain in the#{OPT_SYM} clipboard$/ do |cb_name|
  cb_name = 'tmp' unless cb_name
  _user = user(0, switch: false)
  clean_project = false
  projects = _user.projects

  ## use existing domain or create a new one
  if projects.empty?
    project.create(by: _user)
    _project = project
    clean_project = true
  else
    _project = projects.last
  end

  ## create a dummy service
  dummy_service_get = CucuShift::Http.get(url: "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_pod.json")
  raise "cannot download service" unless dummy_service_get[:success]
  dummy_service = YAML.load(dummy_service_get[:response])
  dummy_service["items"][1]["subsets"][0]["addresses"][0]["ip"] = "192.168.0.1"

  dummy_service_c = _user.cli_exec(:create,
                                   f: '-',
                                   _stdin: dummy_service.to_yaml,
                                   n: _project.name)
  raise "cannot create service" unless dummy_service_c[:success]

  ## create a dummy route
  route_c = _user.cli_exec(:expose, n: _project.name,
                           resource: "service",
                           resource_name: 'selector-less-service')
  raise "cannot create route" unless route_c[:success]

  cb[cb_name] = route(
    "selector-less-service",
    service('selector-less-service', _project)
  ).dns(
    by: _user
  ).split('.',2)[1]
  Kernel.puts cb[cb_name]

  ## clean-up our mess
  if clean_project
    project.delete(by: _user)
  else
    raise unless route.delete(by: _user)[:success]
    raise unless service.delete(by: _user)[:success]
  end
end
