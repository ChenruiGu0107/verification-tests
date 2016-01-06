Given /^a pod becomes ready with labels:$/ do |table|
  labels = table.raw.flatten # dimentions irrelevant
  pod_timeout = 10 * 60
  ready_timeout = 15 * 60

  @result = CucuShift::Pod.wait_for_labeled(*labels, user: user, project: project, seconds: pod_timeout)

  if @result[:matching].empty?
    logger.error("Waiting for labeled pods futile: #{labels.join(",")}")
    raise "See log, waiting for labeled pods futile: #{labels.join(',')}"
  end

  cache_pods(*@result[:matching])

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

Given /^the pod(?: named "(.+)")? status becomes :([^\s]*?)$/ do |name, status|
  status_timeout = 15 * 60
  @result = pod(name).wait_till_status(status, user, status_timeout)

  unless @result[:success]
    logger.error(@result[:response])
    raise "#{pod.name} pod did not become #{status}"
  end
end

# for a rc that has multiple pods, oc describe currently doesn't support json/yaml output format, so do 'oc get pod' to get the status of each pod
Given /^all pods in the project are ready$/ do
  pods = project.pods(by:user)
  logger.info("Number of pods: #{pods[:parsed]['items'].count}")
  pods[:parsed]['items'].each do | pod |
    pod_name = pod['metadata']['name']
    logger.info("POD: #{pod_name}, STATUS: #{pod['status']['conditions']}")
    res = pod(pod_name).wait_till_status(CucuShift::Pod::SUCCESS_STATUSES , user)

    unless res[:success]
      raise "pod #{self.pod.name} did not reach expected status"
    end
  end
end

Given /^([0-9]+) pods become ready with labels:$/ do |count, table|
  labels = table.raw.flatten # dimentions irrelevant
  pod_timeout = 10 * 60
  ready_timeout = 15 * 60
  num = Integer(count)

  @result = CucuShift::Pod.wait_for_labeled(*labels, count: num,
                       user: user, project: project, seconds: pod_timeout)

  if !@result[:success] || @result[:matching].size < num
    logger.error("Wanted #{num} but only got #{@result[:matching].size} pods labeled: #{labels.join(",")}")
    raise "See log, waiting for labeled pods futile: #{labels.join(',')}"
  end

  cache_pods(*@result[:matching])

  # keep last waiting @result as the @result for knowing how pod failed
  @result[:matching].each do |pod|
    @result = pod.wait_till_status(CucuShift::Pod::SUCCESS_STATUSES , user)

    unless @result[:success]
      raise "pod #{pod.name} did not reach expected status"
    end
  end
end

# useful for waiting the deployment pod to die and complete
# @param the 'regardless...' parameter will check the mere existence of a pod
# irrespective of whether or not it exists at the current moment.
Given /^I wait for the pod(?: named "(.+)")? to die( regardless of current status)?$/ do |name, current_status|
  ready_timeout = 15 * 60
  @result = pod(name).wait_till_not_ready(user, ready_timeout) unless current_status
  if current_status || @result[:success]
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

# wrapper around  oc logs, keep executing the command until we have an non-empty response
# There are few occassion that the 'oc logs' cmd returned empty response
#   this step should address those situations
Given /^I collect the deployment log for pod "(.+)" until it disappears$/ do |pod_name|
  opts = {resource_name: pod_name}
  res_cache = {}
  res = {}
  seconds = 15 * 60   # just put a timeout so we don't hang there indefintely
  success = wait_for(seconds) {
    res = user.cli_exec(:logs, **opts)
    if res[:response].include? 'not found'
      # the deploy pod has disappeared which mean we are done waiting.
      true
    else #
      res_cache = res
      false
    end
  }
  res_cache[:success] = success
  @result  = res_cache
end
