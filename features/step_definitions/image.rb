#Use this step definition file to create image-specific steps

#@author cryan@redhat.com
#@params dc_name string The name of the dc which contains the jenkins image
#@params OPT_SYM symbol The (optional) name of the password clipboard
#@notes This is used to save the randomly generated jenkins image password
Given /^I save the jenkins password of dc "([^"]+)" into the#{OPT_SYM} clipboard$/ do | dc_name, cbname |
  cbname = 'jenkins_password' unless cbname
  resource = "dc/#{dc_name}"
  @result = user.cli_exec(:env, resource: resource, list: true)
  unless @result[:success]
    raise "Unable to successfully retrieve jenkins password."
  end
  password = /JENKINS_PASSWORD=(.*)/.match(@result[:response])[1]
  cb[cbname] = password
end
