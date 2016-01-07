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
