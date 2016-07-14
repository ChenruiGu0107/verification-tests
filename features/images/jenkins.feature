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
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route.dns(by: user) %> |
    When I perform the :login web action with:
      | username | admin    |
      | password | password |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> /Dashboard \[Jenkins\]/ =~ browser.title
    """
    When I run the :check_openshift_pipeline_jenkins_plugin web action
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain "OpenShift Pipeline Jenkins Plugin"
    When I perform the :create_freestyle_project web action with:
      | job_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :add_build_string_parameter web action with:
      | job_name         | <%= project.name %> |
      | string_parameter | NAMESPACE           |
    Then the step should succeed
    When I perform the :create_openshift_build_trigger web action with:
      | job_name      | <%= project.name %>         |
      | api_endpoint  | <%= env.api_endpoint_url %> |
      | build_config  | frontend                    |
      | store_project | NAMESPACE                   |
    Then the step should succeed
    When I perform the :build_with_string_parameter web action with:
      | job_name        | <%= project.name %> |
      | build_parameter | <%= project.name %> |
    Then the step should succeed
    And the "frontend-1" build was created
    And the "frontend-1" build completed
    When I perform the :build_with_string_parameter web action with:
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
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/      |
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I perform the :jenkins_login web action with:
      | username | admin    |
      | password | password |
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
