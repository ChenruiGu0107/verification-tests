Feature: projects related features via web

  # @author hasha@redhat.com
  # @case_id OCP-19577
  Scenario: Check project page
    #Now we have to check project page from v4.1 since it has big changes about project overview page compared with v3.11.
    Given the master version >= "4.0"
    Given I open admin console in a browser
    Given an 8 character random string of type :dns is stored into the :pro_name clipboard
    When I perform the :create_project web action with:
      | project_name    | <%= cb.pro_name %> |
      | display_name    | pro_display        |
      | description     | description        |
    Then the step should succeed
    When I perform the :goto_project_details_page web action with:
      | project_name    | <%= cb.pro_name %> |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name         | <%= cb.pro_name %> |
      | display_name | pro_display        |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item   | Delete Project |
    Then the step should succeed
    When I perform the :send_delete_string web action with:
      | resource_name | <%= cb.pro_name %>  |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed
    Given I wait for the resource "project" named "<%= cb.pro_name %> " to disappear
    When I perform the :create_project web action with:
      | project_name   | W          |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Error |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-19725
  Scenario: Check Service account page under project scope
    Given the master version >= "4.1"
    Given I have a project
    Given I open admin console in a browser
    When I perform the :goto_serviceaccounts_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text | builder |
      | link_url | <%= project.name %>/serviceaccounts/builder |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text | default |
      | link_url | <%= project.name %>/serviceaccounts/default |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text | deployer |
      | link_url | <%= project.name %>/serviceaccounts/deployer |
    Then the step should succeed

    When I run the :create_resource_by_default_yaml web action
    Then the step should succeed

    When I perform the :click_one_dropdown_action web action with:
      | item | Delete Service Account |
    Then the step should succeed
    When I run the :delete_resource_panel web action
    Then the step should succeed
    When I run the :get client command with:
      | resource | serviceaccount |
    Then the step should succeed
    And the output should not contain "example"
