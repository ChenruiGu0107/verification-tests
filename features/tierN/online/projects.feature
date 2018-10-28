Feature: ONLY ONLINE Projects related feature's scripts in this file

  # @author etrott@redhat.com
  # @case_id OCP-12550
  Scenario: User should be able to switch projects via CLI
    Given I create a new project
    Then I switch to the second user
    Given I create a new project
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                              |
      | user_name | <%= user(0, switch: false).name %> |
      | n         | <%= project.name %>                |
    Then the step should succeed
    Given I switch to the first user
    When I run the :project client command with:
    | project_name | <%= project(0, switch: false).name %> |
    Then the output should contain:
    | project "<%= project(0, switch: false).name %>" on server |
    When I run the :project client command with:
      | project_name | <%= project.name %> |
    Then the output should contain:
      | project "<%= project.name %>" on server |
    And I run the :project client command with:
      | project_name | notaccessible |
    Then the output should contain:
      | error: You are not a member of project "notaccessible". |
      | Your projects are:                                      |
      | * <%= project.name %>                                   |
      | * <%= project(1).name %>                                |

