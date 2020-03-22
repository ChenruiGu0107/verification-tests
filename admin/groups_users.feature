Feature: groups and users related features

  # @author xiaocwan@redhat.com
  # @case_id OCP-12198
  @admin
  Scenario: Create/Edit/delete the cluster group
    Given I have a project
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
    And I save the output to file> group.yaml
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

  # @author xiaocwan@redhat.com
  # @case_id OCP-12040
  @admin
  Scenario: Add/remove view role to the project group in one or all projects
    Given admin creates a project
    Then evaluation of `project.name` is stored in the :project1 clipboard
    Given admin creates a project
    Then evaluation of `project.name` is stored in the :project2 clipboard

    When I run the :oadm_groups_new admin command with:
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
    Then the step should succeed
    Given admin ensures "<%= cb.project1 %>-<%= cb.project2 %>-group" group is deleted after scenario
    When I run the :oadm_groups_add_users admin command with:
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | user_name  | <%= user(0, switch: false).name %>          |
    Then the step should succeed

    When I run the :policy_add_role_to_group admin command with:
      | role       | view                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project1 %>                          |
    Then the step should succeed
    When I switch to the first user
    And I wait for the "<%= cb.project1 %>" projects to appear
    And I wait for the resource "project" named "<%= cb.project2 %>" to disappear
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | n    | <%= cb.project1 %> |
    Then the step should fail
    And the output should match "cannot create .* in (project|the namespace).*<%= cb.project1 %>"
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project1 %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should fail
    And the output should match "cannot list .* in (project|the namespace).*<%= cb.project2 %>"

    When I run the :policy_add_role_to_group admin command with:
      | role       | view                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project2 %>                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should succeed

    When I run the :policy_remove_role_from_group admin command with:
      | role       | view                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project1 %>                          |
    And I run the :policy_remove_role_from_group admin command with:
      | role       | view                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project2 %>                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project1 %> |
    Then the step should fail
    And the output should match "cannot list .* in (project|the namespace).*<%= cb.project1 %>"
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should fail
    And the output should match "cannot list .* in (project|the namespace).*<%= cb.project2 %>"

  # @author xiaocwan@redhat.com
  # @case_id OCP-11155
  @admin
  Scenario: Add/remove edit and admin role to the cluster group in one or more projects
    Given admin creates a project
    Then evaluation of `project.name` is stored in the :project1 clipboard
    Given admin creates a project
    Then evaluation of `project.name` is stored in the :project2 clipboard

    When I run the :oadm_groups_new admin command with:
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
    Then the step should succeed
    Given admin ensures "<%= cb.project1 %>-<%= cb.project2 %>-group" group is deleted after scenario
    When I run the :oadm_groups_add_users admin command with:
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | user_name  | <%= user(0, switch: false).name %>          |
    Then the step should succeed

    When I run the :policy_add_role_to_group admin command with:
      | role       | admin                                       |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project1 %>                          |
    Then the step should succeed
    When I switch to the first user
    And I wait for the "<%= cb.project1 %>" projects to appear
    And I wait for the resource "project" named "<%= cb.project2 %>" to disappear
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | n          | <%= cb.project1 %>                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project1 %> |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role       | edit                                        |
      | user_name  | <%= user(1, switch: false).name %>          |
      | n          | <%= cb.project1 %>                          |
    Then the step should succeed
    When I run the :policy_remove_role_from_user client command with:
      | role       | edit                                        |
      | user_name  | <%= user(1, switch: false).name %>          |
      | n          | <%= cb.project1 %>                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should fail
    And the output should match "cannot list .* in (project|the namespace).*<%= cb.project2 %>"

    When I run the :policy_add_role_to_group admin command with:
      | role       | edit                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project2 %>                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | n          | <%= cb.project2 %>                          |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role       | edit                                        |
      | user_name  | <%= user(1, switch: false).name %>          |
      | n          | <%= cb.project2 %>                          |
    Then the step should fail
    And the output should contain "User "<%= user.name %>" cannot"

    When I run the :policy_remove_role_from_group admin command with:
      | role       | admin                                       |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project1 %>                          |
    And I run the :policy_remove_role_from_group admin command with:
      | role       | edit                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project2 %>                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project1 %> |
    Then the step should fail
    And the output should match "cannot list .* in (project|the namespace).*<%= cb.project1 %>"
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should fail
    And the output should match "cannot list .* in (project|the namespace).*<%= cb.project2 %>"

  # @author scheng@redhat.com
  # @case_id OCP-12132
  @admin
  Scenario: Cluster-admin can add and remove groups for user object
    Given I restore user's context after scenario
    And a 5 character random string is stored into the :group_name clipboard
    And admin ensures "<%= cb.group_name %>" groups is deleted after scenario
    Given I have a project
    And evaluation of `user.name` is stored in the :user_name clipboard
    Given I run the :oadm_groups_new admin command with:
      | group_name | <%= cb.group_name %> |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | user                |
      | resource_name | <%= cb.user_name %> |
      | p             | {"groups": ["a:b"]} |
    Then the step should fail
    When I run the :patch admin command with:
      | resource      | user                |
      | resource_name | <%= cb.user_name %> |
      | p             | {"groups": ["a%b"]} |
    Then the step should fail
    When I run the :patch admin command with:
      | resource      | user                                 |
      | resource_name | <%= cb.user_name %> |
      | p             | {"groups": ["<%= cb.group_name %>"]} |
    Then the step should succeed
