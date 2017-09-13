require 'yaml'

Given /^the#{OPT_QUOTED} PVC becomes #{SYM}(?: within (\d+) seconds)?$/ do |pvc_name, status, timeout|
  timeout = timeout ? timeout.to_i : 30
  @result = pvc(pvc_name).wait_till_status(status.to_sym, user, timeout)

  unless @result[:success]
    user.cli_exec(:get, resource: "pvc", resource_name: "#{pvc_name}", o: "yaml")
    user.cli_exec(:describe, resource: "pvc", name: "#{pvc_name}")
    raise "PVC #{pvc_name} never reached status: #{status}"
  end
end

Given /^the#{OPT_QUOTED} PVC status is #{SYM}$/ do |pvc_name, status|
  @result = pvc(pvc_name).status?(status: status.to_sym, user: user)

  unless @result[:success]
    user.cli_exec(:get, resource: "pvc", resource_name: "#{pvc_name}", o: "yaml")
    user.cli_exec(:describe, resource: "pvc", name: "#{pvc_name}")
    raise "PVC #{pvc_name} does not have status: #{status}"
  end
end

Given /^([0-9]+) PVCs become #{SYM}(?: within (\d+) seconds)? with labels:$/ do |count, status, timeout, table|
  labels = table.raw.flatten # dimentions irrelevant
  timeout = timeout ? timeout.to_i : 60
  status = status.to_sym
  num = Integer(count)

  @result = CucuShift::PersistentVolumeClaim.wait_for_labeled(*labels,
              project: project, count: num, user: user, seconds: timeout) do |pvc, pvc_hash|
    pvc.status?(user: user, status: status, cached: true)[:success]
  end

  @pvcs.reject! { |pvc| @result[:matching].include? pvc }
  @pvcs.concat @result[:matching]

  if !@result[:success] || @result[:matching].size != num
    logger.error("Wanted #{num} but got '#{@result[:matching].size}' PVCs labeled: #{labels.join(",")}")
    logger.info @result[:response]
    raise "See log, waiting for labeled PVCs futile: #{labels.join(',')}"
  end
end

Given /^the "([^"]*)" PVC becomes bound to the "([^"]*)" PV(?: within (\d+) seconds)?$/ do |pvc_name, pv_name, timeout|
  timeout = timeout ? timeout.to_i : 30

  @result = pvc(pvc_name).wait_till_status(:bound, user, timeout)
  raise "PVC #{pvc_name} never became: bound" unless @result[:success]

  unless pvc(pvc_name).volume_name(user: user, cached: true) == pv_name
    raise "PVC bound to #{pvc(pvc_name).volume_name(cached: true)}"
  end
end

# 1. download file from JSON/YAML URL
# 2. specify specific key/values on different versions
# 3. replace any path with given value from table
# 4. runs `oc create` command over the resulting file
When /^I create pvc (?:over|with) #{QUOTED} replacing paths:$/ do |file, table|
  if file.include? '://'
    step %Q|I download a file from "#{file}"|
    resource_hash = YAML.load(@result[:response])
  else
    resource_hash = YAML.load_file(expand_path(file))
  end

  # version diff
  if env.version_ge("3.6", user: user)
    if !resource_hash["metadata"].to_json.include? "kubernetes.io/storage-class" && !resource_hash["spec"].to_json.include? "storageClassName"
      resource_hash["spec"]["storageClassName"] = ''
    end
  end

  # replace paths from table
  table.raw.each do |path, value|
    eval "resource_hash#{path} = YAML.load value"
    # e.g. resource["spec"]["nfs"]["server"] = 10.10.10.10
    #      resource["spec"]["containers"][0]["name"] = "xyz"
  end
  resource = resource_hash.to_json
  logger.info resource

  @result = user.cli_exec(:create, {f: "-", _stdin: resource})
end
