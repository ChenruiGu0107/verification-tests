# DeploymentConfig support steps

Given /^a deploymentConfig becomes ready with labels:$/ do |table|
  labels = table.raw.flatten # dimentions irrelevant
  dc_timeout = 10 * 60
  ready_timeout = 15 * 60

  @result = CucuShift::DeploymentConfig.wait_for_labeled(*labels, user: user, project: project, seconds: dc_timeout)

  if @result[:matching].empty?
    raise "See log, waiting for labeled dcs futile: #{labels.join(',')}"
  end

  cache_resources(*@result[:matching])
  @result = dc.wait_till_ready(user, ready_timeout)

  unless @result[:success]
    logger.error(@result[:response])
    raise "#{dc.name} deployment_config did not become ready"
  end
end
