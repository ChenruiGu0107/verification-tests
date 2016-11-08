Feature: InitContainers

  # @author dma@redhat.com
  # @case_id 532749
  Scenario: App container run depends on initContainer results in pod
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/initContainers/init-containers-success.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    Then I run the :describe client command with:
      | resource | pod       |
      | name     | hello-pod |
    And the output should match:
      | Initialized\\s+True |
      | Ready\\s+True       |
    Given I ensure "hello-pod" pod is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/initContainers/init-containers-fail.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :failed
    When I get project pods
    And the output should contain "Init:Error"
    Then I run the :describe client command with:
      | resource | pod       |
      | name     | hello-pod |
    And the output should match:
      | Initialized\\s+False |
      | Ready\\s+False       |

  # @author dma@redhat.com
  # @case_id 532751
  Scenario: Check volume and readiness probe field in initContainer
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/initContainers/volume-init-containers.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :running
    Then I run the :describe client command with:
      | resource | pod       |
      | name     | hello-pod |
    And the output should match:
      | Initialized\\s+True |
      | Ready\\s+True       |
    Given I ensure "hello-pod" pod is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/initContainers/init-containers-readiness.yaml |
    Then the step should fail
    And the output should match:
      | spec.initContainers\[0\].readinessProbe: Invalid value.*must not be set for init containers|

  # @author dma@redhat.com
  # @case_id 532754
  Scenario: InitContainer should failed after exceed activeDeadlineSeconds
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/initContainers/init-containers-deadline.yaml |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | pod       |
      | resource_name | hello-pod |
    Then the output should match:
      | hello-pod.*DeadlineExceeded |
    """
