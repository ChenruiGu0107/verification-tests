# helper step for logging and metrics scenarios

# since the logging and metrics module can be deployed and used in any namespace, this step is used to determine
# under what namespace the logging/metrics module is deployed under by getting all of the projects as admin and
And /^I save the (logging|metrics) project name to the#{OPT_SYM} clipboard$/ do |svc_type, clipboard_name|
  ensure_admin_tagged

  if clipboard_name.nil?
    cb_name = svc_type
  else
    cb_name = clipboard_name
  end
  if svc_type == 'logging'
    expected_dc_name = "logging-kibana"
  else
    expected_dc_name = "hawkular-metrics"
  end
  found_proj = CucuShift::Project.get_matching(user: admin) { |project, project_hash|
    dc(expected_dc_name, project).exists?(user: admin, quiet: true)
  }
  if found_proj.count != 1
    raise ("There are #{found_proj.count} logging services installed in any projects within the system, expected 1")
  else
    cb[cb_name] = found_proj[0].name
  end
end

# helper step that does the following:
# 1. figure out project and route information
Given /^I login to kibana logging web console$/ do
  step %Q/I save the logging project name to the :logging clipboard/
  step %Q/admin save the hostname of route "logging-kibana" in project "<%= cb['logging'] %>" to the :logging_route clipboard/
  step %Q/I have a browser with:/, table(%{
    | rules    | lib/rules/web/images/logging/   |
    | rules    | lib/rules/web/console/base/     |
    | base_url | https://<%= cb.logging_route %> |
    })
  step %Q/I perform the :kibana_login web action with:/, table(%{
    | username   | <%= user.name %>                |
    | password   | <%= user.password %>            |
    | kibana_url | https://<%= cb.logging_route %> |
    })
end
