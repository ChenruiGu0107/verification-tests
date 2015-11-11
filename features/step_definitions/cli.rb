## Put here steps that are mostly cli specific, e.g new-app

# there is no such thing as app in OpenShift but there is a command new-app
#   in the cli that logically represents an app - creating/deploying different
#   pods, services, etc.; There is a discussion coing on to rename and refactor
#   the funcitonality. Not sure that goes anywhere but we could adapt this
#   step for backward compatibility if needed.
Given /^I create a new application with:$/ do |table|
  step 'I run the :new_app client command with:', table
end

When /^I run oc create( as admin)? over ERB URL: #{HTTP_URL}$/ do |admin, url|
  step %Q|I download a file from "#{url}"|

  # overwrite with ERB loaded content
  loaded = ERB.new(File.read(@result[:abs_path])).result binding
  File.write(@result[:abs_path], loaded)

  if admin
    #ensure_admin_tagged
    @result = self.admin.cli_exec(:create, {f: @result[:abs_path]})
  else
    @result = user.cli_exec(:create, {f: @result[:abs_path]})
  end
end
