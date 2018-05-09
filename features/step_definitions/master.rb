# steps which interact with master-config.yaml file.

Given /^master config is merged with the following hash:$/ do |yaml_string|
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

Given /^the value with path #{QUOTED} in master config is stored into the#{OPT_SYM} clipboard$/ do |path, cb_name|
  ensure_admin_tagged
  config_hash = env.master_services[0].config.as_hash()
  cb_name ||= "config_value"
  cb[cb_name] = eval "config_hash#{path}"
end

Given /^the master service is restarted on all master nodes( after scenario)?$/ do |after|
  ensure_destructive_tagged

  _master_services = env.master_services
  p = proc {
    _master_services.each { |service|
      service.restart(raise: true)
    }
  }

  if after
    teardown_add p
  else
    p.call
  end
end

Given /^I try to restart the master service on all master nodes$/ do
  ensure_destructive_tagged
  results = []

  env.master_services.each { |service|
    results.push(service.restart)
  }
  @result = CucuShift::ResultHash.aggregate_results(results)
end

Given /^I use the first master host$/ do
  ensure_admin_tagged
  @host = env.master_hosts.first
end

Given /^I run commands on all masters:$/ do |table|
  ensure_admin_tagged
  @result = CucuShift::ResultHash.aggregate_results env.master_hosts.map { |host|
    host.exec_admin(table.raw.flatten)
  }
end

Given /^the master is operational$/ do
  ensure_admin_tagged
  success = wait_for(60) {
    admin.cli_exec(:get, resource_name: "default", resource: "project")[:success]
  }
  raise "Timed out waiting for master to become functional." unless success
end

Given /^the etcd version is stored in the#{OPT_SYM} clipboard$/ do |cb_name|
  ensure_admin_tagged
  cb_name ||= :etcd_version
  @result = env.master_hosts.first.exec("openshift version")
  etcd_version = @result[:response].match(/etcd (.+)$/)[1]
  raise "Can not retrieve the etcd version" if etcd_version.nil?
  cb[cb_name] = etcd_version
end

Given /^the #{QUOTED} path is( recursively)? removed on all masters after scenario$/ do |path, recursively|
  @result = env.master_hosts.reverse_each { |host|
    @host = host
    step %{the "#{path}" path is#{recursively} removed on the host after scenario}
  }
end
