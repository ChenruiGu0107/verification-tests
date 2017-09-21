require 'yaml'

# will create a StorageClass with a random name and updating any requested path within
#   the object hash with the given value e.g.
# | ["metadata"]["name"] | sc-<%= project.name %> |
When /^admin creates a StorageClass from "([^"]*)" where:$/ do |location, table|
  ensure_admin_tagged

  if location.include? '://'
    step %Q/I download a file from "#{location}"/
    sc_hash = YAML.load @result[:response]
  else
    sc_hash = YAML.load_file location
  end

  # use random name to avoid interference
  sc_hash["metadata"]["name"] = rand_str(5, :dns952)
  if sc_hash["kind"] != 'StorageClass'
    raise "why do you give me #{sc_hash["kind"]}"
  end

  # starts from 3.6, change apiVersion from v1beta1 to v1
  if env.version_cmp("3.6", user: user) >= 0
    sc_hash["apiVersion"] = "storage.k8s.io/v1"
  else
    sc_hash["apiVersion"] = "storage.k8s.io/v1beta1"
  end

  table.raw.each do |path, value|
    eval "sc_hash#{path} = value" unless path == ''
    # e.g. sc_hash["metadata"]["name"] = "sc_test_name"
  end

  logger.info("Creating StorageClass:\n#{sc_hash.to_yaml}")
  @result = CucuShift::StorageClass.create(by: admin, spec: sc_hash)

  if @result[:success]
    @storageclasses << @result[:resource]

    # register mandatory clean-up
    _sc = @result[:resource]
    _admin = admin
    teardown_add { _sc.ensure_deleted(user: _admin) }
  else
    logger.error(@result[:response])
    raise "failed to create StorageClass from: #{location}"
  end
end

Given(/^I have a StorageClass named "([^"]*)"$/) do | storageclass_name |
  step %Q/I run the :get admin command with:/, table(%{
    | resource      | StorageClass         |
    | resource_name | #{storageclass_name} |
  })

  step %Q/the step should succeed/
end

Given(/^I run commands on the StorageClass "([^"]*)" backing host:$/) do | storageclass_name, table|
  ensure_admin_tagged

  rest_url = storage_class(storageclass_name).rest_url(user: admin)
  hostname = URI.parse(rest_url).host

  opts = conf[:services, :storage_class_host]

  host = CucuShift::SSHAccessibleHost.new(hostname, opts)

  @result = host.exec_admin(*table.raw.flatten)
end

Given(/^default storage class is deleted$/) do
  ensure_admin_tagged
  ensure_destructive_tagged
  if env.version_ge("3.3", user: user)
    _sc = CucuShift::StorageClass.get_matching(user: user) {|sc, sc_hash| sc.default?}.first 
    if _sc
      #Delete default storageclass
      logger.info "Default storage class will delete and be resotored after scenario:\n#{_sc.name}"
      _sc.ensure_deleted(user: admin)
      # Restore storeclass after scenario
      teardown_add {
        @result = StorageClass.create(by: admin, spec: _sc.raw_resource) 
        raise "!!Warning unable to restore default storage class #{_sc.name}!!" unless @result[:success]
      }
    else
      logger.info "There is no default storage class need to delete and restore"
    end
  end
end
