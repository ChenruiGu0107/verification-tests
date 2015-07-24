## Put here steps that are mostly cli specific, e.g new-app

# there is no such thing as app in OpenShift but there is a command new-app
#   in the cli that logically represents an app - creating/deploying different
#   pods, services, etc.; There is a discussion coing on to rename and refactor
#   the funcitonality. Not sure that goes anywhere but we could adapt this
#   step for backward compatibility if needed.
Given /^I create a new application with:$/ do |table|
  step 'I run the :new_app client command with:', table
end
