Given /^default admin-console route is stored in the#{OPT_SYM} clipboard$/ do | cb_name |
  # save the orignial project name
  org_proj_name = project(generate: false).name rescue nil
  cb_name ||= :console_route
  cb[cb_name] = route('console', service('console',project('openshift-console'))).dns(by: admin)
  project(org_proj_name) if org_proj_name
end

