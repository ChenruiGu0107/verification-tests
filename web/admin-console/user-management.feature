Feature: User management related

  # @author hasha@redhat.com
  # @case_id OCP-25765
  @admin
  Scenario: basic list and details pages for users with impersonate action
    Given the master version >= "4.3"
    # First user is automatically added the first time they log in.
    Given I switch to the first user
    And I open admin console in a browser
    When I run the :goto_projects_list_page web action
    Then the step should succeed
    # Second user take impersonate action
    Given I switch to the second user
    And I open admin console in a browser
    And the second user is cluster-admin
    When I perform the :check_user_in_users_page web action with:
      | text     | <%= user(0, switch: false).name %> |
      | link_url | k8s/cluster/user.openshift.io~v1~User/<%= user(0, switch: false).name %> |
    Then the step should succeed
    When I perform the :check_rolebinding_of_user web action with:
      | username |  <%= user(0, switch: false).name %> |
      | content  | No Role Bindings Found              |
    Then the step should succeed
    # impersonate the first user
    When I perform the :impersonate_one_user web action with:
      | resource_name | <%= user(0, switch: false).name %> |
      | button_text   | Impersonate User "<%= user(0, switch: false).name %>" | 
    Then the step should succeed
    # first user has no permission to access /user page
    When I perform the :check_secondary_menu_missing web action with:
      | secondary_menu | Users |
    Then the step should succeed
    When I perform the :check_impersonate_notifications web action with:
      | username |  <%= user(0, switch: false).name %> |
    Then the step should succeed
    When I run the :click_stop_impersonation web action
    Then the step should succeed
    When I perform the :check_secondary_menu web action with:
      | secondary_menu | Users |
    Then the step should succeed
    Given the first user is cluster-admin
    When I perform the :impersonate_one_user web action with:
      | resource_name | <%= user(0, switch: false).name %> |
      | button_text   | Impersonate User "<%= user(0, switch: false).name %>" |
    Then the step should succeed
    When I perform the :check_secondary_menu web action with:
      | secondary_menu | Users |
    Then the step should succeed
    When I perform the :check_rolebinding_of_user web action with:
      | username    | <%= user(0, switch: false).name %> |
      | rolebinding | cluster-admin |
      | link_url    | /k8s/cluster/clusterrolebindings/cluster-admin |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-25762
  @admin
  Scenario: Group management support on console
    Given the master version >= "4.3"
    Given the first user is cluster-admin
    And I open admin console in a browser
    When I run the :goto_groups_page web action
    Then the step should succeed

    # Create Group using default YAML and check its details
    Given admin ensures "example" group is deleted after scenario
    When I run the :create_resource_by_default_yaml web action
    Then the step should succeed
    When I perform the :check_data_in_users_table web action with:
      | resource_type | User  |
      | resource_name | user1 |
      | resource_link | /k8s/cluster/user.openshift.io~v1~User/user1 |
    Then the step should succeed
    When I perform the :check_data_in_users_table web action with:
      | resource_type | User  |
      | resource_name | user2 |
      | resource_link | /k8s/cluster/user.openshift.io~v1~User/user2 |
    Then the step should succeed

    # Remove User from Group
    When I perform the :remove_user_from_group web action with:
      | resource_name | user2 |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | group/example |
    Then the step should succeed
    And the output should contain "user1"
    And the output should not contain "user2"

    # Add Users to a Group
    When I perform the :goto_one_group_page web action with:
      | group_name | example |
    Then the step should succeed
    When I run the :click_add_users_action web action
    Then the step should succeed
    When I perform the :add_user web action with:
      | user_name | testuser2 |
    Then the step should succeed
    When I run the :click_add_more_users web action
    Then the step should succeed
    When I perform the :add_user web action with:
      | user_name | testuser3 |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed
    When I run the :describe client command with:
      | resource | group/example |
    Then the step should succeed
    And the output should contain:
      | user1 |
      | testuser2 |
      | testuser3 |
    Then the step should succeed

    # Remove Group
    When I run the :click_remove_group_action web action
    Then the step should succeed
    Given I wait for the resource "group" named "example" to disappear

  # @author xiaocwan@redhat.com
  # @case_id OCP-25763
  @admin
  Scenario: Users management on console
    Given the master version >= "4.3"
    # create fake user by oc instead of by oauth login, 
    Given an 8 character random string of type :dns952 is stored into the :my_random clipboard
    And admin ensures "fake-user-<%= cb.my_random %>" user is deleted after scenario
    When I run the :create admin command with:
      | resource_type | user                          |
      | resource_name | fake-user-<%= cb.my_random %> |
    Then the step should succeed

    Given I open admin console in a browser
    Given the first user is cluster-admin
    # delete fake user and check
    When I perform the :check_user_in_users_page web action with:
      | text          | fake-user-<%= cb.my_random %>                                       |
      | link_url      | k8s/cluster/user.openshift.io~v1~User/fake-user-<%= cb.my_random %> |
    Then the step should succeed
    When I perform the :delete_user_from_kebab web action with:
      | resource_name | fake-user-<%= cb.my_random %> |
    Then the step should succeed
    Given I wait for the resource "user" named "fake-user-<%= cb.my_random %>" to disappear within 30 seconds
    When I perform the :check_user_in_users_page web action with:
      | text          | fake-user-<%= cb.my_random %>                                       |
      | link_url      | k8s/cluster/user.openshift.io~v1~User/fake-user-<%= cb.my_random %> |
    Then the step should fail

