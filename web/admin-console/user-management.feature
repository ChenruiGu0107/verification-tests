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
    # impersonate the first user
    Given the first user is cluster-admin
    When I perform the :impersonate_one_user web action with:
      | resource_name | <%= user(0, switch: false).name %> |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I run the :check_users_secondary_menu web action
    Then the step should succeed
    """
    When I perform the :check_rolebinding_of_user web action with:
      | username    | <%= user(0, switch: false).name %> |
      | rolebinding | cluster-admin |
      | link_url    | /k8s/cluster/clusterrolebindings/cluster-admin |
    Then the step should succeed

    And cluster role "cluster-admin" is removed from the "first" user
    When I perform the :impersonate_one_user web action with:
      | resource_name | <%= user(0, switch: false).name %> |
    Then the step should succeed
    When I run the :navigate_to_admin_console web action
    Then the step should succeed
    # first user has no permission to access /user page
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I run the :check_users_secondary_menu_missing web action
    Then the step should succeed
    """
    When I perform the :check_impersonate_notifications web action with:
      | username |  <%= user(0, switch: false).name %> |
    Then the step should succeed
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I run the :click_stop_impersonation web action
    Then the step should succeed
    """
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I run the :check_users_secondary_menu web action
    Then the step should succeed
    """

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

    # check group with special characters
    Given admin ensures "_UO.Sistemas_(50000374)" group is deleted after scenario
    When I run the :oadm_groups_new admin command with:
      | group_name | _UO.Sistemas_(50000374) |
    Then the step should succeed
    When I run the :goto_groups_page web action
    Then the step should succeed
    When I perform the :check_resource_item_name web action with:
      | resource_name | _UO.Sistemas_(50000374) |
    Then the step should succeed


  # @author xiaocwan@redhat.com
  # @case_id OCP-25763
  @admin
  Scenario: Users management on console
    Given the master version >= "4.3"
    # create fake user by oc instead of by oauth login,
    Given an 8 character random string of type :dns952 is stored into the :my_random clipboard
    And admin ensures "fake-user-<%= cb.my_random %>" user is deleted after scenario
    When I run the :create_user admin command with:
      | username | fake-user-<%= cb.my_random %> |
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

  # @author hasha@redhat.com
  # @case_id OCP-19675
  @admin
  Scenario: RBAC access check for cluster-wide/project-wide workload resources
    Given the master version >= "4.3"
    Given I have a project
    Then evaluation of `project.name` is stored in the :project1_name clipboard

    #user can view pod list only of another project when granted list permisson but without view detail permisson
    Given I obtain test data file "deployment/simpledc.json"
    When I run the :create client command with:
      | f | simpledc.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=hello-openshift |
    Then evaluation of `pod.name` is stored in the :test_pod clipboard
    Given I obtain test data file "rbac/list_pod_role.yaml"
    When I run the :create client command with:
      | f | list_pod_role.yaml |
    Then the step should succeed
    When I run the :create_rolebinding admin command with:
      | name  | list-pod                            |
      | user  | <%= user(1, switch: false).name %>  |
      | role  | list-pod                            |
      | n     | <%= cb.project1_name %>             |
    Then the step should succeed
    Given I switch to the second user
    Given I have a project
    Given I open admin console in a browser
    When I access the "k8s/ns/<%= cb.project1_name %>/pods" path in the web console
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | <%= cb.test_pod %> |
    Then the step should succeed
    When I perform the :goto_one_pod_page web action with:
      | project_name  | <%= cb.project1_name %> |
      | resource_name | <%= cb.test_pod %>      |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | cannot get resource "pods" |
    Then the step should succeed

    #normal user
    When I run the :check_administration_menu_for_normal_user web action
    Then the step should succeed
    When I perform the :goto_rolebinding_list_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    When I perform the :check_page_not_match web action with:
      | content | Binding Type |
    Then the step should succeed
    When I run the :goto_storageclass_page web action
    Then the step should succeed
    When I run the :check_create_button_missing web action
    Then the step should succeed
    When I access the "k8s/cluster/namespaces" path in the web console
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | cannot list resource "namespaces" |
    Then the step should succeed

    #clusteradmin user
    Given the second user is cluster-admin
    When I run the :goto_allnamespaces_rolebinding_list_page web action
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | Binding Type |
    Then the step should succeed
    When I run the :check_administration_menu_for_admin_user web action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-24281
  Scenario: RBAC check to normal operations for users with view access
    Given the master version >= "4.2"
    Given I have a project
    Then evaluation of `project.name` is stored in the :project1_name clipboard
    Given I obtain test data file "deployment/simpledc.json"
    When I run the :create client command with:
      | f | simpledc.json |
    Then the step should succeed
    Given I give project view role to the second user

    Given I switch to the second user
    Given I open admin console in a browser
    When I perform the :check_page_contains web action with:
      | content | <%= cb.project1_name %> |
    Then the step should succeed
    When I perform the :check_no_create_button_on_list_page web action with:
      | project_name | <%= cb.project1_name %> |
    Then the step should succeed
    When I perform the :check_kebab_items_disabled_on_list_page web action with:
      | project_name  | <%= cb.project1_name %> |
      | resource_name | hooks                   |
    Then the step should succeed

    When I perform the :check_no_action_button_on_resource_page web action with:
      | project_name | <%= cb.project1_name %> |
      | dc_name      | hooks                   |
    Then the step should succeed
    When I perform the :check_no_save_button_on_resource_page web action with:
      | project_name | <%= cb.project1_name %> |
      | dc_name      | hooks                   |
    Then the step should succeed

    When I perform the :check_no_edit_links_on_detail_page web action with:
      | project_name | <%= cb.project1_name %> |
      | dc_name      | hooks                   |
    Then the step should succeed

    Given I have a project
    Then evaluation of `project.name` is stored in the :project2_name clipboard
    When I perform the :goto_project_pods_list_page web action with:
      | project_name | <%= cb.project2_name %> |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Create |
    Then the step should succeed
    When I perform the :switch_to_project web action with:
      | project_name | <%= cb.project1_name %> |
    Then the step should succeed
    When I run the :check_yaml_create_button_missing web action
    Then the step should succeed
