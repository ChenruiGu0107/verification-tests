#### deployConfig related steps
# Given /^I wait until deployment (?: "(.+)")? matches version "(.+)"$/ do |resource_name, version|
#   ready_timeout = 5 * 60
#   resource_name = resource_name + "-#{version}"
#   rc(resource_name).wait_till_ready(user, ready_timeout)
# end

Given /^I wait until the status of deployment "(.+)" becomes :(.+)$/ do |resource_name, status|
  ready_timeout = 10 * 60
  dc(resource_name).wait_till_status(status.to_sym, user, ready_timeout)
end
