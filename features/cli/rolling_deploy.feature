Feature: rolling deployment related scenarios
  # @author pruan@redhat.com
  # @case_id 503866
  Scenario: Rolling-update pods with set maxSurge to 0
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/rolling.json |
    And I wait until replicationController "hooks-1" is ready
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hooks-1                |
      | replicas | 10                     |
    And I wait for the pod named "hooks-1-deploy" to die
    And I replace resource "dc" named "hooks":
      | maxSurge: 25% | maxSurge: 0 |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And the pod named "hooks-2-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-2-deploy" until it disappears
    And the output should contain:
      | keep 7 pods available, don't exceed 10 pods |
    And I replace resource "dc" named "hooks":
      | maxUnavailable: 25% | maxUnavailable: 50% |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And the pod named "hooks-3-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-3-deploy" until it disappears
    And the output should contain:
      | keep 5 pods available|
    And I replace resource "dc" named "hooks":
      | maxUnavailable: 50% | maxUnavailable: 80% |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And the pod named "hooks-4-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-4-deploy" until it disappears
    And the output should contain:
      | keep 2 pods available |


  # @author pruan@redhat.com
  # @case_id 503864
  Scenario: Rolling-update an invalid value of pods - Negative test
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/rolling.json |
    And I wait for the pod named "hooks-1-deploy" to die
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hooks-1                |
      | replicas | 10                     |
    And all pods in the project are ready
    And I replace resource "dc" named "hooks":
      | maxSurge: 25% | maxSurge: -10 |
    Then the step should fail
    And the output should contain:
      | invalid value '-10', Details: must be non-negative |

  # @author pruan@redhat.com
  # @case_id 503867
  Scenario: Rolling-update pods with set maxUnavabilable to 0
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/rolling.json |
    And I wait for the pod named "hooks-1-deploy" to die
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hooks-1                |
      | replicas | 10                     |
    And all pods in the project are ready
    And I replace resource "dc" named "hooks":
      | maxSurge: 25% | maxSurge: 0 |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And the pod named "hooks-2-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-2-deploy" until it disappears
    And the output should contain:
      | keep 7 pods available, don't exceed 10 pods |
    And I replace resource "dc" named "hooks":
      | maxSurge: 0 | maxSurge: 30% |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And the pod named "hooks-3-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-3-deploy" until it disappears
    And the output should contain:
      | keep 7 pods available, don't exceed 13 pods |
    And I replace resource "dc" named "hooks":
      | maxSurge: 30% | maxSurge: 60% |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And the pod named "hooks-4-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-4-deploy" until it disappears
    And the output should contain:
      | keep 7 pods available, don't exceed 16 pods |

  # @author pruan@redhat.com
  # @case_id 503865,483171
  Scenario: Rolling-update pods with default value for maxSurge/maxUnavailable
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/rolling.json |
    And I wait for the pod named "hooks-1-deploy" to die
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hooks-1                |
      | replicas | 10                     |
    And all pods in the project are ready
    And I run the :get client command with:
      | resource | dc |
      | resource_name | hooks |
      | output | yaml |
    Then the output should contain:
      | maxSurge: 25% |
      | maxUnavailable: 25%  |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    Then the step should succeed
    And the pod named "hooks-2-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-2-deploy" until it disappears
    And the output should contain:
      | keep 7 pods available, don't exceed 13 pods |
    And I replace resource "dc" named "hooks":
      | maxUnavailable: 25% | maxUnavailable: 2 |
      | maxSurge: 25% | maxSurge: 5             |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    Then the step should succeed
    And the pod named "hooks-3-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-3-deploy" until it disappears
    And the output should contain:
      | keep 8 pods available, don't exceed 15 pods |
