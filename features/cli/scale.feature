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
    And I wait until number of replicas match "2" for replicationController "<%= cb.rc_name %>"
    # get dc name
    When I get project deploymentconfig as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :dc_name clipboard
    Then I run the :scale client command with:
      | resource | deploymentconfig  |
      | name     | <%= cb.dc_name %> |
      | replicas | 3                 |
    Then the step should succeed
    And I wait until number of replicas match "3" for replicationController "<%= cb.rc_name %>"
    # scale down
    Then I run the :scale client command with:
      | resource | deploymentconfig  |
      | name     | <%= cb.dc_name %> |
      | replicas | 2                 |
    Then the step should succeed
    And I wait until number of replicas match "2" for replicationController "<%= cb.rc_name %>"
    Then I run the :scale client command with:
      | resource | deploymentconfig  |
      | name     | <%= cb.dc_name %> |
      | replicas | 0                 |
    Then the step should succeed
    And I wait until number of replicas match "0" for replicationController "<%= cb.rc_name %>"

    Then I run the :scale client command with:
      | resource | deploymentconfig  |
      | name     | <%= cb.dc_name %> |
      | replicas | -3                |
    Then the step should fail
    And the output should contain:
      | error: --replicas=COUNT |
