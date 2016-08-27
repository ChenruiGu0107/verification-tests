### replicaSet related steps

Given /^I wait until number of replicas match "(\d+)" for replicaSet "(.+)"$/ do |number, rs_name|
ready_timeout = 300
  matched = rs(rs_name).wait_till_replica_count_match(
    user: user,
    seconds: ready_timeout,
    replica_count: number.to_i
  )
  unless matched
    raise "desired replica count not reached within timeout"
  end
end
