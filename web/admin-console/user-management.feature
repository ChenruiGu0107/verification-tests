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
      | kebab_item    | Impersonate User "<%= user(0, switch: false).name %>" |
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
      | kebab_item    | Impersonate User "<%= user(0, switch: false).name %>" |
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
    When I run the :new_app client command with:
      | app_repo | centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=ruby-ex-1 |
    Then evaluation of `pod.name` is stored in the :test_pod clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/rbac/list_pod_role.yaml |
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
    When I perform the :check_page_not_match web action with:
      | content | Cluster-wide Role Bindings |
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
    When I perform the :goto_rolebinding_list_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | Cluster-wide Role Bindings |
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | Binding Type |
    Then the step should succeed
    When I run the :check_administration_menu_for_admin_user web action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-19727
  @admin
  @destructive
  Scenario: Check rolebinding for different scope of roles with same name
    Given the master version >= "4.2"
    Given the first user is cluster-admin
    Given admin ensures "list-pod" role is deleted from the "default" project after scenario
    Given admin ensures "auto-test-metrics-reader" cluster_role is deleted after scenario
    Given admin ensures "uiautoocp19727-rb" role_binding is deleted from the "default" project after scenario
    Given admin ensures "uiautoocp19727-rb" cluster_role_binding is deleted after scenario

    # create project role and cluster role in case we had destructive changes for existing roles
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/rbac/list_pod_role.yaml |
      | n | default |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/rbac/metrics-reader-cluster-role.yaml |
    Then the step should succeed

    Given I open admin console in a browser
    When I run the :goto_rolebinding_creation_page web action
    Then the step should succeed
    When I perform the :create_namespace_rolebinding web action with:
      | rolebinding_name      | uiautoocp19727-rb   |
      | rolebinding_namespace | default             |
      | role_name             | list-pod            |
      | subject_type          | User                |
      | subject_name          | uiautoOCP19727-user |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | rolebinding |
      | n        | default     |
    Then the step should succeed
    And the output should contain "uiautoocp19727-rb"
    """

    When I run the :goto_rolebinding_creation_page web action
    Then the step should succeed
    When I perform the :create_cluster_rolebinding web action with:
      | rolebinding_name | uiautoocp19727-rb        |
      | role_name        | auto-test-metrics-reader |
      | subject_type     | User                     |
      | subject_name     | uiautoOCP19727-user      |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource | clusterrolebinding |
    Then the step should succeed
    And the output should contain "uiautoocp19727-rb"
    """

    When I perform the :goto_rolebinding_list_page web action with:
      | project_name | default |
    Then the step should succeed
    When I perform the :filter_by_role_or_subject web action with:
      | role_name | uiautoocp19727-rb |
    Then the step should succeed
    When I perform the :check_namespace_rolebinding_name web action with:
      | project_name     | default           |
      | rolebinding_name | uiautoocp19727-rb |
    Then the step should succeed
    When I perform the :check_cluster_rolebinding_name web action with:
      | rolebinding_name | uiautoocp19727-rb |
    Then the step should succeed
    When I perform the :check_namespace_role_reference web action with:
      | project_name | default  |
      | role_name    | list-pod |
    Then the step should succeed
    When I perform the :check_cluster_role_reference web action with:
      | role_name | auto-test-metrics-reader |
    Then the step should succeed

    # check RoleBindings for a Role/ClusterRole is correctly listed on its RoleBinding tab
    When I perform the :goto_namespace_role_rolebinding_page web action with:
      | project_name | default  |
      | role_name    | list-pod |
    Then the step should succeed
    When I perform the :check_namespace_rolebinding_name web action with:
      | project_name     | default           |
      | rolebinding_name | uiautoocp19727-rb |
    Then the step should succeed
    When I perform the :goto_cluster_role_rolebinding_page web action with:
      | role_name | auto-test-metrics-reader |
    Then the step should succeed
    When I perform the :check_cluster_rolebinding_name web action with:
      | rolebinding_name | uiautoocp19727-rb |
    Then the step should succeed
