### Deployment related steps

Given /^I wait until number of replicas match "(\d+)" for deployment "(.+)"$/ do |number, d_name|
  ready_timeout = 300
  matched = deployment(d_name).wait_till_replica_count_match(
    user: user,
    seconds: ready_timeout,
    replica_count: number.to_i
  )
  unless matched
    raise "desired replica count not reached within timeout"
  end
end
