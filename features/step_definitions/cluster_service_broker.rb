Given /^the #{QUOTED} cluster service broker is recreated$/ do |name|
  _admin = admin
  _csb = cluster_service_broker(name)
  cb.cluster_resource_to_recreate = _csb

  teardown_add {
    success = wait_for(60, interval: 9) {
      _csb.describe[:response].include? "Successfully fetched catalog entries from broker"
    }
    unless success
      raise "could not see cluster service broker ready, see log"
    end
  }

  step 'hidden recreate cluster resource after scenario'
end

Given /^I save the first service broker registry prefix to#{OPT_SYM} clipboard$/ do |cb_name|
  ensure_admin_tagged
  cb_name ||= :reg_prefix
  org_project = project(generate: false) rescue nil
  project('openshift-ansible-service-broker')
  cb[cb_name] = YAML.load(config_map('broker-config').value_of('broker-config', user: admin))['registry'].first['name']
  project(org_project)
end

