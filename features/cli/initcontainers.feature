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
