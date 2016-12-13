#Use this step definition file to create image-specific steps

#This empty step will be removed once we can start updating the existing
#jenkins cases to use the new OAuth method; this way there is no
#'missing step' error here.
Given /^I save the jenkins password of dc #{QUOTED} into the#{OPT_SYM} clipboard$/ do
end

Given /^I have a( ephemeral| persistent)? jenkins application$/ do |type|
  if type.nil?
    type = "ephemeral"
  else
    type = type.strip
  end

  #Determine the server version for later jenkins template manipulation
  lt34 = env.version_lt("3.4", user: user)


  #Check if 3.4. if so, use oauth (only present in 3.4), else, use standard login
  #Note: upon app creation, new-app may show "Enable OAuth in Jenkins=true", as
  #only the env var is changed during the substitution below.
  template = "https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-#{type}-template.json"

  if lt34 || !user.password?
    step %Q/I run the :new_app client command with:/, table(%{
      | file | #{template}               |
      | env  | ENABLE_OAUTH=false        |
      | env  | JENKINS_PASSWORD=password |
      })
    step 'the step should succeed'
  else
    step %Q/I run the :new_app client command with:/, table(%{
      | file | #{template} |
      })
    step 'the step should succeed'
  end
end

Given /^I log in to jenkins$/ do
  #Determine the server version for later jenkins template manipulation
  lt34 = env.version_lt("3.4", user: user)

  #Check if 3.4 and not online environment. if so, use oauth
  if !lt34 && user.password?
    step %Q/I perform the :jenkins_oauth_login web action with:/, table(%{
      | username | <%= user.name %>     |
      | password | <%= user.password %> |
      })
  #If less than 3.4, use passwd auth (admin/password). The auth
  #version is set in the create step above.
  else
    step %Q/I perform the :jenkins_standard_login web action with:/, table(%{
      | username | admin    |
      | password | password |
      })
  end
end
