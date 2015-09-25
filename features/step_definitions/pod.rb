Given /^a pod becomes ready with labels:$/ do |table|
  labels = table.raw.flatten # dimentions irrelevant
  pod_timeout = 10 * 60
  ready_timeout = 15 * 60

  @result = CucuShift::Pod.wait_for_labeled(*labels, user: user, project: project, seconds: pod_timeout)

  if @result[:matching].empty?
    logger.error("Waiting for labeled pods futile: #{labels.join(",")}")
    raise "See log, waiting for labeled pods futile: #{labels.join(',')}"
  end

  pods_add(*@result[:matching])

  @result = pod.wait_till_ready(user, ready_timeout)

  unless @result[:success]
    logger.error(@result[:response])
    raise "#{pod.name} pod did not become ready"
  end
end

Given /^the pod(?: named "(.+)")? becomes ready$/ do |name|
  ready_timeout = 15 * 60
  @result = pod(name).wait_till_ready(user, ready_timeout)

  unless @result[:success]
    logger.error(@result[:response])
    raise "#{pod.name} pod did not become ready"
  end
end

# for a rc that has multiple pods, oc describe currently doesn't support json/yaml output format, so do 'oc get pod' to get the status of each pod 
Given /^all pods in the project are ready$/ do
  pods = project.pods(by:user)
  logger.info("Number of pods: #{pods[:parsed]['items'].count}")
  pods[:parsed]['items'].each do | pod |
    pod_name = pod['metadata']['name']
    logger.info("POD: #{pod_name}, STATUS: #{pod['status']['conditions']}")
    res = pod(pod_name).wait_till_status([:running, :succeeded, :missing], user)

    unless res[:success]
      raise "pod #{self.pod.name} did not reach expected status"
    end
  end
end


# useful for waiting the deployment pod to die and complete
Given /^I wait for the pod(?: named "(.+)")? to die$/ do |name|
  ready_timeout = 15 * 60
  # Should wait the pod running first
  @result = pod(name).wait_till_ready(user, ready_timeout)
  if @result[:success]
    @result = pod(name).wait_till_not_ready(user, ready_timeout)
  end
  unless @result[:success]
    logger.error(@result[:response])
    raise "#{pod.name} pod did not die"
  end
end

# args can be a table where each cell is a command or an argument, or a
#   multiline string where each line is a command or an argument
When /^I execute on the(?: "(.+?)")? pod:$/ do |pod_name, raw_args|
  if raw_args.respond_to? :raw
    # this is table, we don't mind dimentions used by user
    args = raw_args.raw.flatten
  else
    # multi-line string; useful when piping is needed
    args = raw_args.split("\n").map(&:strip)
  end

  @result = pod(pod_name).exec(*args, as: user)
end
