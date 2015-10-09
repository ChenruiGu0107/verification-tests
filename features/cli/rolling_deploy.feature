Feature: rolling deployment related scenarios
  # @author pruan@redhat.com
  # @case_id 503866
  Scenario: Rolling-update pods with set maxSurge to 0
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/rolling.json |
    And I wait until replicationController "hooks-1" is ready
    And all pods in the project are ready
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
    And I run the :logs client command with:
      | pod_name | hooks-2-deploy |
    Then the step should succeed
    And the output should contain:
      | Scaling up hooks-2 from 0 to 10, scaling down hooks-1 from 10 to 0 (keep 7 pods available, don't exceed 10 pods) |
    And I wait for the pod named "hooks-2-deploy" to die
    And I replace resource "dc" named "hooks":
      | maxUnavailable: 25% | maxUnavailable: 50% |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And the pod named "hooks-3-deploy" becomes ready
    And I run the :logs client command with:
      | pod_name | hooks-3-deploy |
    Then the step should succeed
    And the output should contain:
      | keep 5 pods available|
    And I wait for the pod named "hooks-3-deploy" to die
    And I replace resource "dc" named "hooks":
      | maxUnavailable: 50% | maxUnavailable: 80% |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And the pod named "hooks-4-deploy" becomes ready
    And I run the :logs client command with:
      | pod_name | hooks-4-deploy |
    Then the step should succeed
    And the output should contain:
      | keep 2 pods available |


  # @author pruan@redhat.com
  # @case_id 503864
  Scenario: Rolling-update an invalid value of pods - Negative test
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/rolling.json |
    And I wait until replicationController "hooks-1" is ready
    And all pods in the project are ready
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hooks-1                |
      | replicas | 10                     |
    And I wait for the pod named "hooks-1-deploy" to die
    And I replace resource "dc" named "hooks":
      | maxSurge: 25% | maxSurge: -10 |
    Then the step should fail
    And the output should contain:
      | emplate.strategy.rollingParams.maxSurge: invalid value '-10', Details: must be non-negative |

  # @author pruan@redhat.com
  # @case_id 503867
  Scenario: Rolling-update pods with set maxUnavabilable to 0
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/rolling.json |
    And I wait until replicationController "hooks-1" is ready
    And all pods in the project are ready
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
    And I run the :logs client command with:
      | pod_name | hooks-2-deploy |
    Then the step should succeed
    And the output should contain:
      | Scaling up hooks-2 from 0 to 10, scaling down hooks-1 from 10 to 0 (keep 7 pods available, don't exceed 10 pods) |
    And I wait for the pod named "hooks-2-deploy" to die
    And I replace resource "dc" named "hooks":
      | maxSurge: 0 | maxSurge: 30% |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And the pod named "hooks-3-deploy" becomes ready
    And I run the :logs client command with:
      | pod_name | hooks-3-deploy |
    Then the step should succeed
    And the output should contain:
      | RollingUpdater: Scaling up hooks-3 from 0 to 10, scaling down hooks-2 from 10 to 0 (keep 7 pods available, don't exceed 13 pods) |
    And I wait for the pod named "hooks-3-deploy" to die
    And I replace resource "dc" named "hooks":
      | maxSurge: 30% | maxSurge: 60% |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And the pod named "hooks-4-deploy" becomes ready
    And I run the :logs client command with:
      | pod_name | hooks-4-deploy |
    Then the step should succeed
    And the output should contain:
      | RollingUpdater: Scaling up hooks-4 from 0 to 10, scaling down hooks-3 from 10 to 0 (keep 7 pods available, don't exceed 16 pods) |
