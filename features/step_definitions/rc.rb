### replicationController related steps 

# to reliably wait for all the replicas to be come ready, we do
# 'oc get rc <rc_name>' and wait until the spec['replicas'] == status['replicas'] 
Given /^I wait until replicationController(?: "(.+)")? with (\d+) replicas is ready$/ do |rc_name, num|
  ready_timeout = 15 * 60 
  num_of_replicas = num.to_i
  rc(rc_name).wait_till_ready(user, ready_timeout)
end

