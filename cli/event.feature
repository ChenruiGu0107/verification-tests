Feature: Event related scenarios

  # @author yanpzhan@redhat.com
  # @case_id OCP-10136
  Scenario: Project should only watch its owned cache events
    When I run the :new_project client command with:
      | project_name | eventcache532269 |
    Then the step should succeed
    Given I switch to the second user
    When I run the :new_project client command with:
      | project_name | eventcache532269-1 |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                              |
      | user_name | <%= user(0, switch: false).name %> |
      | n         | eventcache532269-1                 |
    Then the step should succeed
    Given I switch to the first user
    When I run the :get background client command with:
      | resource | secrets          |
      | o        | name             |
      | n        | eventcache532269 |
      | w        | true             |
    Then the step should succeed

    # Cucumber runs fast. If not wait here, oc get --watch would be killed at
    # once and have empty output, so wait some time for the output to show up
    Given 20 seconds have passed
    When I terminate last background process
    And evaluation of `@result[:response]` is stored in the :watchevent clipboard

    When I run the :get background client command with:
      | resource | secrets            |
      | o        | name               |
      | n        | eventcache532269-1 |
      | w        | true               |
    Then the step should succeed

    # Same reason as above
    Given 20 seconds have passed
    When I terminate last background process
    And evaluation of `@result[:response]` is stored in the :watchevent1 clipboard

    When I run the :get background client command with:
      | resource | secrets          |
      | o        | name             |
      | n        | eventcache532269 |
      | w        | true             |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | secrets            |
      | n           | eventcache532269-1 |
      | all         |                    |
    Then the step should succeed

    # Same reason as above
    Given 20 seconds have passed
    When I terminate last background process
    And the output should equal "<%= cb.watchevent %>"

    When I run the :get background client command with:
      | resource | secrets            |
      | o        | name               |
      | n        | eventcache532269-1 |
      | w        | true               |
    Then the step should succeed

    # Same reason as above
    Given 20 seconds have passed
    When I terminate last background process
    And the expression should be true> @result[:response] != "<%= cb.watchevent1 %>"

  # @author chezhang@redhat.com
  # @case_id OCP-10622
  @admin
  @destructive
  Scenario: Node events should be logged
    Given I have a project
    Given I store the schedulable nodes in the :nodes clipboard
    Given I register clean-up steps:
    """
    I run the :oadm_manage_node admin command with:
      | node_name   | <%= cb.nodes[0].name %> |
      | schedulable | true                    |
    the step should succeed
    """
    When I run the :oadm_manage_node admin command with:
      | node_name   | <%= cb.nodes[0].name %> |
      | schedulable | false                   |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe admin command with:
      | resource | node                    |
      | name     | <%= cb.nodes[0].name %> |
    Then the output should match:
      | Normal\\s+NodeNotSchedulable.*Node <%= cb.nodes[0].name %> status is now: NodeNotSchedulable |
    """
    When I run the :oadm_manage_node admin command with:
      | node_name   | <%= cb.nodes[0].name %> |
      | schedulable | true                    |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe admin command with:
      | resource | node                    |
      | name     | <%= cb.nodes[0].name %> |
    Then the output should match:
      | Normal\\s+NodeSchedulable.*Node <%= cb.nodes[0].name %> status is now: NodeSchedulable |
    """
