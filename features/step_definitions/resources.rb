# This step shouldn't be called by in scenarios directly. It is only to help
# other steps to recreate cluster resources. That's why a special cookie
# needs to be set for it to be executable.
# Rational is that recreating cluster resources would usually require some
# verification that they are working properly. We can't predict what each
# type will require. Thus extracting common code here and leave resource type
# specific steps handle verification.
Given /^hidden recreate cluster resource after scenario$/ do
  ensure_destructive_tagged

  unless cb.cluster_resource_to_recreate
    raise "please don't use this step directly from scenario"
  end

  _resource = cb.cluster_resource_to_recreate
  cb.cluster_resource_to_recreate = nil

  _admin = admin
  _resource_struct = _resource.raw_resource(user: _admin).freeze

  teardown_add {
    _resource.ensure_deleted
    res = _resource.class.create(by: _admin,
                                 spec: _raw_resource)
    if res[:success]
      cache_resources res[:resource]
    else
      raise "failed to create #{_resource.class}: #{res[:response]}"
    end
  }
end
