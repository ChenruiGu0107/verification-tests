Feature: oc_delete.feature

  # @author cryan@redhat.com
  # @case_id 509041
  Scenario: Gracefully delete a pod with '--grace-period' option
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/10.json |
    Given the pod named "grace10" becomes ready
    When I run the :get client command with:
      | resource | pods |
      | resource_name | grace10 |
      | o | yaml |
    Then the output should contain "terminationGracePeriodSeconds"
    When I run the :delete client command with:
      | object_type | pod |
      | l | name=graceful |
      | grace-period | 20 |
    Then the step should succeed
    Given 15 seconds have passed
    When I get project pods
    Then the step should succeed
    And the output should contain "Terminating"
    #The full 20 seconds have passed after this step
    Given 5 seconds have passed
    When I get project pods
    Then the step should succeed
    And the output should not contain "Terminating"
    And the output should not contain "Running"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/10.json |
    Given the pod named "grace10" becomes ready
    When I run the :get client command with:
      | resource | pods |
      | resource_name | grace10 |
      | o | yaml |
    Then the output should contain "terminationGracePeriodSeconds"
    When I run the :delete client command with:
      | object_type | pod |
      | l | name=graceful |
      | grace-period | 0 |
    Then the step should succeed
    When I get project pods
    Then the step should succeed
    And the output should not contain "Terminating"
    And the output should not contain "Running"

  # @author cryan@redhat.com
  # @case_id 509040
  Scenario: Default termination grace period is 30s if it's not set
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/default.json |
    Given the pod named "grace-default" becomes ready
    When I run the :get client command with:
      | resource | pods |
      | resource_name | grace-default |
      | o | yaml |
    Then the output should contain "terminationGracePeriodSeconds: 30"
    When I run the :delete client command with:
      | object_type | pod |
      | l | name=graceful |
    Then the step should succeed
    Given 20 seconds have passed
    When I get project pods
    Then the step should succeed
    And the output should contain "Terminating"
    Given 11 seconds have passed
    When I get project pods
    Then the step should succeed
    And the output should not contain "Terminating"
    And the output should not contain "Running"
