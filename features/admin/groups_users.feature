Feature: groups and users related features

  # @author xiaocwan@redhat.com
  # @case_id 498661
  @admin
  Scenario: Add/remove user to/from the group
    When I run the :oadm_groups_new admin command with:
      | group_name | <%= project.name %>group |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | group                     |
      | object_name_or_id | <%= project.name %>group  |
    the step should succeed
    I run the :get admin command with:
      | resource      | group |
    the step should succeed
    the output should not match:
      | <%= project.name %>group |
    """
    When I run the :oadm_groups_add_users admin command with:
      | group_name | <%= project.name %>group |
      | user_name  | <%= project.name %>user1 |
      | user_name  | <%= project.name %>user2 |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | group |
    Then the step should succeed
    And the output should match:
      | <%= project.name %>group |
      | <%= project.name %>user1 |
      | <%= project.name %>user2 |
    When I run the :oadm_groups_remove_users admin command with:
      | group_name   | <%= project.name %>group |
      | user_name    | <%= project.name %>user2 |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | group                    |
    Then the output should match:
      | <%= project.name %>user1 |
    And the output should not match:
      | <%= project.name %>user2 |

  # @author xiaocwan@redhat.com
  # @case_id 498664
  @admin
  Scenario: Create/Edit/delete the cluster group
    When I run the :oadm_groups_new admin command with:
      | group_name | <%= project.name %>group |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | group                     |
      | object_name_or_id | <%= project.name %>group  |
    the step should succeed
    I run the :get admin command with:
      | resource      | group |
    the step should succeed
    the output should not match:
      | <%= project.name %>group |
    """
    When I run the :oadm_groups_add_users admin command with:
      | group_name | <%= project.name %>group |
      | user_name  | <%= project.name %>user1 |
    Then the step should succeed

    # get group to file, edit and replace it, check by describe
    When I run the :get admin command with:
      | resource      | group |
      | resource_name | <%= project.name %>group |
      | o             | yaml  |
    Then the step should succeed
    And I save the output to file>group.yaml
    Given I delete matching lines from "group.yaml":
      | <%= project.name %>user1 |
    When I run the :replace admin command with:
      | f             | group.yaml  |
    Then the step should succeed
    And the output should match:
      | [Rr]eplaced   |
    When I run the :describe admin command with:
      | resource | group                   |
      | name     | <%= project.name %>group |
    Then the step should succeed
    And the output should not match:
      | <%= project.name %>user1 |
    
