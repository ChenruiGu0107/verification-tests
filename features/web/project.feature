Feature: projects related features via web

  # @author xxing@redhat.com
  # @case_id 479613
  Scenario: Create a project with a valid project name on web console
    When I perform the :new_project web action with:
      | project_name | <%= rand_str(5, :dns) %> |
      | display_name | test                     |
      | description  | test                     |
    Then the step should succeed
    When I perform the :new_project web action with:
      | project_name | <%= rand_str(63, :dns) %> |
      | display_name | test                      |
      | description  | test                      |
    Then the step should succeed
    When I perform the :new_project web action with:
      | project_name | <%= rand_str(2, :dns) %> |
      | display_name | :null                    |
      | description  ||
    Then the step should succeed

