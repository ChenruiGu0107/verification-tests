Feature: jenkins.feature
  # @author xiuwang@redhat.com
  # @case_id OCP-11506
  Scenario: Could change password for jenkins server--jenkins-1-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | template | jenkins-persistent |
    Then the step should succeed
    And the "jenkins" PVC becomes :bound within 300 seconds
    Given I wait for the "jenkins" service to become ready up to 300 seconds
    And I get the service pods
    Given I save the jenkins password of dc "jenkins" into the :jenkins_password clipboard
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | -u| admin:<%= cb.jenkins_password %> | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain:
      | Dashboard [Jenkins] |
    When I run the :set_env client command with:
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
  # @case_id OCP-11217 OCP-11370
  Scenario Outline: Create a new job in jenkins with OpenShift Pipeline Jenkins Plugin
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I give project admin role to the system:serviceaccount:<%= cb.proj1 %>:jenkins service account
    Then the step should succeed
    And I have a jenkins v<ver> application
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/image/language-image-templates/application-template.json |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
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
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json"
    When I perform the :jenkins_create_openshift_resources web action with:
      | job_name  | testplugin                                       |
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
  # @case_id OCP-11279 OCP-11371
  Scenario Outline: jenkins plugin can tag image in different projects use jenkins project token
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    And I have a jenkins v<ver> application
    When I run the :import_image client command with:
      | image_name | ruby                      |
      | from       | centos/ruby-25-centos7 |
      | confirm    | true                      |
    Given I have a jenkins browser
    And I log in to jenkins
    Given I find a bearer token of the system:serviceaccount:<%= cb.proj1 %>:jenkins service account
    Given evaluation of `service_account.cached_tokens.first` is stored in the :token1 clipboard
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
  # @case_id OCP-11941
  Scenario Outline: Check verbose logging in build field of openshift v3 plugin
    Given I have a project
    When I give project admin role to the default service account
    Then the step should succeed
    And I have a jenkins v<ver> application
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/image/language-image-templates/application-template.json |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
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


  # @author cryan@redhat.com
  # @case_id OCP-12389 OCP-12392
  Scenario Outline: Show annotation when build triggered by jenkins pipeline
    Given I have a project
    And I have a jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/application-template.json |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role              | admin                                             |
      | serviceaccountraw | system:serviceaccount:<%= project.name %>:default |
      | n                 | <%= project.name%>                                |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_create_openshift_build_trigger web action with:
      | job_name | testplugin |
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
  # @case_id OCP-11938 OCP-11988
  Scenario Outline: Testing workflow using openshift v3 plugin
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role              | admin                                             |
      | serviceaccountraw | system:serviceaccount:<%= project.name %>:default |
      | n                 | <%= project.name%>                                |
    Then the step should succeed
    And I have a jenkins v<ver> application
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    Given the "ruby22-sample-build-1" build was created
    And the "ruby22-sample-build-1" build completes
    And I get project routes
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | test |
    Then the step should succeed
    When I perform the :jenkins_scale_openshift_deployment web action with:
      | job_name     | test                        |
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
  # @case_id OCP-11768 OCP-11838
  Scenario Outline: Test jenkins post-build actions
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I give project edit role to the system:serviceaccount:<%= cb.proj1 %>:jenkins service account
    Then the step should succeed
    And I have a jenkins v<ver> application
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/image/language-image-templates/application-template.json |
    Then the step should succeed
    And I get project routes
    Then the output should contain "jenkins"
    Given I have a jenkins browser
    And I log in to jenkins
    When I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc470422/application-template-stibuild.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completes
    When I run the :policy_add_role_to_user client command with:
      | role              | edit                                          |
      | serviceaccountraw | system:serviceaccount:<%= cb.proj1 %>:jenkins |
      | n                 | <%= cb.proj2 %>                               |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | cancelbuildjob |
    Then the step should succeed
    When I perform the :jenkins_post_cancel_build_from_job web action with:
      | job_name      |  cancelbuildjob                               |
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
      | deployment_config | database                    |
      | store_project     | <%= cb.proj2 %>             |
    Then the step should succeed
    When I run the :rollout_latest client command with:
      | resource | database |
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
  Scenario Outline: Pipeline build, started before Jenkins is deployed, shouldn't get deleted
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given I get project builds
    Then the output should contain:
      | sample-pipeline-1 |
      | New               |
    Given I have a jenkins v2 application
    #Ensure the pre-existing build is still present after jenkins creation
    Given I get project builds
    Then the output should contain "sample-pipeline-1"
    And I wait up to 600 seconds for the steps to pass:
    """
    Given I get project builds
    Then the output should match:
      | sample-pipeline-1\s+JenkinsPipeline\s+Running |
    """

    Examples:
      | jenkins_version |
      | 1               | # @case_id OCP-11344
      | 2               | # @case_id OCP-11374

  # @author cryan@redhat.com
  # @case_id OCP-11355 OCP-11356 OCP-11357
  Scenario Outline: Delete openshift resources in jenkins with OpenShift Pipeline Jenkins Plugin
    Given I have a project
    And I have a jenkins v<jenkins_version> application
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json"
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    When I perform the :jenkins_create_openshift_resources web action with:
      | job_name  | testplugin                                 |
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
    Examples:
      | steptype       | resourcetype | resourcekey     | resourceval     | resourcejsonyaml                           | deletertype              | jenkins_version |
      | using Labels   | pod          | name            | hello-openshift |                                            | OpenShiftDeleterLabels   | 1               |
      | by Key         | pod          | hello-openshift |                 |                                            | OpenShiftDeleterList     | 1               |
      | from JSON/YAML |              |                 |                 | <%= File.read('hello-pod.json').to_json %> | OpenShiftDeleterJsonYaml | 1               |
      | using Labels   | pod          | name            | hello-openshift |                                            | OpenShiftDeleterLabels   | 2               |
      | by Key         | pod          | hello-openshift |                 |                                            | OpenShiftDeleterList     | 2               |
      | from JSON or YAML |           |                 |                 | <%= File.read('hello-pod.json').to_json %> | OpenShiftDeleterJsonYaml | 2               |

  # @author wewang@redhat.com
  # @case_id OCP-11940
  Scenario Outline: update build field of openshift v3 plugin
    Given I have a project
    When I give project admin role to the default service account
    Then the step should succeed
    And I have a jenkins v<ver> application
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | <%= project.name %>             |
    Then the step should succeed
    When I perform the :jenkins_check_build_fields web action with:
      | job_name     | <%= project.name %>         |
      | build_config | frontend                    |
      | name_space   | <%= project.name %>         |
      | token        | 12345                       |
      | commit_hash  | 456789                      |
    Then the step should succeed
    #update post-build action
    When I perform the :jenkins_check_post_build_fields web action with:
      | job_name      | <%= project.name %>         |
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
  # @case_id OCP-12425 OCP-12426
  Scenario Outline: Show annotation when deployment triggered by jenkins pipeline
    Given I have a project
    And I have a jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/application-template.json |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                           |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | <%= project.name %>             |
    Then the step should succeed
    When I perform the :jenkins_create_openshift_build_trigger web action with:
      | job_name      | <%= project.name %>         |
      | build_config  | frontend                    |
      | store_project | <%= project.name %>         |
    When I perform the :jenkins_create_openshift_deployment_trigger web action with:
      | job_name         | <%= project.name %>         |
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
  # @case_id OCP-11829 OCP-11840
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
    And I have a jenkins v<ver> application
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/image/language-image-templates/application-template.json |
    Then the step should succeed
    Given I have a jenkins browser
    Given I switch to the second user
    And I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    And I use the "<%= cb.proj2 %>" project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc470422/application-template-stibuild.json |
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
      | bldcfg    | ruby-sample-build           |
      | namespace | <%= cb.proj2 %>             |
    When I perform the :jenkins_verify_openshift_deployment web action with:
      | job_name     | openshifttest               |
      | deployconfig | frontend                    |
      | namespace    | <%= cb.proj2 %>             |
    When I perform the :jenkins_verify_openshift_service web action with:
      | job_name  | openshifttest               |
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
  # @case_id OCP-11807
  Scenario Outline: Using jenkinsfile field with jenkinspipeline strategy
    Given I have a project
    And I have a jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
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
  # @case_id OCP-10975
  Scenario Outline: Use Jenkins as S2I builder with plugins
    Given I have a project
    Given I have a jenkins v<ver> application from "<%= BushSlicer::HOME %>/features/tierN/testdata/build/tc515317_536388/jenkins-with-plugins.json"
    And the "jenkins-master-1" build was created
    And the "jenkins-master-1" build completed
    When I run the :build_logs client command with:
      | build_name | jenkins-master-1 |
    Then the output should contain:
      | credentials     |
      | analysis-core   |
      | ansicolor       |
      | plugins         |
    Examples:
      | ver |
      | 2   |

  # @author cryan@redhat.com
  # @case_id OCP-11968 OCP-11989
  Scenario Outline: Create resource using jenkins pipeline DSL
    Given I have a project
    And I have a jenkins v<ver> application
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                           |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given I obtain test data file "templates/OCP_11968/pipeline_create_resource.groovy"
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

  # @author shiywang@redhat.com
  # @case_id OCP-12325 OCP-12328
  Scenario Outline: Verify build using jenkins pipeline DSL
    Given I have a project
    And I have a jenkins v<ver> application
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
    And the "frontend-1" build was created
    And the "frontend-1" build completed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12325/pipeline_verify_build.groovy"
    And I replace lines in "pipeline_verify_build.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest                                         |
      | editor_position | row: 1, column: 1                                     |
      | dsl_text        | <%= File.read('pipeline_verify_build.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | openshifttest |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest |
      | job_number | 1             |
      | time_out   | 60            |
    Then the step should succeed
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author shiywang@redhat.com
  # @case_id OCP-12347 OCP-12349
  Scenario Outline: Verify deployment using jenkins pipeline DSL
    Given I have a project
    And I have a jenkins v<ver> application
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
    And the "frontend-1" build was created
    And the "frontend-1" build completed
    When I run the :rollout_latest client command with:
      | resource | frontend |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12347/pipeline_verify_deployment.groovy"
    And I replace lines in "pipeline_verify_deployment.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest                                              |
      | editor_position | row: 1, column: 1                                          |
      | dsl_text        | <%= File.read('pipeline_verify_deployment.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | openshifttest |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest |
      | job_number | 1             |
      | time_out   | 60            |
    Then the step should succeed
    When I run the :get client command with:
      | resource | dc |
    And the output should match:
      | frontend\s+1\s+1\s+1\s+config |
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author shiywang@redhat.com
  # @case_id OCP-12371 OCP-12374
  Scenario Outline: Verify service using jenkins pipeline DSL
    Given I have a project
    And I have a jenkins v<ver> application
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
    And the "frontend-1" build was created
    And the "frontend-1" build completed
    When I run the :rollout_latest client command with:
      | resource | frontend |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12371/pipeline_verify_service.groovy"
    And I replace lines in "pipeline_verify_service.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest                                           |
      | editor_position | row: 1, column: 1                                       |
      | dsl_text        | <%= File.read('pipeline_verify_service.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | openshifttest |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest |
      | job_number | 1             |
      | time_out   | 60            |
    Then the step should succeed
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest1 |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12371/pipeline_verify_service_failed.groovy"
    And I replace lines in "pipeline_verify_service_failed.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest1                                                 |
      | editor_position | row: 1, column: 1                                              |
      | dsl_text        | <%= File.read('pipeline_verify_service_failed.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | openshifttest1 |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest1 |
      | job_number | 1              |
      | time_out   | 60             |
    Then the step should fail
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author dyan@redhat.com
  Scenario Outline: Switch to 32bit JDK for Jenkins
    Given I have a project
    When I run the :new_app client command with:
      | template | jenkins-ephemeral                      |
      | p        | JVM_ARCH=<arch>                        |
      | p        | JENKINS_IMAGE_STREAM_TAG=jenkins:<tag> |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    When I run the :describe client command with:
      | resource | pod          |
      | l        | name=jenkins |
    Then the step should succeed
    And the output should match:
      | OPENSHIFT_JENKINS_JVM_ARCH:\\s+<arch> |
    When I execute on the pod:
      | bash |
      | -c   |
      | ls -l /etc/alternatives/java |
    Then the step should succeed
    And the output should contain "<jdk>"

    Examples:
      | arch   | tag | jdk    |
      |        | 2   | i386   | # @case_id OCP-13207
      | x86_64 | 2   | x86_64 | # @case_id OCP-13208
      |        | 1   | i386   | # @case_id OCP-13209
      | x86_64 | 1   | x86_64 | # @case_id OCP-13210

  # @author xiuwang@redhat.com
  # @case_id OCP-13109
  Scenario Outline: Add/override env vars to pipeline buildconfigs when start-build pipeline build with -e
    Given I have a project
    And I have a jenkins v<version> application
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/OCP-13259/samplepipeline.yaml |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_check_build_string_parameter web action with:
      | namespace| <%= project.name %>                 |
      | job_name | <%= project.name %>-sample-pipeline |
      | env_name | VAR1                                |
      | env_value| value1                              |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
      | env         | VAR1=newvalue   |
    Then the step should succeed
    When I perform the :jenkins_check_build_string_parameter web action with:
      | namespace| <%= project.name %>                 |
      | job_name | <%= project.name %>-sample-pipeline |
      | env_name | VAR1                                |
      | env_value| value1                              |
    Then the step should succeed
    And the "sample-pipeline-1" build completes
    When I perform the :goto_jenkins_buildlog_page web action with:
      | namespace| <%= project.name %>                |
      | job_name| <%= project.name %>-sample-pipeline |
      | job_num | 1                                   |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should contain:
      | VAR1 = newvalue|
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
      | env         | VAR2=value2     |
      | env         | VAR3=value3     |
    Then the step should succeed
    When I perform the :jenkins_check_build_string_parameter web action with:
      | namespace| <%= project.name %>                 |
      | job_name | <%= project.name %>-sample-pipeline |
      | env_name | VAR2                                |
      | env_value|                                     |
    Then the step should succeed
    When I perform the :jenkins_check_build_string_parameter web action with:
      | namespace| <%= project.name %>                 |
      | job_name | <%= project.name %>-sample-pipeline |
      | env_name | VAR3                                |
      | env_value|                                     |
    Then the step should succeed
    And the "sample-pipeline-2" build completes
    When I perform the :goto_jenkins_buildlog_page web action with:
      | namespace| <%= project.name %>                |
      | job_name| <%= project.name %>-sample-pipeline |
      | job_num | 2                                   |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should contain:
      | VAR1 = value1|
      | VAR2 = value2|
      | VAR3 = value3|

    Examples:
      | version |
      | 1       |
      | 2       |

  # @author shiywang@redhat.com
  # @case_id OCP-12163 OCP-12174
  Scenario Outline: Scale deployment using jenkins pipeline DSL
    Given I have a project
    And I have a jenkins v<ver> application
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
    And the "frontend-1" build was created
    And the "frontend-1" build completed
    When I run the :rollout_latest client command with:
      | resource | frontend |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12163/pipeline_scale_deployment.groovy"
    And I replace lines in "pipeline_scale_deployment.groovy":
      | <repl_env>   | <%= env.api_endpoint_url %> |
      | <repl_ns>    | <%= project.name %>         |
      | <repl_count> | 2                           |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest                                             |
      | editor_position | row: 1, column: 1                                         |
      | dsl_text        | <%= File.read('pipeline_scale_deployment.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name     | openshifttest                      |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest |
      | job_number | 1             |
      | time_out   | 300           |
    Then the step should succeed
    When I run the :get client command with:
      | resource | dc |
    And the output should match:
      | frontend\s+1\s+2\s+2\s+config |
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest1 |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12163/pipeline_scale_deployment.groovy"
    And I replace lines in "pipeline_scale_deployment.groovy":
      | <repl_env>   | <%= env.api_endpoint_url %> |
      | <repl_ns>    | <%= project.name %>         |
      | <repl_count> | 3                           |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest1                                            |
      | editor_position | row: 1, column: 1                                         |
      | dsl_text        | <%= File.read('pipeline_scale_deployment.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name     | openshifttest1                     |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest1 |
      | job_number | 1              |
      | time_out   | 300            |
    Then the step should succeed
    And I wait until number of replicas match "3" for replicationController "frontend-1"
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author shiywang@redhat.com
  # @case_id OCP-12219 OCP-12225
  Scenario Outline: Tag image using jenkins pipeline DSL
    Given I have a project
    And I have a jenkins v<ver> application
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
    And the "frontend-1" build was created
    And the "frontend-1" build completed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12219/tag_image.groovy"
    And I replace lines in "tag_image.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest                                            |
      | editor_position | row: 1, column: 1                                        |
      | dsl_text        | <%= File.read('tag_image.groovy').dump %>                |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name     | openshifttest                      |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest |
      | job_number | 1             |
      | time_out   | 300           |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | is   |
      | name     | myis |
    Then the step should succeed
    Then the expression should be true> image_stream("myis").exists?(user: user)
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author shiywang@redhat.com
  # @case_id OCP-12267 OCP-12271
  Scenario Outline: Trigger build using jenkins pipeline DSL
    Given I have a project
    And I have a jenkins v<ver> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/application-template.json |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                           |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12267/trigger_build.groovy"
    And I replace lines in "trigger_build.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest                                 |
      | editor_position | row: 1, column: 1                             |
      | dsl_text        | <%= File.read('trigger_build.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name     | openshifttest                      |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest  |
      | job_number | 1              |
      | time_out   | 300            |
    Then the step should succeed
    And the "frontend-1" build completed
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest1 |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12267/trigger_build_verbose.groovy"
    And I replace lines in "trigger_build_verbose.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest1                                |
      | editor_position | row: 1, column: 1                             |
      | dsl_text        | <%= File.read('trigger_build_verbose.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name     | openshifttest1                      |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest1 |
      | job_number | 1              |
      | time_out   | 300            |
    Then the step should succeed
    And the "frontend-2" build completed
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest2 |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12267/trigger_build_failed.groovy"
    And I replace lines in "trigger_build_failed.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest2                                           |
      | editor_position | row: 1, column: 1                                        |
      | dsl_text        | <%= File.read('trigger_build_failed.groovy').dump %>     |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name     | openshifttest2 |
    Then the step should succeed
    And the "frontend-3" build was created
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest2 |
      | job_number | 1              |
      | time_out   | 60             |
    Then the step should fail
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author shiywang@redhat.com
  # @case_id OCP-12297 OCP-12300
  Scenario Outline: Trigger deployment using jenkins pipeline DSL
    Given I have a project
    And I have a jenkins v<ver> application
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
    And the "frontend-1" build was created
    And the "frontend-1" build completed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12297/trigger_deployment.groovy"
    And I replace lines in "trigger_deployment.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest                                      |
      | editor_position | row: 1, column: 1                                  |
      | dsl_text        | <%= File.read('trigger_deployment.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name     | openshifttest                      |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest |
      | job_number | 1             |
      | time_out   | 300           |
    Then the step should succeed
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest1 |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12297/trigger_deployment_verbose.groovy"
    And I replace lines in "trigger_deployment_verbose.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest1                                             |
      | editor_position | row: 1, column: 1                                          |
      | dsl_text        | <%= File.read('trigger_deployment_verbose.groovy').dump %> |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name     | openshifttest1                      |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest1 |
      | job_number | 1              |
      | time_out   | 300            |
    Then the step should succeed
    When I perform the :jenkins_create_pipeline_job web action with:
      | job_name | openshifttest2 |
    Then the step should succeed
    Given I obtain test data file "templates/OCP-12297/trigger_deployment_failed.groovy"
    And I replace lines in "trigger_deployment_failed.groovy":
      | <repl_env> | <%= env.api_endpoint_url %> |
      | <repl_ns>  | <%= project.name %>         |
    # The use of the 'dump' method in dsl_text escapes the groovy content to be
    # used by watir/selenium.
    When I perform the :jenkins_pipeline_insert_script web action with:
      | job_name        | openshifttest2                                             |
      | editor_position | row: 1, column: 1                                          |
      | dsl_text        | <%= File.read('trigger_deployment_failed.groovy').dump %>  |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name     | openshifttest2 |
    Then the step should succeed
    When I perform the :jenkins_verify_job_success web action with:
      | job_name   | openshifttest2 |
      | job_number | 1              |
      | time_out   | 300            |
    Then the step should fail
    Examples:
      | ver |
      | 1   |
      | 2   |

  # @author xiuwang@redhat.com
  Scenario Outline: Using nodejs slave when do jenkinspipeline strategy
    Given I have a project
    Given I have a jenkins v<version> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | jenkins/nodejs=true |
    Given the "sample-pipeline-1" build completes

    Examples:
      | version |
      | 1       | # @case_id OCP-11308
      | 2       | # @case_id OCP-11373

  # @author wewang@redhat.com
  # @case_id OCP-11372
  Scenario: Sync builds from jenkins to openshift
    Given I have a project
    And I have a jenkins v2 application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    Given I update "maven" slave image for jenkins 2 server
    Given I update "nodejs" slave image for jenkins 2 server
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When the "sample-pipeline-1" build becomes :running
    And the "nodejs-mongodb-example-1" build becomes :running
    Then the "nodejs-mongodb-example-1" build completed
    Then the "sample-pipeline-1" build completed
    And I run the steps 2 times:
    """
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    """
    Given I get project builds
    Then the output should contain 3 times:
      | sample-pipeline |
    When the "sample-pipeline-3" build becomes :running
    And I perform the :jenkins_verify_job_text web action with:
      | namespace  | <%= project.name %>                    |
      | job_name   | <%= project.name %>-sample-pipeline    |
      | checktext  | <%= project.name %>/sample-pipeline-3  |
      | job_num    | 3                                      |
      | time_out   | 300                                    |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type           | buildconfig     |
      | object_name_or_id     | sample-pipeline |
    Then the step should succeed
    When I perform the :jenkins_verify_project_job web action with:
      | namespace  | <%= project.name %>                 |
      | job_name   | <%= project.name %>-sample-pipeline |
      | time_out   | 300                                 |
    Then the step should fail

  # @author wewang@redhat.com
  # @case_id OCP-15197
    @admin
  Scenario: Using jenkins slave maven image to do pipeline build with limited resource
    And I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/OCP-15196/limitrange.json |
      | n | <%= project.name %>                                                                                    |
    Then the step should succeed
    Given I have a jenkins v2 application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/maven-pipeline.yaml |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    Given I update "maven" slave image for jenkins 2 server
    And I run the :start_build client command with:
      | buildconfig | openshift-jee-sample |
    Then the step should succeed
    When the "openshift-jee-sample-1" build becomes :running
    And the "openshift-jee-sample-docker-1" build becomes :running
    Then the "openshift-jee-sample-docker-1" build completed
    Then the "openshift-jee-sample-1" build completed
    And a pod becomes ready with labels:
      | app=openshift-jee-sample |

  # @author xiuwang@redhat.com
  # @case_id OCP-15196
  @admin
  Scenario: Using jenkins slave nodejs image to do pipeline build with limited resource
    And I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/OCP-15196/limitrange.json |
      | n | <%= project.name %>                                                                                    |
    Then the step should succeed
    Given I have a jenkins v2 application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    Given I update "nodejs" slave image for jenkins 2 server
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When the "sample-pipeline-1" build becomes :running
    And the "nodejs-mongodb-example-1" build becomes :running
    Then the "nodejs-mongodb-example-1" build completed
    Then the "sample-pipeline-1" build completed
    And a pod becomes ready with labels:
      | name=nodejs-mongodb-example |

  # @author wewang@redhat.com
  # @case_id OCP-11400
  Scenario: Add env in the build steps of jenkins
    Given I have a project
    Given I have a jenkins v2 application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/application-template.json |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_create_freestyle_job web action with:
      | job_name | openshifttest |
    Then the step should succeed
    When I perform the :jenkins_create_openshift_build_trigger web action with:
      | job_name      | openshifttest       |
      | build_config  | frontend            |
      | store_project | <%= project.name %> |
      | var_key       | env1                |
      | var_value     | value1              |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name | openshifttest |
    Then the step should succeed
    Given the "frontend-1" build completes
    When I run the :export client command with:
      | resource | build/frontend-1 |
    Then the step should succeed
    Then the output should contain:
      | env1   |
      | value1 |

  # @case_id OCP-18220
  Scenario: Jenkins API authentication should success until the first web access
    When I have a project
    And I have a persistent jenkins v2 application
    When I perform the HTTP request:
    """
    :url: https://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login
    :method: :get
    :headers:
      :Authorization: Bearer <%= cb.user_token %>
    """
    Then the step should succeed
    And the output should contain:
      | <title>Jenkins</title> |
    And I ensure "<%= cb.jenkins_pod %>" pod is deleted
    And I wait for the "jenkins" service to become ready up to 300 seconds
    #Non-browser access to jenkins API with a Bearer
    When I perform the HTTP request:
    """
    :url: https://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login
    :method: :get
    :headers:
      :Authorization: Bearer <%= cb.user_token %>
    """
    Then the step should succeed
    And the output should contain:
      | <title>Jenkins</title> |
    #Browser access to jenkins
    Given I have a jenkins browser
    Then I log in to jenkins
    #Non-browser access to jenkins API with a Bearer
    When I perform the HTTP request:
    """
    :url: https://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login
    :method: :get
    :headers:
      :Authorization: Bearer <%= cb.user_token %>
    """
    Then the step should succeed
    And the output should contain:
      | <title>Jenkins</title> |

  # @author xiuwang@redhat.com
  # @case_id OCP-12784
  Scenario: Programmatic access to jenkins with openshift oauth
    Given I have a project
    And I have a jenkins v2 application
    And I find a bearer token of the system:serviceaccount:<%= project.name %>:jenkins service account
    And evaluation of `service_account.cached_tokens.first` is stored in the :token1 clipboard
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-1" build becomes :running
    When I perform the HTTP request:
    """
      :method: get
      :url: https://<%= cb.jenkins_dns %>/job/<%= project.name %>/job/<%= project.name %>-sample-pipeline/1/consoleText
      :headers:
        Authorization: Bearer <%= cb.token1 %>
    """
    Then the step should succeed
    And the output should contain:
      | OpenShift Build <%= project.name %>/sample-pipeline-1 |
    When I perform the HTTP request:
    """
      :method: get
      :url: https://<%= cb.jenkins_dns %>/job/<%= project.name %>/job/<%= project.name %>-sample-pipeline/1/consoleText
      :headers:
        Authorization: Bearer invaildtoken
    """
    Then the step should fail
    And the expression should be true> @result[:exitstatus] == 401

  # @author xiuwang@redhat.com
  # @case_id OCP-11990
  Scenario: Sync builds status between openshift and jenkins
    Given I have a project
    And I have a jenkins v2 application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    Given I update "nodejs" slave image for jenkins 2 server
    When I perform the :jenkins_build_now web action with:
      | job_name  | <%= project.name %>/job/<%= project.name %>-sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-1" build becomes :running
    When I perform the :jenkins_check_build_status web action with:
      | job_name     | <%= project.name %>-sample-pipeline |
      | namespace    | <%= project.name %>                 |
      | job_num      | 1          |
      | build_status | In progress|
    Then the step should succeed
    Given the "sample-pipeline-1" build completed within 300 seconds
    When I perform the :jenkins_check_build_status web action with:
      | job_name     | <%= project.name %>-sample-pipeline |
      | namespace    | <%= project.name %>                 |
      | job_num      | 1       |
      | build_status | Success |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When I run the :cancel_build client command with:
      | build_name | sample-pipeline-2 |
    Then the step should succeed
    When I perform the :jenkins_check_build_status web action with:
      | job_name     | <%= project.name %>-sample-pipeline |
      | namespace    | <%= project.name %>                 |
      | job_num      | 2       |
      | build_status | Aborted |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc                                                                                                                |
      | resource_name | sample-pipeline                                                                                                   |
      | p             | {"spec":{"strategy": {"type": "JenkinsPipeline","jenkinsPipelineStrategy": {"jenkinsfile":"uncorrect grammar"}}}} |
    Then the step should succeed
    When I perform the :jenkins_build_now web action with:
      | job_name  | <%= project.name %>/job/<%= project.name %>-sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-3" build failed
    When I perform the :jenkins_check_build_status web action with:
      | job_name     | <%= project.name %>-sample-pipeline |
      | namespace    | <%= project.name %>                 |
      | job_num      | 3      |
      | build_status | Failed |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | builds   |
      | object_name_or_id | sample-pipeline-3|
    Then the step should succeed
    When I perform the :jenkins_check_build_status web action with:
      | job_name     | <%= project.name %>-sample-pipeline |
      | namespace    | <%= project.name %>                 |
      | job_num      | 3      |
      | build_status | Failed |
    Then the step should fail
