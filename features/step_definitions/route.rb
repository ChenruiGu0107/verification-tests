require 'openshift/route'
require 'openshift/service'

# e.g I expose the "myapp" service
When /^I expose(?: the)?(?: "(.+?)")? service$/ do |service_name|
  r = route(service_name, service(service_name))
  @result = r.create(by: user)
end

# get the route information given a project name
Given /^(I|admin) save the hostname of route #{QUOTED} in project #{QUOTED} to the#{OPT_SYM} clipboard$/ do |by, route_name, proj_name, clipboard_name |
  _user = by == "admin" ? admin : user
  ensure_admin_tagged if by == "admin"
  clipboard_name ||= :host_route
  cb_name = clipboard_name.to_sym
  res = _user.cli_exec(:get, resource: 'route', n: proj_name, o: 'yaml')
  if res[:success]
    res[:parsed]['items'].each do | route |
      cb[cb_name] = route['spec']['host'] if route['metadata']['name'] == route_name
    end
  end
  raise "There is no route named '#{route_name}' in project '#{proj_name}'" if cb[cb_name].nil?
end

# add required cluster role (based on master version) to router service account for ingress object
Given /^required cluster roles are added to router service account for ingress$/ do
  step 'cluster role "cluster-reader" is added to the "system:serviceaccount:default:router" service account'
  if env.version_lt("3.6", user: user)
    step 'cluster role "system:service-serving-cert-controller" is added to the "system:serviceaccount:default:router" service account'
  else
    step 'cluster role "system:openshift:controller:service-serving-cert-controller" is added to the "system:serviceaccount:default:router" service account'
  end
end
