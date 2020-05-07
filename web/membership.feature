Feature: memberships related features via web
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
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | view        |
      | o             | yaml        |
    Then the step should succeed
    And I save the output to file> rolebinding_view.yaml
    When I run oc create over "rolebinding_view.yaml" replacing paths:
      | ["metadata"]["name"]              | view2nd |
      | ["metadata"]["creationTimestamp"] | null    |
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
