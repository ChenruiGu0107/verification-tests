#### deployConfig related steps
#
Given /^I wait until deployment config(?: "(.+)")? matches version "(.+)"$/ do |dc_name, version|
  ready_timeout = 15 * 60
  dc(dc_name).wait_till_ready(user, version, ready_timeout)
end

Given /^I wait until the status of depolyment config(?: "(.+)")? with version "(.+)" is :(.+)$/ do |dc_name, version, status|
  ready_timeout = 10 * 60
  dc(dc_name).wait_till_status(status.to_sym, version, user, ready_timeout)
end
