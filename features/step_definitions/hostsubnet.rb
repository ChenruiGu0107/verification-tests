Given /^hostsubnet #{QUOTED} is restored after scenario$/ do |subnet|
  ensure_destructive_tagged

  @result = admin.cli_exec(:get, resource: 'hostsubnet', resource_name: subnet, o: 'yaml')
  if @result[:success]
    orig_hostsubnet = @result[:response]
    logger.info "hostsubnet '#{subnet}' will be restored after scenario"
  else
    raise "could not get hostsubnet: '#{subnet}'"
  end

  _admin = admin
  teardown_add {
    admin.cli_exec(
      :delete,
      object_type: :hostsubnet,
      object_name_or_id: subnet
    )
    # we don't check result here, we don't care if it existed or not
    # we care if it will be created successfully below

    @result = _admin.cli_exec(
      :create,                                                                                                                                                                                
      f: "-",
      _stdin: orig_hostsubnet
    )
    raise "cannot restore #{subnet}" unless @result[:success]
  }
end
