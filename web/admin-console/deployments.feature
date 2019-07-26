Feature: deployment/dc related features via web

  # @author hasha@redhat.com
  # @case_id OCP-19558
  Scenario: Check deployment page
    Given the master version >= "3.11"		
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/claim-rwo-ui.json |
    Then the step should succeed
    And I open admin console in a browser
    When I perform the :goto_deployment_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :create_resource_by_default_yaml web action
    Then the step should succeed
    When I perform the :goto_one_deployment_page web action with:
      | project_name | <%= project.name %>  |
      | deploy_name  | example              |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name            | example             |
      | pod_selector    | app=hello-openshift |
      | update_strategy | RollingUpdate       |
      | max_unavailable | 25%                 |
      | max_surge       | 25%                 |
    Then the step should succeed
    When I perform the :click_value_on_resource_detail web action with:
      | key   | Pod Selector        |
      | value | app=hello-openshift |
    Then the step should succeed
    Given the expression should be true> browser.url.include? "/search/ns/<%= project.name %>?kind=Pod"
    When I perform the :goto_one_deployment_page web action with:
      | project_name | <%= project.name %>  |
      | deploy_name  | example              |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item   | Edit Count |
    Then the step should succeed
    When I perform the :update_resource_count web action with:
      | resource_count | 2 |
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Desired Count |
      | value | 2 pod         |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item   | Edit Update Strategy |
    Then the step should succeed
    When I perform the :update_rollout_strategy web action with:
      | update_strategy | Recreate |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name            | example  |
      | update_strategy | Recreate |
    Then the step should succeed
    When I perform the :click_tab web action with:
      | tab_name| Environment |
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name    | test_key         |
      | env_var_value   | test_value       |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | deploy/example |
      | list     | true           |
    And the step should succeed
    And the output should contain:
      | test_key=test_value |
    When I perform the :click_tab web action with:
      | tab_name | Overview |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item   | Delete Deployment |
    Then the step should succeed
    When I perform the :delete_resource_panel web action with:
      | cascade       | true              |
    Then the step should succeed
    Given I wait up to 70 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | deployment |
    Then the step should succeed
    And the output should contain:
     | No resources found |
    """

  # @author yanpzhan@redhat.com
  # @case_id OCP-19653
  Scenario: Pause and resume Deployment support
    Given I have a project
    When I run the :run client command with:
      | name         | mydc                  |
      | image        | aosqe/hello-openshift |
      | limits       | memory=256Mi          |
    Then the step should succeed
    And I open admin console in a browser
    When I perform the :goto_one_dc_page web action with:
      | project_name | <%= project.name %> |
      | dc_name      | mydc                |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item  | Pause Rollouts |
    Then the step should succeed

    When I perform the :check_page_match web action with:
      | content | Resume Rollouts |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item  | Start Rollout |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | deployment config "mydc" is paused |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | OK |
    Then the step should succeed

    When I perform the :click_one_dropdown_action web action with:
      | item  | Resume Rollouts |
    Then the step should succeed

    When I perform the :click_one_dropdown_action web action with:
      | item  | Start Rollout |
    Then the step should succeed
    When I perform the :check_page_not_match web action with:
      | content | deployment config "mydc" is paused |
    Then the step should succeed
