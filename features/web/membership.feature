Feature: memberships related features via web

  # @author etrott@redhat.com
  # @case_id OCP-11651
  Scenario: Manage project membership about groups
    Given the master version >= "3.4"
    Given I have a project
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Groups              |
      | name         | test_group          |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Groups              |
      | name         | test_group          |
      | role         | basic-user          |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
    Then the output should contain:
      | basic-user |
      | test_group |
    When I perform the :delete_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Groups              |
      | name         | test_group          |
      | role         | basic-user          |
    Then the step should succeed
    And I run the :get client command with:
      | resource     | rolebinding |
    Then the output should not contain:
      | basic-user |
      | test_group |


  # @author etrott@redhat.com
  # @case_id OCP-11843
  Scenario: Manage project membership about users
    Given the master version >= "3.4"
    Given I have a project
    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | <%= user.name %>    |
      | role         | admin               |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | count        | 1                   |
    Then the step should succeed
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | test_user           |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | test_user           |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | count        | 2                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding        |
    Then the output should contain:
      | basic-user|
      | test_user |
    When I perform the :delete_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | test_user           |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | count        | 1                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
    Then the output should not contain:
      | basic-user |
      | test_user  |
    When I perform the :check_entry_content_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %>  |
      | tab_name     | Service Accounts     |
      | namespace    | <%= project.name %>  |
      | name         | builder              |
      | role         | system:image-builder |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | <%= project.name %> |
      | name         | deployer            |
      | role         | system:deployer     |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | count        | 2                   |
    Then the step should succeed
    When I perform the :add_sa_role_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | <%= project.name %> |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | <%= project.name %> |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | count        | 3                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
    Then the output should contain:
      | basic-user |
      | test.sa    |
    When I perform the :delete_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | <%= project.name %> |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | count        | 2                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
    Then the output should not contain:
      | basic-user |
      | test.sa    |
    When I perform the :add_role_on_membership_with_typed_namespace web console action with:
      | project_name  | <%= project.name %> |
      | tab_name      | Service Accounts    |
      | old_namespace | <%= project.name %> |
      | namespace     | default             |
      | name          | test.sa             |
      | role          | basic-user          |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | default             |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | count        | 3                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding|
    Then the output should contain:
      | basic-user |
      | test.sa    |
    When I perform the :delete_role_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | default             |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | count        | 2                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
    Then the output should not contain:
      | basic-user |
      | test.sa    |


  # @author etrott@redhat.com
  # @case_id OCP-12099
  Scenario: Check rolebinding duplication when editing membership
    Given the master version >= "3.4"
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role      | view                |
      | user name | star                |
      | n         | <%= project.name %> |
    Then the step should succeed
    And I run the :export client command with:
      | resource      | rolebinding |
      | name          | view        |
    Then the step should succeed
    And I save the output to file> rolebinding_view.yaml
    When I run oc create over "rolebinding_view.yaml" replacing paths:
      | ["metadata"]["name"] | view2nd |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
    Then the output should contain:
      | view2nd |
    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | star                |
      | role         | view                |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | star                |
      | role         | view2nd             |
    Then the step should fail
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | bob                 |
      | role         | view                |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
    Then the output should contain:
      | bob |
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | bob                 |
      | role         | view                |
      | save_changes | false               |
    Then the step should succeed
    When I perform the :check_error_message_on_membership web console action with:
      | name | bob  |
      | role | view |
    Then the step should succeed
    And I run the :get client command with:
      | resource | rolebinding |
    Then the output should not contain 2 times:
      | bob |


  # @author hasha@redhat.com
  # @case_id OCP-11380
  Scenario: Check warning modal in some membership edit situations
    #have no related rules for v3.4&v3.5
    Given the master version >= "3.4"
    Given I have a project
    When I perform the :click_to_goto_membership_tab web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
    Then the step should succeed
    When I run the :edit_membership web console action
    Then the step should succeed
    When I perform the :click_on_delete_role_on_membership web console action with:
      | name         | deployer                      |
      | role         | system:deployer               |
      | danger_alert | may cause unexpected behavior |
    Then the step should succeed
    When I perform the :click_to_goto_membership_tab web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
    Then the step should succeed
    When I run the :edit_membership web console action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-11992
  Scenario: Manage project membership with project-local role
    Given I log the message> scenario not supported on version < 3.6
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/rbac/OCP-12989/role.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource | rolebinding |
    Then the step should succeed
    Then the output should not contain:
      | <%= project.name %>/deleteservices |
      | bob                                |
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | bob                 |
      | role         | deleteservices      |
      | save_changes | true                |
    Then the step should succeed
    When I run the :get client command with:
      | resource | rolebinding |
    Then the step should succeed
    Then the output should contain:
      | <%= project.name %>/deleteservices |
      | bob                                |
