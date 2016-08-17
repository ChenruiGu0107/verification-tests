Feature: jenkins.feature
  # @author xiuwang@redhat.com
  # @case_id 498668
  Scenario: Could change password for jenkins server--jenkins-1-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | template | jenkins-persistent |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | jenkins                                                                         |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "jenkins" PVC becomes :bound within 300 seconds
    Given I wait for the "jenkins" service to become ready
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | -u| admin:password | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain:
      | Dashboard [Jenkins] |
    When I run the :env client command with:
      | resource | dc/jenkins  |
      | e        | JENKINS_PASSWORD=redhat |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=jenkins |
      | deployment=jenkins-2 |
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | -u | admin:redhat | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain:
      | Dashboard [Jenkins] |

  # @author cryan@redhat.com
  # @case_id 525985
  Scenario: Jenkins service existed with bc of jenkinpipeline strategy
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/fabric8io/openshift-jenkins-sync-plugin/master/src/test/resources/sampleBC.yml"
    When I run the :create client command with:
      | f | sampleBC.yml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    And I wait for the "jenkins" service to become ready
    When I use the "jenkins" service
    When I open secure web server via the "jenkins" route
    Then the output should contain "hudson"
    #Create second bc
    Given I replace lines in "sampleBC.yml":
      | name: edam | name: edam1 |
    When I run the :create client command with:
      | f | sampleBC.yml |
    Then the step should succeed
    When I use the "jenkins" service
    When I open secure web server via the "jenkins" route
    Then the output should contain "hudson"
    When I run the :get client command with:
      | resource | bc |
    Then the step should succeed
    And the output should contain:
      | edam  |
      | edam1 |

  # @author shiywang@redhat.com
  # @case_id 515420
  Scenario: Build with new parameter which is configged
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                           |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    Then the step should succeed
    And I wait for the "jenkins" service to become ready
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login" url
    Then the output should contain "Jenkins"
    And the output should not contain "ready to work"
    """
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route.dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin                      |
      | password | <%= cb.jenkins_password %> |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> /Dashboard \[Jenkins\]/ =~ browser.title
    """
    When I run the :jenkins_check_openshift_pipeline_jenkins_plugin web action
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain "OpenShift Pipeline Jenkins Plugin"
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :jenkins_add_build_string_parameter web action with:
      | job_name         | <%= project.name %> |
      | string_parameter | NAMESPACE           |
    Then the step should succeed
    When I perform the :jenkins_create_openshift_build_trigger web action with:
      | job_name      | <%= project.name %>         |
      | api_endpoint  | <%= env.api_endpoint_url %> |
      | build_config  | frontend                    |
      | store_project | NAMESPACE                   |
    Then the step should succeed
    When I perform the :jenkins_build_with_string_parameter web action with:
      | job_name        | <%= project.name %> |
      | build_parameter | <%= project.name %> |
    Then the step should succeed
    And the "frontend-1" build was created
    And the "frontend-1" build completed
    When I perform the :jenkins_build_with_string_parameter web action with:
      | job_name        | <%= project.name %> |
      | build_parameter | notpass-1a4bc       |
    Then the step should succeed
    And I run the :get client command with:
      | resource | build |
    Then the output should not contain "frontend-2"

  # @author cryan@redhat.com
  # @case_id 515421
  Scenario: Create a new job in jenkins with OpenShift Pipeline Jenkins Plugin
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I give project admin role to the system:serviceaccount:<%= cb.proj1 %>:default service account
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin                      |
      | password | <%= cb.jenkins_password %> |
    Then the step should succeed
    When I create a new project
    Then the step should succeed
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I give project edit role to the system:serviceaccount:<%= cb.proj1 %>:default service account
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json"
    When I perform the :jenkins_create_openshift_resources web action with:
      | job_name  | testplugin                                       |
      | apiurl    | https://<%= env.master_hosts[0].hostname %>:8443 |
      | jsonfile  | <%= File.read('hello-pod.json').to_json %>       |
      | namespace | <%= cb.proj2 %>                                  |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name  | testplugin |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=hello-openshift |

  # @author cryan@redhat.com
  # @case_id 527335
  Scenario: jenkins plugin can tag image in the same project
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I create a new project
    Then the step should succeed
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I give project edit role to the system:serviceaccount:<%= cb.proj1 %>:default service account
    When I run the :import_image client command with:
      | image_name | ruby                     |
      | from       | wewang58/ruby-22-centos7 |
      | confirm    | true                     |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is   |
      | resource_name | ruby |
      | o             | yaml |
    Then the step should succeed
    And evaluation of `@result[:parsed]["status"]["tags"][0]["items"][0]["image"]` is stored in the :shasum clipboard
    When I perform the :jenkins_login web action with:
      | username | admin                      |
      | password | <%= cb.jenkins_password %> |
    Then the step should succeed
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_tag_openshift_image web action with:
      | job_name               | testplugin                  |
      | apiurl                 | <%= env.api_endpoint_url %> |
      | curr_img_tag           | <%= cb.shasum %>            |
      | curr_img_tag_is        | ruby                        |
      | new_img_tag            | tag20                       |
      | new_img_tag_is         | ruby20                      |
      | tagnamespace           | <%= cb.proj2 %>             |
      | destinationnamespace   | <%= cb.proj2 %>             |
      | auth_token             | ""                          |
      | destination_auth_token | ""                          |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name  | testplugin |
    Then the step should succeed
    Given the "ruby20" image stream becomes ready
    When I run the :get client command with:
      | resource      | is     |
      | resource_name | ruby20 |
      | o             | json   |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]["spec"]["tags"][0]["from"]["name"] == "ruby@<%= cb.shasum.gsub(/sha256:/,'') %>"
    When I perform the :jenkins_tag_openshift_image_update_dest_tag web action with:
      | job_name | testplugin |
    When I perform the :jenkins_build_now web action with:
      | job_name | testplugin |
    Then the step should succeed
    Given the "ruby20" image stream becomes ready
    When I run the :get client command with:
      | resource      | is     |
      | resource_name | ruby20 |
      | o             | json   |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]["spec"]["tags"][0]["from"]["name"] == "ruby:latest"

  # @author cryan@redhat.com
  # @case_id 498667
  Scenario: Trigger build of application from jenkins job with ephemeral volume
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    When I give project edit role to the default service account
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    When I execute on the pod:
      |  id | -u |
    Then the step should succeed
    #Check that the user is not root, or 0 id
    #The regex below should match any number greater than 0
    And the output should match "^[1-9][0-9]*$"
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin                      |
      | password | <%= cb.jenkins_password %> |
    Then the step should succeed
    When I perform the :jenkins_trigger_sample_openshift_build web action with:
      | job_name                 | OpenShift%20Sample          |
      | scaler_apiurl            | <%= env.api_endpoint_url %> |
      | scaler_namespace         | <%= project.name %>         |
      | builder_apiurl           | <%= env.api_endpoint_url %> |
      | builder_namespace        | <%= project.name %>         |
      | deploy_verify_apiurl     | <%= env.api_endpoint_url %> |
      | deploy_verify_namespace  | <%= project.name %>         |
      | service_verify_apiurl    | <%= env.api_endpoint_url %> |
      | service_verify_namespace | <%= project.name %>         |
      | image_tagger_apiurl      | <%= env.api_endpoint_url %> |
      | image_tagger_namespace   | <%= project.name %>         |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | OpenShift%20Sample |
    Then the step should succeed
    Given the "frontend-1" build was created
    And the "frontend-1" build completes
    And a pod becomes ready with labels:
      | app=frontend |
    #Ensure the Jenkins job completes, wait for the frontend-prod pod
    And a pod becomes ready with labels:
      | deployment=frontend-prod-1 |
    And I get project services
    Then the output should contain:
      | frontend-prod |
      | frontend      |
      | jenkins       |
    Given I get project deploymentconfigs
    Then the output should contain:
      | frontend-prod |
      | frontend      |
      | jenkins       |
    Given I get project is
    Then the output should contain:
      | <%= project.name %>/nodejs-010-rhel7     |
      | <%= project.name %>/origin-nodejs-sample |
      | prod                                     |
    When I run the :describe client command with:
      | resource | builds     |
      | name     | frontend-1 |
    Then the step should succeed
    And the output should contain "Manually triggered"
    When I perform the :jenkins_build_now web action with:
      | job_name | OpenShift%20Sample |
    Then the step should succeed
    Given the "frontend-2" build was created
    And the "frontend-2" build completes
    Given I get project is
    Then the output should contain:
      | <%= project.name %>/nodejs-010-rhel7     |
      | <%= project.name %>/origin-nodejs-sample |
      | prod                                     |

  # @author cryan@redhat.com
  # @case_id 527297
  Scenario: jenkins plugin can tag image in different projects use destination project token
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    When I run the :import_image client command with:
      | image_name | ruby                      |
      | from       | openshift/ruby-22-centos7 |
      | confirm    | true                      |
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin    |
      | password | <%= cb.jenkins_password %> |
    Then the step should succeed
    When I create a new project
    Then the step should succeed
    And evaluation of `project.name` is stored in the :proj2 clipboard

    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj1 %>:default |
      | n | <%= cb.proj2 %> |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj2 %>:default |
      | n                 | <%= cb.proj1 %>                               |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj2 %>:default |
      | n                 | <%= cb.proj2 %>                               |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj1 %>:default |
      | n                 | <%= cb.proj1 %>                               |
    Then the step should succeed

    Given I find a bearer token of the system:serviceaccount:<%= cb.proj2 %>:default service account
    Given evaluation of `service_account.get_bearer_token.token` is stored in the :token1 clipboard
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_tag_openshift_image web action with:
      | job_name               | testplugin                                       |
      | apiurl                 | https://<%= env.master_hosts[0].hostname %>:8443 |
      | curr_img_tag           | latest                                           |
      | curr_img_tag_is        | ruby                                             |
      | new_img_tag            | newtag                                           |
      | new_img_tag_is         | newimage                                         |
      | tagnamespace           | <%= cb.proj1 %>                                  |
      | destinationnamespace   | <%= cb.proj2 %>                                  |
      | auth_token             | ""                                               |
      | destination_auth_token | <%= cb.token1 %>                                 |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | testplugin |
      | job_number | 1          |
      | time_out   | 60         |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is       |
      | resource_name | newimage |
      | o             | json     |
    Then the step should succeed
    And the output should contain:
      | newtag           |
      | ImageStreamImage |
      | ruby@            |
    When I perform the :jenkins_build_now web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | testplugin |
      | job_number | 2          |
      | time_out   | 60         |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is       |
      | resource_name | newimage |
      | o             | json     |
    Then the step should succeed
    And the output should contain:
      | newtag           |
      | ImageStreamImage |
      | ruby@            |
    Given evaluation of `@result[:parsed]["spec"]["tags"][0]["from"]["name"].gsub(/ruby@/,'')` is stored in the :imgid clipboard
    When I perform the :jenkins_tag_openshift_image_id_update web action with:
      | job_name             | testplugin                                       |
      | apiurl               | https://<%= env.master_hosts[0].hostname %>:8443 |
      | curr_img_tag         | <%= cb.imgid %>                                  |
      | curr_img_tag_is      | ruby                                             |
      | new_img_tag          | newtag                                           |
      | new_img_tag_is       | newimage                                         |
      | tagnamespace         | <%= cb.proj1 %>                                  |
      | destinationnamespace | <%= cb.proj2 %>                                  |
      | token                | <%= cb.token1 %>                                 |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | testplugin |
      | job_number | 3          |
      | time_out   | 60         |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is       |
      | resource_name | newimage |
      | o             | json     |
    Then the step should succeed
    And the output should contain:
      | newtag           |
      | ImageStreamImage |
      | ruby@            |
    When I perform the :jenkins_build_now web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | testplugin |
      | job_number | 4          |
      | time_out   | 60         |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is       |
      | resource_name | newimage |
      | o             | json     |
    Then the step should succeed
    And the output should contain:
      | newtag           |
      | ImageStreamImage |
      | ruby@            |

  # @author cryan@redhat.com
  # @case_id 527298
  Scenario: jenkins plugin can tag image in different projects use jenkins project token
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    When I run the :import_image client command with:
      | image_name | ruby                      |
      | from       | openshift/ruby-22-centos7 |
      | confirm    | true                      |
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin                      |
      | password | <%= cb.jenkins_password %> |
    Then the step should succeed
    When I create a new project
    Then the step should succeed
    And evaluation of `project.name` is stored in the :proj2 clipboard

    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj1 %>:default |
      | n | <%= cb.proj2 %> |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj2 %>:default |
      | n                 | <%= cb.proj1 %>                               |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj2 %>:default |
      | n                 | <%= cb.proj2 %>                               |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj1 %>:default |
      | n                 | <%= cb.proj1 %>                               |
    Then the step should succeed

    Given I find a bearer token of the system:serviceaccount:<%= cb.proj1 %>:default service account
    Given evaluation of `service_account.get_bearer_token.token` is stored in the :token1 clipboard
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_tag_openshift_image web action with:
      | job_name                | testplugin                                       |
      | apiurl                  | https://<%= env.master_hosts[0].hostname %>:8443 |
      | curr_img_tag            | latest                                           |
      | curr_img_tag_is         | ruby                                             |
      | new_img_tag             | newtag                                           |
      | new_img_tag_is          | newimage                                         |
      | tagnamespace            | <%= cb.proj1 %>                                  |
      | destinationnamespace    | <%= cb.proj2 %>                                  |
      | auth_token              | <%= cb.token1 %>                                 |
      | destination_auth_token  | ""                                               |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | testplugin |
      | job_number | 1          |
      | time_out   | 60         |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is       |
      | resource_name | newimage |
      | o             | json     |
    Then the step should succeed
    And the output should contain:
      | newtag           |
      | ImageStreamImage |
      | ruby@            |
    When I perform the :jenkins_build_now web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | testplugin |
      | job_number | 2          |
      | time_out   | 60         |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is       |
      | resource_name | newimage |
      | o             | json     |
    Then the step should succeed
    And the output should contain:
      | newtag           |
      | ImageStreamImage |
      | ruby@            |
    Given evaluation of `@result[:parsed]["spec"]["tags"][0]["from"]["name"].gsub(/ruby@/,'')` is stored in the :imgid clipboard
    When I perform the :jenkins_tag_openshift_image_id_update web action with:
      | job_name     | testplugin      |
      | curr_img_tag | <%= cb.imgid %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | testplugin |
      | job_number | 3          |
      | time_out   | 60         |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is       |
      | resource_name | newimage |
      | o             | json     |
    Then the step should succeed
    And the output should contain:
      | newtag           |
      | ImageStreamImage |
      | ruby@            |
    When I perform the :jenkins_build_now web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | testplugin |
      | job_number | 4          |
      | time_out   | 60         |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is       |
      | resource_name | newimage |
      | o             | json     |
    Then the step should succeed
    And the output should contain:
      | newtag           |
      | ImageStreamImage |
      | ruby@            |

  # @author shiywang@redhat.com
  # @case_id 516504
  Scenario: Check verbose logging in build field of openshift v3 plugin of jenkins-1-rhel7
    Given I have a project
    When I give project admin role to the default service account
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json                  |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/                                     |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin                      |
      | password | <%= cb.jenkins_password %> |
    Then the step should succeed
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :jenkins_check_logging_build_step_verbose web action with:
      | job_name | <%= project.name %> |
    Then the step should succeed

  # @author shiywang@redhat.com
  # @case_id 520288 520287 520286
  Scenario Outline: Use Jenkins as S2I builder and with Kubernetes Slaves
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                                            |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/master-slave/jenkins-slave-template.json  |
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/master-slave/jenkins-master-template.json |
    Then the step should succeed
    When I perform the :create_app_from_template_with_blank_form web console action with:
      | project_name  | <%= project.name %>                                       |
      | template_name | jenkins-slave-builder                                     |
      | namespace     | <%= project.name %>                                       |
      | param_one     | <%= product_docker_repo %><image_url>                     |
      | param_two     | <image>                                                   |
      | param_three   | https://github.com/openshift-qe/jenkins-slave-rhel7repo   |
      | param_four    | :null                                                     |
      | param_five    | master                                                    |
    Then the step should succeed
    And the "<image>-jenkins-slave-1" build was created
    And the "<image>-jenkins-slave-1" build completed
    And I run the :get client command with:
      | resource      | imagestreams          |
      | resource_name | <image>-jenkins-slave |
    Then the step should succeed
    And the output should match:
      | <image>-jenkins-slave |
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %> |
      | template_name | jenkins-master      |
      | namespace     | <%= project.name %> |
      | param_one     | :null               |
      | param_two     | :null               |
      | param_three   | :null               |
      | param_four    | :null               |
      | param_five    | :null               |
    Then the step should succeed
    And the "jenkins-master-1" build was created
    And the "jenkins-master-1" build completed
    And I wait for the "jenkins" service to become ready
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login" url
    Then the output should contain "Jenkins"
    And the output should not contain "ready to work"
    """
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    Then the step should succeed
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route.dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin                      |
      | password | <%= cb.jenkins_password %> |
    Then the step should succeed
    When I run the :jenkins_install_kubernetes_plugin web action
    Then the step should succeed
    When I perform the :jenkins_login web action with:
      | username | admin                      |
      | password | <%= cb.jenkins_password %> |
    Then the step should succeed
    When I run the :jenkins_check_kubernetes_plugin web action
    Then the step should succeed
    When I perform the :jenkins_change_configure_label web action with:
      | job_name | ruby-hello-world-test |
      | label    | <image>               |
    When I perform the :jenkins_change_execute_shell_command web action with:
      | job_name | ruby-hello-world-test |
      | input    | <execute_shell_param> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | ruby-hello-world-test |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | ruby-hello-world-test |
      | job_number | 1                     |
      | time_out   | 300                   |
    Then the step should succeed
    Examples:
      | image      | image_url                       | execute_shell_param                                                                                             |
      | ruby-22    | rhscl/ruby-22-rhel7:latest      | # Install the rubygems \n bundle install --path=./vendor \n # Execute simple unit test \n bundle exec rake test |
      | ruby-20    | openshift3/ruby-20-rhel7:latest | # Install the rubygems \n bundle install --path=./vendor \n # Execute simple unit test \n bundle exec rake test |
      | nodejs-010 | openshift3/nodejs-010-rhel7     | npm -v                                                                                                          |

  # @author wewang@redhat.com
  # @case_id  515423
  Scenario: Test jenkins post-build actions 
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I give project edit role to the system:serviceaccount:<%= cb.proj1 %>:default service account
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    Then the step should succeed
    And I wait for the "jenkins" service to become ready
    Given I wait up to 60 seconds for the steps to pass:
    """ 
    When I open web server via the "https://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login" url
    Then the output should contain "Jenkins"
    And the output should not contain "ready to work"
    When I run the :env client command with:
      | resource | dc/jenkins |
      | list     | true       |
    Then the step should succeed
    And evaluation of `/JENKINS_PASSWORD=(.*)/.match(@result[:response])[1]` is stored in the :jenkins_password clipboard
    """
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route.dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin    |
      | password | <%= cb.jenkins_password %> | 
    Then the step should succeed
    When I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completes
    When I give project edit role to the system:serviceaccount:<%= cb.proj1 %>:default service account
    When I run the :start_build client command with:
      |buildconfig|ruby-sample-build|
    Then the step should succeed
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | cancelbuildjob |
    Then the step should succeed
    When I perform the :jenkins_post_cancel_build_from_job web action with:
      | job_name  |  cancelbuildjob                                  |
      | api_endpoint | <%= env.api_endpoint_url %>                   |
      | store_project| <%= cb.proj2 %>                               |
      | build_config | ruby-sample-build                             |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name  | cancelbuildjob |
    Then the step should succeed
    And the "ruby-sample-build-2" build was cancelled 
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | canceldeploymentjob |
    Then the step should succeed
    When I perform the :jenkins_cancel_deployment_from_job web action with:
      | job_name  | canceldeploymentjob                              |
      | api_endpoint | https://openshift.default.svc.cluster.local   |
      | deployment_config  | database                                |
      | store_project | <%= cb.proj2 %>                              |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | database |
      | latest | true |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name  | canceldeploymentjob |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | rc   |
    And the output should match:
      | database-2+\s+0+\s+0 |
