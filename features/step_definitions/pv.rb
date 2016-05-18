require 'yaml'

Given /^the#{OPT_QUOTED} PV becomes #{SYM}(?: within (\d+) seconds)?$/ do |pv_name, status, timeout|
  timeout = timeout ? timeout.to_i : 30
  @result = pv(pv_name).wait_till_status(status.to_sym, admin, timeout)

  unless @result[:success]
    raise "PV #{pv_name} never reached status: #{status}"
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
