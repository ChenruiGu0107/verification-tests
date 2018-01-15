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

Given /^the #{QUOTED} (\w+) is recreated( by admin)? in the#{OPT_QUOTED} project after scenario$/ do |resource_name, resource_type, by_admin, project_name|
  if by_admin
    ensure_admin_tagged
    _user = admin
  else
    _user = user
  end
  _resource = resource(resource_name, resource_type, project_name: project_name)
  unless CucuShift::ProjectResource > _resource.class
    raise "step only supports project resources, but #{_resource.class} is not"
  end

  _raw_resource = _resource.raw_resource(user: _user)
  teardown_add {
    _resource.ensure_deleted(user: _user)
    res = _resource.class.create(by: _user,
                                 project: _resource.project,
                                 spec: _raw_resource)
    if res[:success]
      cache_resources res[:resource]
    else
      raise "failed to create #{_resource.class}: #{res[:response]}"
    end
  }
end

# as resource you need to use a string that exists as a resource method in World
Given /^(I|admin) checks? that the #{QUOTED} (\w+) exists(?: in the#{OPT_QUOTED} project)?$/ do |who, name, resource_type, namespace|
  _user = who == "admin" ? admin : user

  resource = resource(name, resource_type, project_name: namespace)
  resource.default_user = _user

  resource.get_checked
  cache_resources resource
end

Given /^(I|admin) checks? that there are no (\w+)(?: in the#{OPT_QUOTED} project)?$/ do |who, resource_type, namespace|
  _user = who == "admin" ? admin : user

  clazz = resource_class(resource_type)
  if CucuShift::ProjectResource > clazz
    list = clazz.list(user: _user, project: project(namespace))
  else
    list = clazz.list(user: _user)
  end

  unless list.empty?
    raise "found resources: #{list.map(&:name).join(', ')}"
  end
end

# tries to delete resource if it exists and make sure it disappears
# example: I ensure "hello-openshift" pod is deleted
Given /^(I|admin) ensures? #{QUOTED} (\w+) is deleted(?: from the#{OPT_QUOTED} project)?( after scenario)?$/ do |by, name, type, project_name, after|
  _user = by == "admin" ? admin : user
  _resource = resource(name, type, project_name: project_name)
  _seconds = 300
  p = proc {
    @result = _resource.ensure_deleted(user: _user, wait: _seconds)
  }

  if after
    teardown_add p
  else
    p.call
  end
end

# example: I wait for the "hello-pod" pod to appear up to 42 seconds
Given /^(I|admin) waits? for the #{QUOTED} (\w+) to appear(?: in the#{OPT_QUOTED} project)?(?: up to (\d+) seconds)?$/ do |by, name, type, project_name, timeout|
  _user = by == "admin" ? admin : user
  _resource = resource(name, type, project_name: project_name)
  _resource.default_user = _user
  timeout = timeout ? timeout.to_i : 60

  @result = _resource.wait_to_appear(_user, timeout)
  unless @result[:success]
    raise %Q{#{type} "#{name}" did not appear within timeout}
  end
  cache_resources _resource
end

Given /^the( admin)? (\w+) named #{QUOTED} does not exist(?: in the#{OPT_QUOTED} project)?$/ do |who, resource_type, resource_name, project_name|
  _user = who ? admin : user
  _resource = resource(resource_name, resource_type, project_name: project_name)
  _seconds = 60

  if _resource.exists?(user: _user)
    raise "#{resource_type} names #{resource_name} exists"
  end
end

# When applying "oc delete" on one resource, the resource may take some time to
# terminate, so use this step to wait for its dispapearing.
Given /^I wait for the resource "(.+)" named "(.+)" to disappear(?: within (\d+) seconds)?$/ do |resource_type, resource_name, timeout|
  opts = {resource_name: resource_name, resource: resource_type}
  res = {}
  # just put a timeout so we don't hang there indefintely
  timeout = timeout ? timeout.to_i : 15 * 60
  # TODO: update to use the new World#resource method
  success = wait_for(timeout) {
    res = user.cli_exec(:get, **opts)
    case res[:response]
    # the resource has terminated which means we are done waiting.
    when /cannot get project/, /not found/, /No resources found/
      break true
    end
  }
  res[:success] = success
  @result  = res
  unless @result[:success]
    logger.error(@result[:response])
    raise "#{resource_name} #{resource_type} did not terminate"
  end
end
