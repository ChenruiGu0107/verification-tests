# Presently this step just runs `apb` locally and some commands my require
#   docker daemon running locally. Thus it is not portable. But it can help
#   on specially crafted jenkins slaves and locally.
# To make it portable going forward, step might be changed in the future to
#   execute on a remote host so try to NOT rely on files present locally.
Given /^I run the #{SYM} apb command with:$/ do |cmd, table|
  cmd_key = cmd.to_sym
  params = table.raw
  params = params == [[]] ? [] : opts_array_process(table.raw)

  @apb_executor ||= CucuShift::RulesCommandExecutor.new(
    host: CucuShift::Host.localhost,
    rules: "#{CucuShift::HOME}/lib/rules/apb.yaml"
  )

  @result = @apb_executor.run(cmd_key, params)
end

Given /^I run the #{SYM} apb command:$/ do |cmd|
  step "I run the #{cmd} apb command with:", table([[]])
end
