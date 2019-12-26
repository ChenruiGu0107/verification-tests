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
    Given cluster role "cluster-admin" is added to the "first" user
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

