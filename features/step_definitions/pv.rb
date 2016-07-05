require 'yaml'

Given /^I save volume id from PV named "([^"]*)" in the#{OPT_SYM} clipboard$/ do |resource_name, cbname|
  cbname = 'volume' unless cbname
  ensure_admin_tagged
  step %Q/I run the :get admin command with:/, table(%{
    | resource      | pv               |
    | resource_name | #{resource_name} |
    | o             | yaml             |
  })
  step %Q/the step should succeed/
  @result[:parsed] = YAML.load @result[:response]
  case
  when @result[:parsed]['spec']['gcePersistentDisk']
    cb[cbname] = @result[:parsed]['spec']['gcePersistentDisk']['pdName']
  when @result[:parsed]['spec']['awsElasticBlockStore']
    cb[cbname] = @result[:parsed]['spec']['awsElasticBlockStore']['volumeID']
  when @result[:parsed]['spec']['cinder']
    cb[cbname] = @result[:parsed]['spec']['cinder']['volumeID']
  else
    raise "Unknown persistent volume type."
  end
end

Given /^I have a(?: (\d+) GB)? volume and save volume id in the#{OPT_SYM} clipboard$/ do |size, cbname|
  timeout = 60
  size = size ? size.to_i : 1
  cbname = 'volume_id' unless cbname
  ensure_admin_tagged
  unless project.exists?(user: user)
    raise "No project exist"
  end

  cb.dynamic_pvc_name = rand_str(8, :dns)
  step %Q{I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:}, table(%{
    | ["metadata"]["name"]                         | <%= project.name %>-<%= cb.dynamic_pvc_name %> |
    | ["spec"]["resources"]["requests"]["storage"] | #{size}                                        |
    })
  step %Q/the step should succeed/
  step %Q/the "<%= project.name %>-<%= cb.dynamic_pvc_name %>" PVC becomes :bound within #{timeout} seconds/
  step %Q/I save volume id from PV named "<%= pvc.volume_name(user: admin, cached: true) %>" in the :#{cbname} clipboard/
end

Given /^the#{OPT_QUOTED} PV becomes #{SYM}(?: within (\d+) seconds)?$/ do |pv_name, status, timeout|
  timeout = timeout ? timeout.to_i : 30
  @result = pv(pv_name).wait_till_status(status.to_sym, admin, timeout)

  unless @result[:success]
    raise "PV #{pv_name} never reached status: #{status}"
  end
end

Given /^the PVs become #{SYM}(?: within (\d+) seconds) with labels:?$/ do |status, timeout, table|
  timeout = timeout ? timeout.to_i : 30
  @result = pv(pv_name).wait_till_status(status.to_sym, admin, timeout)

  unless @result[:success]
    raise "PV #{pv_name} never reached status: #{status}"
  end
end

Given /^([0-9]+) PVs become #{SYM}(?: within (\d+) seconds)? with labels:$/ do |count, status, timeout, table|
  labels = table.raw.flatten # dimentions irrelevant
  timeout = timeout ? timeout.to_i : 60
  status = status.to_sym
  num = Integer(count)

  @result = CucuShift::PersistentVolume.wait_for_labeled(*labels, count: num,
                       user: admin, seconds: timeout) do |pv, pv_hash|
    pv.status?(user: admin, status: status, cached: true)[:success]
  end

  @pvs.reject! { |pv| @result[:matching].include? pv }
  @pvs.concat @result[:matching]

  if !@result[:success] || @result[:matching].size != num
    logger.error("Wanted #{num} but only got '#{@result[:matching].size}' PVs labeled: #{labels.join(",")}")
    logger.info @result[:response]
    raise "See log, waiting for labeled PVs futile: #{labels.join(',')}"
  end
end

Given /^the#{OPT_QUOTED} PV status is #{SYM}$/ do |pv_name, status|
  @result = pv(pv_name).status?(status: status.to_sym, user: admin)

  unless @result[:success]
    raise "PV #{pv_name} does not have status: #{status}"
  end
end

# will create a PV with a random name and updating any requested path within
#   the object hash with the given value e.g.
# | ["spec"]["nfs"]["server"] | service("nfs-service").ip |
When /^admin creates a PV from "([^"]*)" where:$/ do |location, table|
  ensure_admin_tagged

  if location.include? '://'
    step %Q/I download a file from "#{location}"/
    pv_hash = YAML.load @result[:response]
  else
    pv_hash = YAML.load_file location
  end

  # use random name to avoid interference
  pv_hash["metadata"]["name"] = rand_str(5, :dns952)
  if pv_hash["kind"] != 'PersistentVolume'
    raise "why do you give me #{pv_hash["kind"]}"
  end

  table.raw.each do |path, value|
    eval "pv_hash#{path} = value" unless path == ''
    # e.g. pv_hash["spec"]["nfs"]["server"] = 10.10.10.10
  end

  logger.info("Creating PV:\n#{pv_hash.to_yaml}")
  @result = CucuShift::PersistentVolume.create(by: admin, spec: pv_hash)

  if @result[:success]
    @pvs << @result[:resource]

    # register mandatory clean-up
    _pv = @result[:resource]
    _admin = admin
    teardown_add {
      @result = _pv.delete(by: _admin)
      if !@result[:success] &&
          @result[:response] !~ /persistent.*#{_pv.name}.*not found/i
        raise "could not remove PV: #{_pv.name}"
      end
    }
  else
    logger.error(@result[:response])
    raise "failed to create PV from: #{location}"
  end
end
