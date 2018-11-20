Feature: projects related features via web

  # @author hasha@redhat.com
  # @case_id OCP-19577
  Scenario: Check project page
    Given I open admin console in a browser
    When I perform the :create_project web action with:
      | project_name   | W          |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Error |
    Then the step should succeed
    When I perform the :clear_input_value web action with:
      | clear_field_id | input-name |
    Then the step should succeed
    When I perform the :create_project web action with:
      | project_name    | test             |
      | display_name    | test_display     |
      | description     | test_description |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name         | test         |
      | display_name | test_display |
    Then the step should succeed
    When I perform the :click_tab web action with:
      | tab_name | Role Bindings |
    Then the step should succeed
    When I perform the :check_row_filter_on_page web action with:
      | filter | Namespace Role Bindings |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item   | Delete Project |
    Then the step should succeed
    When I perform the :send_delete_string web action with:
      | resource_name | test |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed
    Given I wait for the resource "project" named "test" to disappear
    When I run the :get client command with:
      | resource | project |
    Then the step should succeed
    And the output should contain:
      | No resources found |


  # @author xiaocwan@redhat.com
  # @case_id OCP-19669
  Scenario: Console works for empty project
    Given I open admin console in a browser
    When I perform the :goto_project_status web action with:
      | project   | default |
    Then the step should succeed
    When I run the :check_getting_started web action
    Then the step should succeed
    When I perform the :check_doc_get_started_with_cli web action with:
      | documentationbaseurl | docs.openshift.com/container-platform |
    Then the step should succeed
    When I run the :check_additional_support web action
    Then the step should succeed

    Given I saved following keys to list in :resources clipboard:
      | Deployment Config         | |
      | Pod                       | |
      | Deployment                | |
      | Stateful Set              | |
      | Config Map                | |
      | Cron Job                  | |
      | Job                       | |
      | Daemon Set                | |
      | Replication Controller    | |
      | Horizontal Pod Autoscaler | |
      | Service                   | |
      | Route                     | |
      | Persistent Volume Claim   | |
      | Build Config              | |
      | Image Stream              | |
      | Service Account           | |
      | Resource Quota            | |
    When I repeat the following steps for each :resource in cb.resources:
    """
    Given evaluation of `cb.resource.downcase` is stored in the :resource_url clipboard
    When I perform the :goto_resource_page_under_default_project web action with:
      | resource_url_name   | <%= cb.resource_url.id2name.delete(" ")+"s" %> |
    Then the step should succeed

    When I run the :check_getting_started web action
    Then the step should succeed
    When I perform the :check_dim_resource_list web action with:
      | resource_url_name | <%= cb.resource_url.id2name.delete(" ")+"s" %>  |
      | resource_singular | <%= cb.resource %>  |
    Then the step should succeed
    """

