Feature: projects related features via web

  # @author hasha@redhat.com
  # @case_id OCP-19577
  Scenario: list/create/delete projects
    Given I open admin console in a browser
    When I perform the :create_project web action with:
      | project_name   | W          |
    Then the step should succeed
    When I run the :check_invalid_message web action
    Then the step should succeed
    When I perform the :clear_input_value web action with:
      | clear_field_id | input-name |
    Then the step should succeed
    When I perform the :create_project web action with:
      | project_name    | test             |
      | display_name    | test_display     |
      | description     | test_description |
    Then the step should succeed
    When I perform the :check_project_on_overview_page web action with:
      | project_name    | test         |
      | display_name    | test_display |
    Then the step should succeed
    When I perform the :click_tab_on_overview_page web action with:
      | tab_name | Role Bindings |
    Then the step should succeed
    When I perform the :check_row_filter_on_page web action with:
      | filter | Namespace Role Bindings |
    Then the step should succeed
    When I run the :goto_projects_list_page web action
    Then the step should succeed
    When I perform the :delete_project_on_list_page web action with:
      | resource_name | test           |
      | action_item   | Delete Project |
    Then the step should succeed
