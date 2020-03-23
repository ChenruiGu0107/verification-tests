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
    Given I wait until number of replicas match "2" for deployment "example"
    When I perform the :click_one_dropdown_action web action with:
      | item   | Edit Update Strategy |
    Then the step should succeed
    When I perform the :update_rollout_strategy web action with:
      | update_strategy | Recreate |
    Then the step should succeed

    # after changes we first check using CLI
    And I wait up to 10 seconds for the steps to pass:
    """
    Then the expression should be true>  deployment("example").strategy(cached: false)["type"] == "Recreate"
    """

    # reload page to reflect changes
    When I perform the :goto_one_deployment_page web action with:
      | project_name | <%= project.name %>  |
      | deploy_name  | example              |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name            | example  |
      | update_strategy | Recreate |
    Then the step should succeed
    When I run the :click_environment_tab web action
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
    When I run the :click_overview_tab web action
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item   | Delete Deployment |
    Then the step should succeed
    When I perform the :delete_resource_panel web action with:
      | cascade       | true |
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
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I perform the :check_page_match web action with:
      | content | Resume Rollouts |
    Then the step should succeed
    """
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

  # @author yapei@redhat.com
  # @case_id OCP-24423
  Scenario: Cancel support for Deployment Config
    Given the master version >= "4.2"
    Given I have a project
    And I open admin console in a browser
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json  |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | hooks            |
      | replicas | 3                |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | deployment=hooks-1 |
    When I run the :rollout_latest client command with:
      | resource | hooks |
    Then the step should succeed
    When I perform the :goto_one_rc_page web action with:
      | project_name | <%= project.name %> |
      | rc_name      | hooks-2             |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item | Cancel Rollout |
    Then the step should succeed
    When I run the :confirm_cancel_rollout web action
    Then the step should succeed
    Given I wait until the status of replication controller "hooks-2" becomes :failed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Phase  |
      | value | Failed |
    Then the step should succeed
    When I perform the :goto_one_dc_page web action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | RolloutCancelled |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-20849
  Scenario: Check basic process of create/delete DC from image
    Given the master version >= "4.1"
    Given I have a project
    Given I open admin console in a browser
    When I perform the :goto_deploy_image_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    # Check non-existed image error message
    When I run the :search_nonexisted_image_and_check_message web action
    Then the step should succeed  
    # Check existed image creating page
    When I perform the :goto_deploy_image_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :search_and_deploy_image web action with:
      | search_content | aosqe/hello-openshift |
    Then the step should succeed 
    # Check created resources
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | all                 |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should match:
      | deploymentconfig.*hello-openshift       |
      | replicationcontroller/hello-openshift-1 |
      | pod/hello-openshift-1                   |
      | service/hello-openshift                 |
      | imagestream.*hello-openshift            |
    """
    # Delete dc and check dependent objects
    When I perform the :goto_one_dc_page web action with:
      | project_name | <%= project.name %> |
      | dc_name      | hello-openshift     |
    Then the step should succeed
    When I run the :delete_dc_with_dependency_objects web action
    Then the step should succeed
    Given I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | all                 |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should not match:
      | deploymentconfig.*python       |
      | replicationcontroller/python-1 |
      | pod/python-1"                  |
    """
    
  # @author xiaocwan@redhat.com
  # @case_id OCP-25773
  @admin
  Scenario: Add rs/rc tab under deployment/dc page
    Given the master version >= "4.3"
    Given I open admin console in a browser
    Given I have a project
    When I perform the :goto_dc_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :run client command with:
       | name    | example                 |
       | image   | busybox                 |
    Then the step should succeed
    When I perform the :goto_one_dc_page web action with:
      | project_name | <%= project.name %>  |
      | dc_name      | example              |
    Then the step should succeed
    When I perform the :click_tab web action with:
      | tab_name | Replication Controllers |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | example-1                        |
      | link_url | replicationcontrollers/example-1 |
    Then the step should succeed

    Given the first user is cluster-admin
    When I perform the :goto_one_deployment_page web action with:
      | project_name | openshift-console |
      | deploy_name  | console           |
    Then the step should succeed
    When I perform the :click_tab web action with:
      | tab_name | Replica Sets |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | console-             |
      | link_url | replicasets/console- |
    Then the step should succeed


  # @author hasha@redhat.com
  # @case_id OCP-25793
  Scenario: Workload list views have created and owner
    Given the master version >= "4.3"
    Given I open admin console in a browser
    Given I have a project
    When I run the :run client command with:
      | name  | exampletest           |
      | image | aosqe/hello-openshift |
    Then the step should succeed
    When I perform the :goto_rc_list_page web action with:
      | project_name | <%= project.name %>  |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Created |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Owner |
    Then the step should succeed
    When I perform the :goto_one_rc_page web action with:
      | project_name | <%= project.name %>  |
      | rc_name      | exampletest-1        |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | created_at | |
      | owner      | exampletest |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc536590/k8s-deployment.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | rs   |
      | o        | json |
    Then the step succeeded
    Given evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :rs_name clipboard
    And a pod is present with labels:
      | app=hello-openshift |
    And evaluation of `pod.name` is stored in the :pod_name clipboard
    When I perform the :goto_replica_sets_page web action with:
      | project_name | <%= project.name %>  |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Created |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Owner |
    Then the step should succeed
    When I perform the :goto_one_rs_page web action with:
      | project_name | <%= project.name %>  |
      | rs_name      | <%= cb.rs_name %>    |
    Then the step should succeed
    When I run the :wait_until_no_loading web action
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | created_at | |
      | owner      | hello-openshift |
    Then the step should succeed
    When I perform the :goto_one_pod_page web action with:
      | project_name  | <%= project.name %>  |
      | resource_name | <%= cb.pod_name %>   |
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | <%= cb.rs_name %> |
      | link_url | /k8s/ns/<%= project.name %>/replicasets/<%= cb.rs_name %> |
    Then the step should succeed
