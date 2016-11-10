# step which interact with master-config.yaml file.

Given(/^master config is merged with the following hash:$/) do |yaml_string|
  ensure_admin_tagged

  yaml_hash = YAML.load(yaml_string)
  resource_hash = CucuShift::MasterConfig.as_hash(env)

  CucuShift::Collections.deep_merge!(resource_hash, yaml_hash)
  resource = resource_hash.to_yaml
  logger.info resource
  CucuShift::MasterConfig.backup(env)
  @result = CucuShift::MasterConfig.update(env, resource)

  teardown_add {
    CucuShift::MasterConfig.restore(env)
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

