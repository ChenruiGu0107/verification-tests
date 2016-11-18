Feature: Seccomp

  # @author wmeng@redhat.com
  # @case_id 539049
  Scenario: seccomp=unconfined used by default
    Given I have a project
    When I run the :create client command with:
      | filename  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When  I run the :describe client command with:
      | resource | pod             |
      | name     | hello-openshift |
    Then the output should contain:
      | Security:[seccomp=unconfined] |
    When I execute on the pod:
      | grep | Seccomp | /proc/self/status |
    Then the output should contain:
      | 0 |
    And the output should not contain:
      | 2 |
