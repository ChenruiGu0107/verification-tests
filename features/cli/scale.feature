Feature: scaling related scenarios
  # @author pruan@redhat.com
  # @case_id 482264
  Scenario: Scale replicas via replicationcontrollers and deploymentconfig
    Given I have a project
    And I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | myapp                                                                   |
    Then the step should succeed
    When I expose the "myapp" service
    Then the step should succeed
    Given I wait for the "myapp" service to become ready
    When I get project replicationcontroller as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :rc_name clipboard
    When I run the :describe client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
    Then the step should succeed
    Then the output should contain:
      | <%= "Replicas:\\t1 current / 1 desired" %> |
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
      | replicas | 2                      |
    And I wait until replicationController "<%= cb.rc_name %>" with 2 replicas is ready
    And all pods in the project are ready
    Then I run the :describe client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
    Then the output should contain:
      | <%= "Replicas:\\t2 current / 2 desired" %>                             |
      | <%= "Pods Status:\\t2 Running / 0 Waiting / 0 Succeeded / 0 Failed" %> |
    # get dc name
    When I get project deploymentconfig as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :dc_name clipboard
    Then I run the :scale client command with:
      | resource | deploymentconfig  |
      | name     | <%= cb.dc_name %> |
      | replicas | 3                 |
    Then the step should succeed
    And I wait until replicationController "<%= cb.rc_name %>" with 3 replicas is ready
    And all pods in the project are ready
    # check replicas is modified
    Then I run the :describe client command with:
      | resource | dc                |
      | name     | <%= cb.dc_name %> |
    Then the step should succeed
    Then the output should contain:
      | <%= "Replicas:\\t3 current / 3 desired" %>                             |
      | <%= "Pods Status:\\t3 Running / 0 Waiting / 0 Succeeded / 0 Failed" %> |
    # scale down
    Then I run the :scale client command with:
      | resource | deploymentconfig  |
      | name     | <%= cb.dc_name %> |
      | replicas | 2                 |
    Then the step should succeed
    And all pods in the project are ready
    Then I run the :describe client command with:
      | resource | deploymentconfig  |
      | name     | <%= cb.dc_name %> |
    Then the step should succeed
    Then the output should contain:
      | <%= "Replicas:\\t2 current / 2 desired" %>                             |
      | <%= "Pods Status:\\t2 Running / 0 Waiting / 0 Succeeded / 0 Failed" %> |
    Then I run the :scale client command with:
      | resource | deploymentconfig  |
      | name     | <%= cb.dc_name %> |
      | replicas | 0                 |
    Then the step should succeed
    And all pods in the project are ready
    Then I run the :describe client command with:
      | resource | deploymentconfig  |
      | name     | <%= cb.dc_name %> |
    Then the step should succeed
    Then the output should contain:
      | <%= "Replicas:\\t0 current / 0 desired" %>                             |
      | <%= "Pods Status:\\t0 Running / 0 Waiting / 0 Succeeded / 0 Failed" %> |

    Then I run the :scale client command with:
      | resource | deploymentconfig  |
      | name     | <%= cb.dc_name %> |
      | replicas | -3                |
    Then the step should fail
    And the output should contain:
      | error: --replicas=COUNT |


