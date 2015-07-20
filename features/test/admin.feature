Feature: Testing Admin Scenarios
  Scenario: simple create project admin scenario
    When I run the :new_project admin command with:
      | project_name | demo                                             |
      | display name | OpenShift 3 Demo                                 |
      | description  | This is the first demo project with OpenShift v3 |
      | admin        | <%= user.name %>                                 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should contain:
      | OpenShift 3 Demo |
      | Active |
