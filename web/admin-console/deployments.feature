Feature: deployment/dc related features via web

  # @author hasha@redhat.com
  # @case_id OCP-19558
  Scenario: Check deployment page
    Given the master version >= "3.11"
    Given I have a project
    Given I obtain test data file "storage/nfs/claim-rwo-ui.json"
    When I run the :create client command with:
      | f | claim-rwo-ui.json |
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
    When I perform the :click_pod_selector_on_resource_detail web action with:
      | value | app=hello-openshift |
    Then the step should succeed
    Given the expression should be true> browser.url.include? "/search/ns/<%= project.name %>?kind=Pod"
    When I perform the :goto_one_deployment_page web action with:
      | project_name | <%= project.name %>  |
      | deploy_name  | example              |
    Then the step should succeed
    When I run the :edit_pod_count_action web action
    Then the step should succeed
    When I perform the :update_resource_count web action with:
      | resource_count | 2 |
    Then the step should succeed
    Given I wait until number of replicas match "2" for deployment "example"
    When I run the :edit_update_strategy_action web action
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
    When I run the :delete_deployment_action web action
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
    Given I obtain test data file "deployment/simpledc.json"
    When I run the :create client command with:
      | f | simpledc.json |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I get project deploymentconfigs
    Then the output should contain "hooks"
    """
    And I open admin console in a browser
    When I perform the :goto_one_dc_page web action with:
      | project_name | <%= project.name %>  |
      | dc_name      | hooks                |
    Then the step should succeed
    When I run the :pause_rollouts_action web action
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I perform the :check_page_match web action with:
      | content | Resume Rollouts |
    Then the step should succeed
    """
    When I run the :start_rollout_action web action
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | deployment config "hooks" is paused |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | OK |
    Then the step should succeed

    When I run the :resume_rollouts_action web action
    Then the step should succeed

    When I run the :start_rollout_action web action
    Then the step should succeed
    When I perform the :check_page_not_match web action with:
      | content | deployment config "hooks" is paused |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-24423
  Scenario: Cancel support for Deployment Config
    Given the master version >= "4.2"
    Given I have a project
    And I open admin console in a browser
    Given I obtain test data file "deployment/deployment1.json"
    When I run the :create client command with:
      | f | deployment1.json  |
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
    When I run the :cancel_rollout_action web action
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :failed
    When I perform the :check_resource_details web action with:
      | phase | Failed |
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
    # for disconnect env, better to workaround by digest image marked as below:
    # quay.io/openshifttest/hello-openshift@sha256:aaea76ff622d2f8bcb32e538e7b3cd0ef6d291953f3e7c9f556c1ba5baf47e2e
    # Digest image blocked by bug for https://bugzilla.redhat.com/show_bug.cgi?id=1823616
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
    Given I obtain test data file "deployment/simpledc.json"
    When I run the :create client command with:
      | f | simpledc.json |
    Then the step should succeed
    Given a pod is present with labels:
      | deployment=hooks-1 |
    When I perform the :goto_one_dc_page web action with:
      | project_name | <%= project.name %>  |
      | dc_name      | hooks                |
    Then the step should succeed
    When I run the :click_replication_controllers_tab web action
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | hooks-1                          |
      | link_url | replicationcontrollers/hooks-1   |
    Then the step should succeed

    Given the first user is cluster-admin
    When I perform the :goto_one_deployment_page web action with:
      | project_name | openshift-console |
      | deploy_name  | console           |
    Then the step should succeed
    When I run the :click_replica_sets_tab web action
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
    Given I obtain test data file "deployment/simpledc.json"
    When I run the :create client command with:
      | f | simpledc.json |
    Then the step should succeed
    Given a pod is present with labels:
      | deployment=hooks-1 |
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
      | rc_name      | hooks-1              |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | created_at | |
      | owner      | hooks |
    Then the step should succeed
    Given I obtain test data file "deployment/ocp25793/k8s-deployment.yaml"
    When I run the :create client command with:
      | f | k8s-deployment.yaml |
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

  # @author hasha@redhat.com
  # @case_id OCP-25777
  Scenario: Check pod status when container is still running or state is Error
    Given the master version >= "4.2"
    Given I have a project
    And I open admin console in a browser
    Given I obtain test data file "pods/two_container_sleep.yaml"
    When I run the :create client command with:
      | f | two_container_sleep.yaml |
    Then the step should succeed
    Given the pod named "sleeppod" status becomes :running
    When I perform the :goto_project_pods_list_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_pod_status web action with:
      | pod_name   | sleeppod |
      | pod_status | Running  |
    Then the step should succeed
    Given the pod named "sleeppod" status becomes :succeeded
    When I perform the :goto_project_pods_list_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_pod_completed_status web action with:
      | pod_name | sleeppod |
    Then the step should succeed

    Given I obtain test data file "pods/two_container_sleep.yaml"
    When I run oc create with "two_container_sleep.yaml" replacing paths:
      | ["metadata"]["name"]               | podtest               |
      | ["spec"]["containers"][0]["image"] | quay.io/openshifttest/busybox_non |
    Then the step should succeed
    Given the pod named "podtest" status becomes :pending
    Given I wait up to 120 seconds for the steps to pass:
    """
    When I get project pods
    Then the output should contain:
      | ImagePullBackOff |
    """
    When I perform the :goto_project_pods_list_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_pod_status web action with:
      | pod_name   | podtest          |
      | pod_status | ImagePullBackOff |
    Then the step should succeed

