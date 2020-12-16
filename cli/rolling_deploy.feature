Feature: rolling deployment related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-11516
  Scenario: Rolling-update pods with set maxSurge to 0
    Given I have a project
    Given I obtain test data file "deployment/rolling.json"
    When I run the :create client command with:
      | f | rolling.json |
    #And I wait until replicationController "hooks-1" is ready
    #And I wait for the pod named "hooks-1-deploy" to die
    Then I run the :scale client command with:
      | resource | dc    |
      | name     | hooks |
      | replicas | 3     |
    #And I wait for the pod named "hooks-1-deploy" to die
    Given number of replicas of "hooks" deployment config becomes:
      | desired   | 3 |
      | current   | 3 |
      | updated   | 3 |
      | available | 3 |
    And I replace resource "dc" named "hooks":
      | maxSurge: 25% | maxSurge: 0 |
    Then the step should succeed
    When I run the :rollout_latest client command with:
      | resource | dc/hooks |
    Then the step should succeed
    And the pod named "hooks-2-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-2-deploy" until it becomes :succeeded
    And the output should contain:
      | keep 2 pods available, don't exceed 3 pods |
    And I replace resource "dc" named "hooks":
      | maxUnavailable: 25% | maxUnavailable: 50% |
    Then the step should succeed
    When I run the :rollout_latest client command with:
      | resource | dc/hooks |
    Then the step should succeed
    And the pod named "hooks-3-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-3-deploy" until it becomes :succeeded
    And the output should contain:
      | keep 2 pods available|
    And I replace resource "dc" named "hooks":
      | maxUnavailable: 50% | maxUnavailable: 80% |
    Then the step should succeed
    When I run the :rollout_latest client command with:
      | resource | dc/hooks |
    Then the step should succeed
    And the pod named "hooks-4-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-4-deploy" until it becomes :succeeded
    And the output should contain:
      | keep 1 pods available |

  # @author pruan@redhat.com
  # @case_id OCP-10686
  Scenario: Rolling-update an invalid value of pods - Negative test
    Given I have a project
    Given I obtain test data file "deployment/rolling.json"
    When I run the :create client command with:
      | f | rolling.json |
    And I wait for the pod named "hooks-1-deploy" to die
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hooks-1                |
      | replicas | 10                     |
    And 10 pods become ready with labels:
      | name=hello-openshift |
    And I replace resource "dc" named "hooks":
      | maxSurge: 25% | maxSurge: -10 |
    Then the step should fail
    And the output should match:
      | .*nvalid value.*-10.*must be non-negative |

  # @author pruan@redhat.com
  # @case_id OCP-11744
  Scenario: Rolling-update pods with set maxUnavabilable to 0
    Given I have a project
    Given I obtain test data file "deployment/rolling.json"
    When I run the :create client command with:
      | f | rolling.json |
    #And I wait for the pod named "hooks-1-deploy" to die
    Then I run the :scale client command with:
      | resource | dc    |
      | name     | hooks |
      | replicas | 3     |
    And 3 pods become ready with labels:
      | name=hello-openshift |
    And I replace resource "dc" named "hooks":
      | maxSurge: 25%       | maxSurge: 10%       |
      | maxUnavailable: 25% | maxUnavailable: 0 |
    Then the step should succeed
    When I run the :rollout_latest client command with:
      | resource | dc/hooks |
    Then the step should succeed
    And the pod named "hooks-2-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-2-deploy" until it becomes :succeeded
    And the output should contain:
      | keep 3 pods available, don't exceed 4 pods |
    And I replace resource "dc" named "hooks":
      | maxSurge: 10% | maxSurge: 30% |
    Then the step should succeed
    When I run the :rollout_latest client command with:
      | resource | dc/hooks |
    Then the step should succeed
    And the pod named "hooks-3-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-3-deploy" until it becomes :succeeded
    And the output should contain:
      | keep 3 pods available, don't exceed 4 pods |
    And I replace resource "dc" named "hooks":
      | maxSurge: 30% | maxSurge: 60% |
    Then the step should succeed
    When I run the :rollout_latest client command with:
      | resource | dc/hooks |
    Then the step should succeed
    And the pod named "hooks-4-deploy" becomes ready
    Given I collect the deployment log for pod "hooks-4-deploy" until it becomes :succeeded
    And the output should contain:
      | keep 3 pods available, don't exceed 5 pods |
