require 'yaml'

Given /^the#{OPT_QUOTED} PVC becomes #{SYM}(?: within (\d+) seconds)?$/ do |pvc_name, status, timeout|
  timeout = timeout ? timeout.to_i : 30
  @result = pvc(pvc_name).wait_till_status(status.to_sym, user, timeout)

  unless @result[:success]
    raise "PVC #{pvc_name} never reached status: #{status}"
  end
end

Given /^([0-9]+) PVCs become #{SYM}(?: within (\d+) seconds)? with labels:$/ do |count, status, timeout, table|
  labels = table.raw.flatten # dimentions irrelevant
  appear_timeout = 30
  status_timeout = timeout ? timeout.to_i : 60
  status = status.to_sym
  num = Integer(count)

  @result = CucuShift::PersistentVolumeClaim.wait_for_labeled(*labels,
              project: project, count: num, user: user, seconds: appear_timeout)

  if !@result[:success] || @result[:matching].size != num
    logger.error("Wanted #{num} but only got '#{@result[:matching].size}' PVCs labeled: #{labels.join(",")}")
    raise "See log, waiting for labeled PVs futile: #{labels.join(',')}"
  end

  @pvcs.reject! { |pvc| @result[:matching].include? pvc }
  @pvcs.concat @result[:matching]

  # keep last waiting @result as the @result for knowing how pvc failed
  @result[:matching].each do |pvc|
    # TODO make status_timeout be a global timeout not per PV
    @result = pvc.wait_till_status(status, user, status_timeout)

    unless @result[:success]
      raise "pvc #{pvc.name} did not reach expected status"
    end
  end
end


