# steps which interact with master-config.yaml file.

Given /^master config is merged with the following hash:$/ do |yaml_string|
  ensure_admin_tagged
  ensure_destructive_tagged

  yaml_hash = YAML.load(yaml_string)


  env.master_services.each { |service|
    master_config = service.config
    config_hash = master_config.as_hash()
    CucuShift::Collections.deep_merge!(config_hash, yaml_hash)
    config = config_hash.to_yaml
    logger.info config
    master_config.backup()
    @result = master_config.update(config)

    teardown_add {
      master_config.restore()
    }
  }

end

Given /^master config is restored from backup$/ do
  env.master_services.each { |service|
    @result = service.config.restore()
  }
end

#Given(/^admin will download the master config to "(.+?)" file$/) do |file|
#  @result = CucuShift::MasterConfig.raw(env)
#  if @result[:success]
#    file = File.join(localhost.workdir, file)
#    File.write(file, @result[:response])
#  end
#end

#Given(/^admin will update master config from "(.+?)" file$/) do |file|
#  CucuShift::MasterConfig.backup(env)
#  content = File.read(File.expand_path(file))
#  @result = CucuShift::MasterConfig.update(env, content)

#  teardown_add {
#    CucuShift::MasterConfig.restore(env)
#  }
#end

Given /^I store the value of path (.+?) of master config in the#{OPT_SYM} clipboard$/ do |path, cb_name|
  ensure_admin_tagged
  config_hash = env.master_services[0].config.as_hash()
  cb_name ||= "config_value"
  cb[cb_name] = eval "config_hash#{path}"
end

Given /^the master service is restarted on all master nodes$/ do
  ensure_destructive_tagged

  env.master_services.each { |service|
    service.restart_all(raise: true)
  }
end

Given /^I try to restart the master service on all master nodes$/ do
  ensure_destructive_tagged
  results = []

  env.master_services.each { |service|
    results.push(service.restart_all)
  }
  @result = CucuShift::ResultHash.aggregate_results(results)
  # aggregate all the responses from all masters
  @result[:response] = results.map { |r| r[:response] }
  # aggregate all the exit statuses from all masters
  @result[:exitstatus] = results.map { |r| r[:exitstatus] }
end

