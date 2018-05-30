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

Given /^I update #{QUOTED} slave image for jenkins #{NUMBER} server$/ do |slave_name,jenkins_version|
  le39 = env.version_le("3.9", user: user)

  step 'I store master major version in the clipboard'
  if le39 or jenkins_version == '1'
    step %Q/I perform the :jenkins_update_cloud_image web action with:/, table(%{
      | currentimgval | registry.access.redhat.com/openshift3/jenkins-slave-#{slave_name}-rhel7                          |
      | cloudimage    | <%= product_docker_repo %>openshift3/jenkins-slave-#{slave_name}-rhel7:v<%= cb.master_version %> |
      })
    step 'the step should succeed'
  elsif slave_name == 'maven'
    step %Q/I perform the :jenkins_update_cloud_image web action with:/, table(%{
      | currentimgval | registry.access.redhat.com/openshift3/jenkins-agent-maven-35-rhel7                          |
      | cloudimage    | <%= product_docker_repo %>openshift3/jenkins-agent-maven-35-rhel7:v<%= cb.master_version %> |
      })
    step 'the step should succeed'
  elsif slave_name == 'nodejs'
    step %Q/I perform the :jenkins_update_cloud_image web action with:/, table(%{
      | currentimgval | registry.access.redhat.com/openshift3/jenkins-agent-nodejs-8-rhel7                          |
      | cloudimage    | <%= product_docker_repo %>openshift3/jenkins-agent-nodejs-8-rhel7:v<%= cb.master_version %> |
      })
    step 'the step should succeed'
  end
end
