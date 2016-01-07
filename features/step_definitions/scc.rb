# creates a SCC policy and registers clean-up to remove it after scenario
Given /^the following scc policy is created: (.+)$/ do |policy|
  ensure_admin_tagged

  if policy.include? '://'
    step %Q{I download a file from "#{policy}"}
    path = @result[:abs_path]
  else
    path = policy
  end

  raise "no policy template found: #{path}" unless File.exist?(path)

  ## figure out policy name for clean-up
  policy_name = YAML.load_file(path)["metadata"]["name"]
  raise "no policy name in template" unless policy_name

  @result = admin.cli_exec(:create, f: path)
  if @result[:success]
    _admin = admin
    teardown_add {
      @result = _admin.cli_exec(
        :delete,
        object_type: :scc,
        object_name_or_id: policy_name
      )
      raise "cannot remove policy #{policy_name}" unless @result[:success]
    }
  else
    raise "unable to set scc policy #{path}, see log"
  end
end

# setup tier_down to restore scc after scenario end;
Given /^scc policy #{QUOTED} is restored after scenario$/ do |policy|
  ensure_admin_tagged

  @result = admin.cli_exec(:get, resource: 'scc', resource_name: policy, o: 'yaml')
  if @result[:success]
    orig_policy = @result[:response]
    logger.info "SCC restore tear_down registered:\n#{orig_policy}"
  else
    raise "could not get scc: #{policy}"
  end

  _admin = admin
  teardown_add {
    admin.cli_exec(
      :delete,
      object_type: :scc,
      object_name_or_id: policy
    )
    # we don't check result here, we don't care if it existed or not
    # we care if it will be created successfully below

    @result = _admin.cli_exec(
      :create,
      f: "-",
      _stdin: orig_policy
    )
    raise "cannot restore #{policy}" unless @result[:success]
  }
end
