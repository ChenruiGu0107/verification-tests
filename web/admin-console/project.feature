Feature: projects related features via web

  # @author hasha@redhat.com
  # @case_id OCP-26910
  Scenario: Check project page
    #Now we have to check project page from v4.1 since it has big changes about project overview page compared with v3.11.
    Given the master version >= "4.1"
    Given I open admin console in a browser
    When I run the :navigate_to_admin_console web action
    Then the step should succeed
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
    When I run the :delete_project_action web action
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

    When I perform the :delete_serviceaccount_action web action
    Then the step should succeed
    When I run the :delete_resource_panel web action
    Then the step should succeed
    When I run the :get client command with:
      | resource | serviceaccount |
    Then the step should succeed
    And the output should not contain "example"

  # @author yapei@redhat.com
  # @case_id OCP-26984
  @admin
  Scenario: Add metrics to project list page
    Given the master version >= "4.4"
    Given the first user is cluster-admin

    # check CPU and Memory column shown
    Given I open admin console in a browser
    When I run the :goto_projects_list_page web action
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | CPU |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Memory |
    Then the step should succeed

    # check data is correctly shown for one project
    When I perform the :check_memory_data_for_one_project_in_table web action with:
      | project_name | openshift-apiserver |
    Then the step should succeed
    When I perform the :check_cpu_data_for_one_project_in_table web action with:
      | project_name | openshift-apiserver |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-26841
  Scenario: Check project list for display name and creation date
    Given the master version >= "4.3"
    Given an 8 character random string of type :dns is stored into the :pro_name clipboard
    When I run the :new_project client command with:
      | project_name | project-<%= cb.pro_name %> |
      | display_name | display-<%= cb.pro_name %> |
    Then the step should succeed
    Then I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | project |
    Then the step should succeed
    And the output should contain:
      | project-<%= cb.pro_name %> |
      | display-<%= cb.pro_name %> |
    """
    Given I open admin console in a browser
    When I run the :goto_projects_list_page web action

    # check columns: display name and creation date
    When I perform the :check_column_in_table web action with:
      | field | Display Name |
    And I perform the :check_column_in_table web action with:
      | field | Created |
    Then the step should succeed

    # check same row: project name,  display name and creation time
    When I perform the :check_resource_data_in_table web action with:
      | resource_name | project-<%= cb.pro_name %> |
      | data          | display-<%= cb.pro_name %> |
    Then the step should succeed
    When I perform the :check_resource_data_in_table web action with:
      | resource_name | project-<%= cb.pro_name %> |
      | data          | ago                        |
    Then the step should succeed

