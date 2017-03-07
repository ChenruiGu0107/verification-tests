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


# ##  curl
# -H "Authorization: Bearer $USER_TOKEN"
# -H "Hawkular-tenant: $PROJECT"
# -H "Content-Type: application/json"
# -X POST/GET https://hawkular-metrics.$SUBDOMAIN/hawkular/metrics/{gauges|metrics|counters}
### https://hawkular-metrics.0227-ep7.qe.rhcloud.com/hawkular/metrics/metrics
# acceptable parameters are:
# 1. | project_name | name of project |
# 2. | type  | type of metrics you want to query {gauges|metrics|counters} |
# 3. | payload | for POST only, local path or url |
# NOTE: if we agree to use a fixed name for the first part of the metrics URL, then we don't need admin access privilege to run this step.
When /^I perform the (GET|POST) metrics rest request with:$/ do | op_type, table |

  if !env.opts[:admin_cli]
    # for Online/STG/INT, we just get the URL from env
    cb['metrics'] = env.metrics_console_url
  else
    unless cb[:metrics]
      step %Q/I store default router subdomain in the :metrics clipboard/
      cb[:metrics] = 'https://hawkular-metrics.' + cb[:metrics] + '/hawkular/metrics'
    end
  end
  opts = opts_array_to_hash(table.raw)
  supported_metrics_types = %w(gauges metrics counters)
  raise "Unsupported query type '#{opts[:type]}' for metrics, valid types are #{supported_metrics_types}" unless supported_metrics_types.include? opts[:type]
  https_opts = {}
  https_opts[:headers] ||= {}
  https_opts[:headers][:accept] ||= "application/json"
  https_opts[:headers][:content_type] ||= "application/json"
  https_opts[:headers][:hawkular_tenant] ||= opts[:project_name]
  https_opts[:headers][:authorization] ||= "Bearer #{user.get_bearer_token.token}"
  metrics_url = cb.metrics + '/' + opts[:type]

  if op_type == 'POST'
    datastore_url = metrics_url + '/datastore'
    file_name = opts[:payload]
    if %w(http https).include? URI.parse(opts[:payload]).scheme
      # user given a http source as a parameter
      step %Q/I download a file from "#{opts[:payload]}"/
      file_name = @result[:file_name]
    end
    https_opts[:payload] = File.read(expand_path(file_name))
    url = datastore_url + "/raw"
  else
    url = metrics_url
  end

  @result = CucuShift::Http.request(url: url, **https_opts, method: op_type)
end
