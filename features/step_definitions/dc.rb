#### deployConfig related steps
Given /^I wait until deployment config(?: "(.+)")? matches version "(.+)"$/ do |resource_name, version|
  ready_timeout = 5 * 60
 	resource_name = resource_name + "-#{version}"
  rc(resource_name).wait_till_ready(user, ready_timeout)
end

Given /^I wait until the status of deployment config "(.+)"(?: with version (\d+))? becomes :(.+)$/ do |resource_name, version, status|
  ready_timeout = 10 * 60
  if version
  	resource_name = resource_name + "-#{version}"
		rc(resource_name).wait_till_status(status.to_sym, user, ready_timeout)
  else
		dc(resource_name).wait_till_status(status.to_sym, user, ready_timeout)
	end

end
