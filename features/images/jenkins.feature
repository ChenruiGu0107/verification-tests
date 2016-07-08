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
    When I perform the :login web action with:
      | username | admin    |
      | password | password |
    Then the step should succeed
    When I create a new project
    Then the step should succeed
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I give project edit role to the system:serviceaccount:<%= cb.proj1 %>:default service account
    When I perform the :create_job web action with:
      | job_name | testplugin |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json"
    When I perform the :create_openshift_resources web action with:
      | job_name  | testplugin                                       |
      | apiURL    | https://<%= env.master_hosts[0].hostname %>:8443 |
      | jsonfile  | <%= File.read('hello-pod.json').to_json %>       |
      | namespace | <%= cb.proj2 %>                                  |
    Then the step should succeed
