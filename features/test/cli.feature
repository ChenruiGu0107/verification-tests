Feature: Testing CLI Scenarios
  Scenario: simple create project
    When I run the :new_project client command with:
      | project_name | demo |
      | display name | OpenShift 3 Demo |
      | description  | This is the first demo project with OpenShift v3 |
    Then the step should succeed
    And 3 seconds have passed
    When I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should contain:
      | OpenShift 3 Demo |
      | Active |
    When I switch to the second user
    And I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should not contain:
      | demo |
    When I switch to the first user
    And I run the :delete client command with:
      | object_type | project |
      | object_name_or_id | demo |
    Then the step should succeed

  # actually, because of user clean-up relying on cli, we never run REST
  #   requests before we run cli requests
  Scenario: rest request before cli
    Given I perform the :delete_project rest request with:
      | project name | demo |
    # looks like time needs to pass for the project to be really gone
    And 5 seconds have passed
    And I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should not contain:
      | demo |
