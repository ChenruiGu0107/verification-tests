#Use this step definition file to create image-specific steps

#This empty step will be removed once we can start updating the existing
#jenkins cases to use the new OAuth method; this way there is no
#'missing step' error here.
Given /^I save the jenkins password of dc #{QUOTED} into the#{OPT_SYM} clipboard$/ do
end

Given /^I have an?( ephemeral| persistent| custom)? jenkins v#{NUMBER} application(?: from #{QUOTED})?$/ do |type, version, cust_templ|
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
  source = ""
  if type == "custom"
    source = "| file | #{cust_templ} |"
  else
    source = "| template | jenkins-#{type} |"
  end

  if lt34 || !user.password?
    step %Q/I run the :new_app client command with:/, table(%{
      #{source}
      | p | ENABLE_OAUTH=false                          |
      | p | JENKINS_IMAGE_STREAM_TAG=jenkins:#{version} |
      })
    step 'the step should succeed'
  else
    step %Q/I run the :new_app client command with:/, table(%{
      #{source}
      | p | JENKINS_IMAGE_STREAM_TAG=jenkins:#{version} |
      })
    step 'the step should succeed'
  end
end

Given /^I log in to jenkins$/ do
  #Determine the server version for later jenkins template manipulation
  lt34 = env.version_lt("3.4", user: user)

  # On v3.4 and above, if we can login to OpenShift via password, then
  #   we can use SSO login.
  # On 3.3 and earlier, or if we only know user token, then we must use
  #   non-SSO login.
  # Installation step also installs based on this.
  if !lt34 && user.password?
    step %Q/I perform the :jenkins_oauth_login web action with:/, table(%{
      | username | <%= user.name %>     |
      | password | <%= user.password %> |
      })
  else
    step %Q/I perform the :jenkins_standard_login web action with:/, table(%{
      | username | admin    |
      | password | password |
      })
  end
end
