# you use "second", "third", "default", etc. user
Given /^I switch to(?: the)? ([a-z]+) user$/ do |who|
  user(word_to_num(who))
end

# user full or short service account name, e.g.:
# system:serviceaccount:project_name:acc_name
# acc_name
Given /^I switch to the (.+) service account$/ do |who|
  @user = service_account(who)
end

Given /^I switch to cluster admin pseudo user$/ do
  ensure_admin_tagged
  @user = admin
end

Given /^I create the serviceaccount "([^"]*)"$/ do |name|
  sa = service_account(name)
  @result = sa.create(by: user)

  raise "could not create service account #{name}" unless @result[:success]
end

Given /^I find a bearer token of the(?: (.+?))? service account$/ do |acc|
  service_account(acc).load_bearer_tokens(by: user)
end

Given /^the(?: ([a-z]+))? user has all owned resources cleaned$/ do |who|
  num = who ? word_to_num(who) : nil
  user(num).clean_up_on_load
end

Given /^(I|admin) ensures identity #{QUOTED} is deleted$/ do |by, name|
  _user = by == "admin" ? admin : user
  _resource = identity(name)
  _seconds = 60
  @result = _resource.ensure_deleted(user: _user, wait: _seconds)
end

Given /^I restore user's context after scenario$/ do
  @result = user.cli_exec(:config, subcommand: "current-context")
  raise "could not get current-context" unless @result[:success]

  _current_context = @result[:response]
  _user = user

  teardown_add {
    _user.cli_exec(:config_set_context, name: _current_context)
  }
end
