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
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | -u| admin:<%= cb.jenkins_password %> | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain:
      | Dashboard [Jenkins] |
    When I run the :env client command with:
      | resource | dc/jenkins              |
      | e        | JENKINS_PASSWORD=redhat |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=jenkins         |
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
  # @case_id 525984
  Scenario: Jenkins service created with bc of jenkinpipeline strategy
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/fabric8io/openshift-jenkins-sync-plugin/master/src/test/resources/sampleBC.yml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    And I wait for the "jenkins" service to become ready
    When I use the "jenkins" service
    When I open secure web server via the "jenkins" route
    Then the output should contain "hudson"
    When I run the :delete client command with:
      | object_type       | bc   |
      | object_name_or_id | edam |
    Then the step should succeed
    Given I get project pods
    Then the output should contain "jenkins"

  # @author cryan@redhat.com
  # @case_id 531203 536414
  Scenario Outline: Using jenkinsfilePath or contextDir with jenkinspipeline strategy
    Given I have a project
    And I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc531203/samplepipeline.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I get project buildconfigs
    Then the output should contain:
      | ruby-sample-build |
      | sample-pipeline   |
    When I run the :get client command with:
      | resource      | bc              |
      | resource_name | sample-pipeline |
      | o             | yaml            |
    Then the output should contain "https://github.com/openshift-qe/jenkins-pipeline-ruby-test.git"
    And the output should match "jenkinsfilePath:\s+jenkins/pipeline/Jenkinsfile"
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-1" build was created
    And the "sample-pipeline-1" build completes
    Given I get project builds
    Then the output should contain:
      | ruby-sample-build-1 |
      | sample-pipeline-1   |
    When I run the :patch client command with:
      | resource      | bc                                                                                                  |
      | resource_name | sample-pipeline                                                                                   |
      | p             | {"spec":{"strategy": {"type": "JenkinsPipeline","jenkinsPipelineStrategy": {"jenkinsfilePath":""}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-2" build was created
    And the "sample-pipeline-2" build completes
    When I run the :patch client command with:
      | resource      | bc                                                                                                  |
      | resource_name | sample-pipeline                                                                                   |
      | p             | {"spec": {"source": {"contextDir": "jenkins/pipeline","type": "Git"},"strategy": {"type": "JenkinsPipeline","jenkinsPipelineStrategy": {"jenkinsfilePath": ""}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-3" build was created
    And the "sample-pipeline-3" build completes
    When I run the :patch client command with:
      | resource      | bc                                                                                                  |
      | resource_name | sample-pipeline                                                                                   |
      | p             | {"spec": {"source": {"contextDir": "jenkins","type": "Git"},"strategy": {"type": "JenkinsPipeline","jenkinsPipelineStrategy": {"jenkinsfilePath": "pipeline/Jenkinsfile"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-4" build was created
    And the "sample-pipeline-4" build completes
    Examples:
      | ver |
      | 1   |
      | 2   |

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
    When I run the :create client command with:
      | f | sampleBC.yml |
    Then the step should fail
    And the output should contain "already exists"

  # @author shiywang@redhat.com
  # @case_id 515420 536389
  Scenario Outline: Build with new parameter which is configged
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                           |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    Given I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    Then the step should succeed
    And I wait for the "jenkins" service to become ready
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login" url
    Then the output should contain "Jenkins"
    And the output should not contain "ready to work"
    """
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    Given I log in to jenkins
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
      | time_out | 300                 |
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
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id 515421 536390
  Scenario Outline: Create a new job in jenkins with OpenShift Pipeline Jenkins Plugin
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I give project admin role to the system:serviceaccount:<%= cb.proj1 %>:jenkins service account
    Then the step should succeed
    Given I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    Given I log in to jenkins
    When I create a new project
    Then the step should succeed
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I give project edit role to the system:serviceaccount:<%= cb.proj1 %>:jenkins service account
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json"
    When I perform the :jenkins_create_openshift_resources web action with:
      | job_name  | testplugin                                       |
      | apiurl    | <%= env.api_endpoint_url %>                      |
      | jsonfile  | <%= File.read('hello-pod.json').to_json %>       |
      | namespace | <%= cb.proj2 %>                                  |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name  | testplugin |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=hello-openshift |
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id 527335 536401
  Scenario Outline: jenkins plugin can tag image in the same project
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    And I have an ephemeral jenkins v<ver> application
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I create a new project
    Then the step should succeed
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I give project edit role to the system:serviceaccount:<%= cb.proj1 %>:jenkins service account
    When I run the :import_image client command with:
      | image_name | ruby                  |
      | from       | aosqe/ruby-22-centos7 |
      | confirm    | true                  |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is   |
      | resource_name | ruby |
      | o             | yaml |
    Then the step should succeed
    And evaluation of `@result[:parsed]["status"]["tags"][0]["items"][0]["image"]` is stored in the :shasum clipboard
    Given I log in to jenkins
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
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id 498667 536384
  Scenario Outline: Trigger build of application from jenkins job with ephemeral volume
    Given I have a project
    And I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    When I give project edit role to the default service account
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    When I execute on the pod:
      |  id | -u |
    Then the step should succeed
    #Check that the user is not root, or 0 id
    #The regex below should match any number greater than 0
    And the output should match "^[1-9][0-9]*$"
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
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
      | <%= env.version_gt("3.2", user: user) ? "name" : "app" %>=frontend |
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
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id 508754 536386
  Scenario Outline: Trigger build of application from jenkins job with persistent volume
    Given I have a project
    When I run the :new_app client command with:
      | file         | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-persistent-template.json |
      | env          | JENKINS_PASSWORD=test                                                                                       |
      | env          | OPENSHIFT_ENABLE_OAUTH=false                                                                                |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | jenkins                                                                         |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "jenkins" PVC becomes :bound within 300 seconds
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    When I give project edit role to the default service account
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    When I execute on the pod:
      |  id | -u |
    Then the step should succeed
    #Check that the user is not root, or 0 id
    Then the expression should be true> Integer(@result[:response]) > 0
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
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
      | deploymentconfig=frontend |
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
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id 527297 536399
  Scenario Outline: jenkins plugin can tag image in different projects use destination project token
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    And I have an ephemeral jenkins v<ver> application
    Given a pod becomes ready with labels:
      | name=jenkins |
    When I run the :import_image client command with:
      | image_name | ruby                      |
      | from       | openshift/ruby-22-centos7 |
      | confirm    | true                      |
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    Given I log in to jenkins
    When I create a new project
    Then the step should succeed
    And evaluation of `project.name` is stored in the :proj2 clipboard

    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj1 %>:jenkins |
      | n                 | <%= cb.proj2 %>                               |
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
      | serviceaccountraw | system:serviceaccount:<%= cb.proj1 %>:jenkins |
      | n                 | <%= cb.proj1 %>                               |
    Then the step should succeed

    Given I find a bearer token of the system:serviceaccount:<%= cb.proj2 %>:default service account
    Given evaluation of `service_account.get_bearer_token.token` is stored in the :token1 clipboard
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_tag_openshift_image web action with:
      | job_name               | testplugin                                       |
      | apiurl                 | <%= env.api_endpoint_url %>                      |
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
      | apiurl               | <%= env.api_endpoint_url %>                      |
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
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id 527298 536400
  Scenario Outline: jenkins plugin can tag image in different projects use jenkins project token
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    And I have an ephemeral jenkins v<ver> application
    Given a pod becomes ready with labels:
      | name=jenkins |
    When I run the :import_image client command with:
      | image_name | ruby                      |
      | from       | openshift/ruby-22-centos7 |
      | confirm    | true                      |
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
    Given I find a bearer token of the system:serviceaccount:<%= cb.proj1 %>:jenkins service account
    Given evaluation of `service_account.get_bearer_token.token` is stored in the :token1 clipboard
    When I create a new project
    Then the step should succeed
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj1 %>:jenkins |
      | n                 | <%= cb.proj2 %>                               |
    Then the step should succeed
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_tag_openshift_image web action with:
      | job_name                | testplugin                                       |
      | apiurl                  | <%= env.api_endpoint_url %>                      |
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
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author shiywang@redhat.com
  # @case_id 516504
  Scenario Outline: Check verbose logging in build field of openshift v3 plugin
    Given I have a project
    When I give project admin role to the default service account
    Then the step should succeed
    Given I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    Given I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :jenkins_check_logging_build_step_verbose web action with:
      | job_name | <%= project.name %> |
    Then the step should succeed
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author shiywang@redhat.com
  # @case_id 520288 520287 520286
  # NOTE: The behavior outlined here is now outdated, and should be refactored
  # in accordance with:
  # https://github.com/openshift/origin/tree/master/examples/jenkins#advanced
  # Until then, the missing master-slave scripts can be found in v3-testfiles.
  Scenario Outline: Use Jenkins as S2I builder and with Kubernetes Slaves
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                                            |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc520288/jenkins-slave-template.json  |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc520288/jenkins-master-template.json |
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
    Then the step should succeed
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_2/                                   |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
    When I run the :jenkins_install_kubernetes_plugin web action
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

  # @author cryan@redhat.com
  # @case_id 529769 536411
  Scenario Outline: Show annotation when build triggered by jenkins pipeline
    Given I have a project
    And I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/application-template.json |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role              | admin                                             |
      | serviceaccountraw | system:serviceaccount:<%= project.name %>:default |
      | n                 | <%= project.name%>                                |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=jenkins |
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_create_openshift_build_trigger web action with:
      | job_name | testplugin |
      | api_endpoint  | <%= env.api_endpoint_url %> |
      | build_config  | frontend                    |
      | store_project | <%= project.name %>         |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | testplugin |
      | job_number | 1          |
      | time_out   | 300        |
    Then the step should succeed
    Given the "frontend-1" build completes
    When I run the :describe client command with:
      | resource | build      |
      | name     | frontend-1 |
    Then the output should contain "job/testplugin"
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id 515424 536393
  Scenario Outline: Testing workflow using openshift v3 plugin
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role              | admin                                             |
      | serviceaccountraw | system:serviceaccount:<%= project.name %>:default |
      | n                 | <%= project.name%>                                |
    Then the step should succeed
    Given I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    Given the "ruby22-sample-build-1" build was created
    And the "ruby22-sample-build-1" build completes
    And a pod becomes ready with labels:
      | name=jenkins |
    And I get project routes
    Then the output should contain "jenkins"
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | test |
    Then the step should succeed
    When I perform the :jenkins_scale_openshift_deployment web action with:
      | job_name     | test                        |
      | apiurl       | <%= env.api_endpoint_url %> |
      | depcfg       | frontend                    |
      | namespace    | <%= project.name%>          |
      | replicacount | 3                           |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | test |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | test |
      | job_number | 1    |
      | time_out   | 300  |
    Then the step should succeed
    Given I get project dc
    Then the output should match "frontend\s+1\s+3"
    Given I get project rc
    Then the output should match "frontend-1\s+3\s+3"
    Given I get project pods
    Then the output should contain 3 times:
      | frontend-1 |
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author wewang@redhat.com
  # @case_id 515423 536392
  Scenario Outline: Test jenkins post-build actions
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I give project edit role to the system:serviceaccount:<%= cb.proj1 %>:jenkins service account
    Then the step should succeed
    Given I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=jenkins |
    And I get project routes
    Then the output should contain "jenkins"
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
    When I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completes
    When I give project edit role to the system:serviceaccount:<%= cb.proj1 %>:jenkins service account
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | cancelbuildjob |
    Then the step should succeed
    When I perform the :jenkins_post_cancel_build_from_job web action with:
      | job_name      |  cancelbuildjob                               |
      | api_endpoint  | <%= env.api_endpoint_url %>                   |
      | store_project | <%= cb.proj2 %>                               |
      | build_config  | ruby-sample-build                             |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | cancelbuildjob |
    Then the step should succeed
    And the "ruby-sample-build-2" build was created
    And the "ruby-sample-build-2" build was cancelled
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | canceldeploymentjob |
    Then the step should succeed
    When I perform the :jenkins_cancel_deployment_from_job web action with:
      | job_name          | canceldeploymentjob         |
      | api_endpoint      | <%= env.api_endpoint_url %> |
      | deployment_config | database                    |
      | store_project     | <%= cb.proj2 %>             |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | database |
      | latest            | true     |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | canceldeploymentjob |
    Then the step should succeed
    When I run the :get client command with:
      | resource | rc |
    And the output should match:
      | database-2+\s+0+\s+0 |
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id 533683
  Scenario: Pipeline build, started before Jenkins is deployed, shouldn't get deleted
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given I get project builds
    Then the output should contain:
      | sample-pipeline-1 |
      | New               |
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    #Ensure the pre-existing build is still present after jenkins creation
    Given I get project builds
    Then the output should contain "sample-pipeline-1"
    And I wait up to 60 seconds for the steps to pass:
    """
    Given I get project builds
    Then the output should match:
      | sample-pipeline-1\s+JenkinsPipeline\s+Running |
    """

  # @author cryan@redhat.com
  # @case_id 534536 534540 534541
  Scenario Outline: Delete openshift resources in jenkins with OpenShift Pipeline Jenkins Plugin
    Given I have a project
    Given I have an ephemeral jenkins v<jenkins_version> application
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json"
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<jenkins_version>/                   |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_create_openshift_resources web action with:
      | job_name  | testplugin                                 |
      | apiurl    | <%= env.api_endpoint_url %>                |
      | jsonfile  | <%= File.read('hello-pod.json').to_json %> |
      | namespace | <%= project.name %>                        |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name  | testplugin |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=hello-openshift |
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | deletesrc |
    Then the step should succeed
    When I perform the :jenkins_delete_openshift_resources web action with:
      | job_name         | deletesrc                   |
      | steptype         | <steptype>                  |
      | deletertype      | <deletertype>               |
      | apiurl           | <%= env.api_endpoint_url %> |
      | resourcetype     | <resourcetype>              |
      | resourcekey      | <resourcekey>               |
      | resourceval      | <resourceval>               |
      | resourcejsonyaml | <resourcejsonyaml>          |
      | namespace        | <%= project.name %>         |
    When I perform the :jenkins_build_now web action with:
      | job_name | deletesrc |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | deletesrc |
      | job_number | 1         |
      | time_out   | 300       |
    Then the step should succeed
    Given I wait for the pod named "hello-openshift" to die regardless of current status
    Given I get project pods
    Then the output should not contain "hello-openshift"
    Examples:
      | steptype       | resourcetype | resourcekey     | resourceval     | resourcejsonyaml                           | deletertype              | jenkins_version |
      | using Labels   | pod          | name            | hello-openshift |                                            | OpenShiftDeleterLabels   | 1               |
      | by Key         | pod          | hello-openshift |                 |                                            | OpenShiftDeleterList     | 1               |
      | from JSON/YAML |              |                 |                 | <%= File.read('hello-pod.json').to_json %> | OpenShiftDeleterJsonYaml | 1               |
      | using Labels   | pod          | name            | hello-openshift |                                            | OpenShiftDeleterLabels   | 2               |
      | by Key         | pod          | hello-openshift |                 |                                            | OpenShiftDeleterList     | 2               |
      | from JSON/YAML |              |                 |                 | <%= File.read('hello-pod.json').to_json %> | OpenShiftDeleterJsonYaml | 2               |

  # @author wewang@redhat.com
  # @case_id 516502
  Scenario Outline: update build field of openshift v3 plugin
    Given I have a project
    When I give project admin role to the default service account
    Then the step should succeed
    Given I have an ephemeral jenkins v<ver> application
    And a pod becomes ready with labels:
      | name=jenkins |
    And I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | <%= project.name %>             |
    Then the step should succeed
    When I perform the :jenkins_check_build_fields web action with:
      | job_name     | <%= project.name %>         |
      | api_endpoint | <%= env.api_endpoint_url %> |
      | build_config | frontend                    |
      | name_space   | <%= project.name %>         |
      | token        | 12345                       |
      | commit_hash  | 456789                      |
    Then the step should succeed
    #update post-build action
    When I perform the :jenkins_check_post_build_fields web action with:
      | job_name      | <%= project.name %>         |
      | api_endpoint  | <%= env.api_endpoint_url %> |
      | store_project | <%= project.name %>         |
      | build_config  | frontend                    |
    Then the step should succeed
    When I perform the :goto_configure_page web action with:
      | job_name      | <%= project.name %>        |
    Then the step should succeed
    When I get the "value" attribute of the "input" web element:
      | xpath | //input[contains(@checkurl, 'OpenShiftBuilder/checkApiURL')]    |
    Then the output should contain "<%= env.api_endpoint_url %>"
    When I get the "value" attribute of the "input" web element:
      | xpath | //input[contains(@checkurl, 'OpenShiftBuilder/checkBldCfg')]    |
    Then the output should contain "frontend"
    When I get the "value" attribute of the "input" web element:
      | xpath | //input[contains(@checkurl, 'OpenShiftBuilder/checkNamespace')] |
    Then the output should contain "<%= project.name %>"
    When I get the "value" attribute of the "input" web element:
      | xpath | //input[contains(@checkurl, 'OpenShiftBuilder/checkAuthToken')] |
    Then the output should contain "12345"
    When I get the "value" attribute of the "input" web element:
      | name  | _.commitID |
    Then the output should contain "456789"
    When I get the "value" attribute of the "input" web element:
      | xpath | //div[contains(@descriptorid, 'OpenShiftBuilder')]//td[contains(text(),"Allow for verbose logging during this build step plug-in")]/following-sibling::td[1]/input[1]              |
    Then the output should contain "true"
    When I get the "value" attribute of the "input" web element:
      | xpath | //div[contains(@descriptorid, 'OpenShiftBuilder')]//td[contains(text(),"Pipe the build logs from OpenShift to the Jenkins console")]/following-sibling::td[1]/input[1]             |
    Then the output should contain "true"
    When I get the "value" attribute of the "input" web element:
      | xpath | //div[contains(@descriptorid, 'OpenShiftBuilder')]//td[contains(text(),"Verify whether any deployments triggered by this build's output fired")]/following-sibling::td[1]/input[1] |
    Then the output should contain "true"
    #check post-build action options
    When I get the "value" attribute of the "input" web element:
      | xpath | //input[contains(@checkurl,"OpenShiftBuildCanceller/checkApiURL")]    |
    Then the output should contain "<%= env.api_endpoint_url %>"
    When I get the "value" attribute of the "input" web element:
      | xpath | //input[contains(@checkurl,"OpenShiftBuildCanceller/checkNamespace")] |
    Then the output should contain "<%= project.name %>"
    When I get the "value" attribute of the "input" web element:
      | xpath | //input[contains(@checkurl,"OpenShiftBuildCanceller/checkBldCfg")]    |
    Then the output should contain "frontend"
    When I get the "value" attribute of the "input" web element:
      | xpath | //div[contains(@descriptorid, 'OpenShiftBuildCanceller')]//td[contains(text(),"Allow for verbose logging during this build step plug-in")]/following-sibling::td[1]/input[1]       |
    Then the output should contain "true"
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id 532328
  Scenario: Make jenkins slave configurable when do jenkinspipeline strategy with maven slave
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc                                                                                                                                                                                                                                                                                         |
      | resource_name | sample-pipeline                                                                                                                                                                                                                                                                            |
      | p             | {"spec" : {"strategy": {"jenkinsPipelineStrategy": {"jenkinsfile": "node('maven') {\\nstage 'build'\\nopenshiftBuild(buildConfig: 'ruby-sample-build', showBuildLogs: 'true')\\nstage 'deploy'\\nopenshiftDeploy(deploymentConfig: 'frontend')\\nstage 'Check mvn version'\\nsh 'mvn -v'\\n}"}}}} |
    Then the step should succeed
    Given a pod becomes ready with labels:
        | name=jenkins         |
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin                      |
      | password | <%= cb.jenkins_password %> |
    Then the step should succeed
    When I perform the :jenkins_update_cloud_image web action with:
      | currentimgval | openshift/jenkins-slave-maven-centos7                          |
      | cloudimage    | <%= product_docker_repo %>openshift3/jenkins-slave-maven-rhel7 |
    Then the step should succeed
    When I perform the :jenkins_check_pipeline_script web action with:
      | job_name  | sample-pipeline |
      | checktext | 'mvn -v'        |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | jenkins=slave |
    Given the "sample-pipeline-1" build completes
    When I perform the :jenkins_verify_job_text web action with:
      | job_name   | sample-pipeline |
      | job_number | 1               |
      | checktext  | Apache Maven    |
      | time_out   | 300             |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc                                                                                                                                                                                                                                                                                         |
      | resource_name | sample-pipeline                                                                                                                                                                                                                                                                            |
      | p             | {"spec" : {"strategy": {"jenkinsPipelineStrategy": {"jenkinsfile": "node('unexist') {\\nstage 'build'\\nopenshiftBuild(buildConfig: 'ruby-sample-build', showBuildLogs: 'true')\\nstage 'deploy'\\nopenshiftDeploy(deploymentConfig: 'frontend')\\nstage 'Check mvn version'\\nsh 'mvn -v'\\n}"}}}} |
    Then the step should succeed
    When I perform the :jenkins_add_pod_template web action with:
      | podname  | unexist        |
      | podlabel | unexist        |
      | podimage | unexist:latest |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When I perform the :jenkins_verify_job_text web action with:
      | job_name   | sample-pipeline |
      | job_number | 2               |
      | checktext  | is offline      |
      | time_out   | 300             |
    Then the step should succeed

  # @author cryan@redhat.com
  # @case_id 529770
  Scenario: Show annotation when deployment triggered by image built from jenkins pipeline
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/application-template.json |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                           |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/                                     |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin                           |
      | password | <%= cb.jenkins_password %>      |
    Then the step should succeed
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | <%= project.name %>             |
    Then the step should succeed
    When I perform the :jenkins_create_openshift_build_trigger web action with:
      | job_name      | <%= project.name %>         |
      | api_endpoint  | <%= env.api_endpoint_url %> |
      | build_config  | frontend                    |
      | store_project | <%= project.name %>         |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name      | <%= project.name %>         |
    Then the step should succeed
    Given the "frontend-1" build completes
    And a pod becomes ready with labels:
      | name=frontend |
    When I run the :get client command with:
      | resource      | replicationcontrollers |
      | resource_name | frontend-1             |
      | o             | yaml                   |
    And the output should contain:
      | job/<%= project.name %>        |
      | openshift.io/jenkins-build-uri |

  # @author cryan@redhat.com
  # @case_id 529771 536413
  Scenario Outline: Show annotation when deployment triggered by jenkins pipeline
    Given I have a project
    Given I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/application-template.json |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                           |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | <%= project.name %>             |
    Then the step should succeed
    When I perform the :jenkins_create_openshift_build_trigger web action with:
      | job_name      | <%= project.name %>         |
      | api_endpoint  | <%= env.api_endpoint_url %> |
      | build_config  | frontend                    |
      | store_project | <%= project.name %>         |
    When I perform the :jenkins_create_openshift_deployment_trigger web action with:
      | job_name         | <%= project.name %>         |
      | api_endpoint     | <%= env.api_endpoint_url %> |
      | deploymentconfig | frontend                    |
      | store_project    | <%= project.name %>         |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | <%= project.name %> |
    Then the step should succeed
    Given the "frontend-1" build completes
    And a pod becomes ready with labels:
      | name=frontend |
    When I run the :get client command with:
      | resource      | replicationcontrollers |
      | resource_name | frontend-1             |
      | o             | yaml                   |
    And the output should contain:
      | job/<%= project.name %>        |
      | openshift.io/jenkins-build-uri |
    Examples:
      | ver |
      |  1  |
      |  2  |

  # @author cryan@redhat.com
  # @case_id 534542 536427
  # @note This scenario will fail as of 1/17/17 due to a deprecation
  # of spec.portalIP in the jenkins templates, and a shift in the
  # jenkins plugin to use spec.portalIP.
  # https://github.com/openshift/origin/commit/e0c8f93be1bf173f5932796c4d3cbd96310b4de7
  # The plugin should be rebuilt shortly, and we can retest sometime after 1
  # week beyond 1/17/17 for a passing result.
  # The attendant github issue can be tracked here:
  # https://github.com/openshift/jenkins-plugin/issues/122
  Scenario Outline: Verify openshift build deployment and service in jenkins pipeline plugin
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :policy_add_role_to_user client command with:
      | role           | edit            |
      | serviceaccount | jenkins         |
      | n              | <%= cb.proj1 %> |
    Then the step should succeed
    Given I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    And I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    Given I switch to the second user
    And I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    And I use the "<%= cb.proj2 %>" project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build completes
    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj1 %>:jenkins |
      | n                 | <%= cb.proj2 %>                               |
    Then the step should succeed
    Given I switch to the first user
    Given I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    When I perform the :jenkins_verify_openshift_build web action with:
      | job_name  | openshifttest               |
      | apiurl    | <%= env.api_endpoint_url %> |
      | bldcfg    | ruby-sample-build           |
      | namespace | <%= cb.proj2 %>             |
    When I perform the :jenkins_verify_openshift_deployment web action with:
      | job_name     | openshifttest               |
      | apiurl       | <%= env.api_endpoint_url %> |
      | deployconfig | frontend                    |
      | namespace    | <%= cb.proj2 %>             |
    When I perform the :jenkins_verify_openshift_service web action with:
      | job_name  | openshifttest               |
      | apiurl    | <%= env.api_endpoint_url %> |
      | svcname   | frontend                    |
      | namespace | <%= cb.proj2 %>             |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | openshifttest |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest |
      | job_number | 1             |
      | time_out   | 300           |
    Then the step should succeed
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id 531206
  Scenario Outline: Using jenkinsfile field with jenkinspipeline strategy
    Given I have a project
    And I have a persistent jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    Given I get project buildconfigs
    Then the output should contain 2 times:
      | 0 |
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-1" build was created
    Given the "nodejs-mongodb-example-1" build was created within 120 seconds
    And the "nodejs-mongodb-example-1" build completes
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author xiuwang@redhat.com
  # @case_id 515317 536388
  Scenario: Use Jenkins as S2I builder with plugins
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/jenkins-example/master/jenkins-with-plugins.json |
    Then the step should succeed
    And the "jenkins-master-1" build was created
    And the "jenkins-master-1" build completed
    When I run the :build_logs client command with:
      | build_name | jenkins-master-1 |
    Then the output should contain:
      | Downloading credentials-1.23                         |
      | Downloading analysis-core-1.71                       |
      | Downloading ansicolor-0.4.1                          |
      | Installing 2 Jenkins plugins from plugins/ directory |

  # @author cryan@redhat.com
  # @case_id OCP-11968 OCP-11989
  Scenario Outline: Create resource using jenkins pipeline DSL
    Given I have a project
    And I have an ephemeral jenkins v<ver> application
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                           |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    And I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP_11968/pipeline_create_resource.groovy"
    And I replace lines in "pipeline_create_resource.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest                                            |
      | editor_position | row: 1, column: 1                                        |
      | dsl_text        | <%= File.read('pipeline_create_resource.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name     | openshifttest                      |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest |
      | job_number | 1             |
      | time_out   | 60            |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=hello-openshift |
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author cryan@redhat.com
  # @case_id OCP-12075 OCP-12094
  Scenario Outline: Delete resource using jenkins pipeline DSL
    Given I have a project
    And I have an ephemeral jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/application-template.json |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                           |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | frontend |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    And I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                               |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    And I log in to jenkins
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP_12075/pipeline_delete_resource.groovy"
    And I replace lines in "pipeline_delete_resource.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest                                            |
      | editor_position | row: 1, column: 1                                        |
      | dsl_text        | <%= File.read('pipeline_delete_resource.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | openshifttest |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest |
      | job_number | 1             |
      | time_out   | 60            |
    Then the step should succeed
    Given I get project dc named "frontend"
    Then the output should contain "not found"
    Given I get project builds
    Then the output should contain "No resources found"
    Given I get project is
    Then the output should not match "origin-nodejs-sample\s+latest"
    Examples:
      | ver |
      | 1   |
      | 2   |
