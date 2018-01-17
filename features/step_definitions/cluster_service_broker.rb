Given /^the #{QUOTED} cluster service broker is recreated$/ do |name|
  _admin = admin
  _csb = cluster_service_broker(name)
  cb.cluster_resource_to_recreate = _csb

  teardown_add {
    success = wait_for(interval: 9) {
      _csb.describe.include? "Successfully fetched catalog entries from broker"
    }
    unless success
      raise "could not see cluster service broker ready, see log"
    end
  }

  step 'hidden recreate cluster resource after scenario'
end
