Feature: change the policy of user/service account

  # @author anli@redhat.com
  # @case_id 479042
  @smoke
  @admin
  Scenario: Add/Remove a global role
    Given the first user is cluster-admin
    Given I have a project
    When I run the :get client command with:
      | resource   | pod     |
      | namespace  | default |
    And the output should contain:
      | READY  |
    And the output should not contain:
      | cannot |
    When I run the :oadm_remove_cluster_role_from_user admin command with:
      | role_name  | cluster-admin    |
      | user_name  | <%= user.name %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource   | pod              |
      | namespace  | default          |
    And the output should contain:
      | cannot list pods in project "default" |

  # @author xxing@redhat.com
  # @case_id 467925
  Scenario: User can view ,add, remove and modify roleBinding via admin role user
    Given I have a project
    When I run the :describe client command with:
      | resource | policyBindings |
      | name     | :default       |
    Then the output should match:
      | Role:\s+admin              |
      | Users:\s+<%= @user.name %> |
    When I run the :oadm_add_role_to_user client command with:
      | role_name | admin            |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | policyBindings |
      | name     | :default       |
    Then the output should match:
      | Role:\s+admin                                                  |
      | Users:\s+<%= @user.name %>, <%= user(1, switch: false).name %> |
    When I run the :oadm_remove_role_from_user client command with:
      | role_name | admin            |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | policyBindings |
      | name     | :default       |
    Then the output should match:
      | Role:\s+admin              |
      | Users:\s+<%= @user.name %> |
