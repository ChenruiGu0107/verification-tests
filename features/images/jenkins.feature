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
