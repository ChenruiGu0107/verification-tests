Feature: Testing REST Scenarios
  Scenario: simple rest scenario
    # this step will go into clean-up phase in the future
    Given I perform the :delete_project rest request with:
      | project name | demo |
    # looks like time needs to pass for the project to be really gone
    And 5 seconds have passed
    When I run the :new_project admin command with:
      | new_project_name | demo |
      | display name | OpenShift 3 Demo |
      | description | This is the first demo project with OpenShift v3 |
      | admin | <%= user.name %> |
    Then the step should succeed
    When I perform the :list_projects rest request
    Then the step should succeed
    And the output should contain:
      | OpenShift 3 Demo |
      | Active |
    When I switch to the second user
    And I perform the :list_projects rest request
    Then the step should succeed
    And the output should not contain:
      | demo |
    When I switch to the first user
    And I perform the :delete_project rest request with:
      | project name | demo |
    Then the step should succeed

  Scenario: cli command before rest
    Given I run the :delete client command with:
      | object_type | project |
      | object_name_or_id | demo |
    # looks like time needs to pass for the project to be really gone
    And 5 seconds have passed
    And I perform the :list_projects rest request
    Then the step should succeed
    And the output should not contain:
      | demo |
