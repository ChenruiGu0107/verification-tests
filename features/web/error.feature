Feature: error page on web console
  # @author yapei@redhat.com
  # @case_id OCP-11446
  Scenario: Redirect to error page when got 403 error
    Given I have a project
    When I perform the :delete_project web console action with:
      | project_name | <%= project.name %> |
      | input_str    | <%= project.name %> |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_error_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    # switch to second user,create new project
    Given I switch to the second user
    Given an 8 characters random string of type :dns is stored into the :project2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    Given I switch to the first user
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    When I perform the :check_error_page web console action with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
