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
  # @case_id 509045
  # @bug_id 1277101
  @admin
  Scenario: The namespace will not be deleted until all pods gracefully terminate
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/0.json  |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/10.json |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/20.json |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/40.json |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/default.json |
    Given all pods in the project are ready
    Given the project is deleted
    Given 10 seconds have passed
    When I run the :get admin command with:
      | resource | namespaces |
    Then the output should contain "<%= project.name %>"
    When I get project pods
    Then the step should succeed
    And the output should contain 3 times:
      | Terminating |
    Given 30 seconds have passed
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

  # @author cryan@redhat.com
  # @case_id 509046
  Scenario: Verify pod is gracefully deleted when DeletionGracePeriodSeconds is specified.
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/10.json |
    Given the pod named "grace10" becomes ready
    When I run the :get client command with:
      | resource | pods |
      | resource_name | grace10 |
      | o | yaml |
    Then the output should contain "terminationGracePeriodSeconds: 10"
    When I run the :delete client command with:
      | object_type | pod |
      | l | name=graceful |
    Then the step should succeed
    When I get project pods
    Then the step should succeed
    And the output should contain "Terminating"
    Given 10 seconds have passed
    When I get project pods
    Then the step should succeed
    And the output should not contain "Terminating"
    And the output should not contain "Running"

  # @author cryan@redhat.com
  # @case_id 509042
  Scenario: Pod should be immediately deleted if TerminationGracePeriodSeconds is 0
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/0.json |
    Given the pod named "grace0" becomes ready
    When I run the :get client command with:
      | resource | pods |
      | resource_name | grace0 |
      | o | yaml |
    Then the output should contain "terminationGracePeriodSeconds: 0"
    When I run the :delete client command with:
      | object_type | pod |
      | l | name=graceful |
    Then the step should succeed
    When I get project pods
    Then the step should succeed
    And the output should not contain "Terminating"
    And the output should not contain "Running"
