When /^I give (.+?) role to (the [a-z]+) user$/ do |role_name, which_user|
   user_name=env.users[word_to_num(which_user)].name
   user.cli_exec(:add_role_to_user, role:role_name,user_name:user_name)
   
end

When /^I revoke (.+?) role from (the [a-z]+) user$/ do |role_name, which_user|
   user_name=env.users[word_to_num(which_user)].name
   user.cli_exec(:remove_role_from_user, role:role_name, user_name:user_name)
end

Given /^(the [a-z]+) user is cluster-admin$/ do |which_user|
   user_name=env.users[word_to_num(which_user)].name
    _admin = admin

    _admin.cli_exec(
       :oadm_policy,
       policy_type: "add-cluster-role-to-user",
       role_name: "cluster-admin",
       user_name: user_name
    )

    teardown_add {
      res = _admin.cli_exec(
        :oadm_policy,
        policy_type: "remove-cluster-role-from-user",
        role_name: "cluster-admin",
        user_name: user_name
      )
      raise "could not restore user #{user_name}" unless res[:success]
    }
end
