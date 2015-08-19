When /^I give (.+?) role to (the [a-z]+) user$/ do |role_name, which_user|
  user_name=env.users[word_to_num(which_user)].name
  user.cli_exec(
    :add_role_to_user,
    role: role_name,
    user_name: user_name,
    n: project.name
  )
end

When /^I remove (.+?) role from (the [a-z]+) user$/ do |role_name, which_user|
  user_name=env.users[word_to_num(which_user)].name
  user.cli_exec(
    :remove_role_from_user,
    role: role_name,
    user_name: user_name,
    n: project.name
  )
end

Given /^(the [a-z]+) user is cluster-admin$/ do |which_user|
  user_name=env.users[word_to_num(which_user)].name
  _admin = admin
  @result=_admin.cli_exec(
     :oadm_add_cluster_role_to_user,
     role_name: "cluster-admin",
     user_name: user_name
  )
  if @result[:success]
    teardown_add {
      @res = _admin.cli_exec(
        :oadm_remove_cluster_role_from_user,
        role_name: "cluster-admin",
        user_name: user_name
      )
      raise "could not restore user #{user_name}" unless @res[:success]
    }
  else
    raise "could not give #{user_name} role cluster-admin"
  end
end
