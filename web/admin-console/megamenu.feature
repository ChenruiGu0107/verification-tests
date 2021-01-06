Feature: mega menu on console

  # @author yanpzhan@redhat.com
  # @case_id OCP-24512
  @admin
  Scenario: Check mega menu on console
    Given the master version >= "4.2"
    And I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :navigate_to_dev_console web action
    Then the step should succeed
    And the expression should be true> browser.url.include? "/topology/"
    When I run the :goto_projects_list_page web action
    Then the step should succeed
    When I run the :check_mega_menu web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-25761
  @admin
  Scenario: Allow users to Report Bug and Open Support Case from console
    # we don't cover 'Open Support Case' button, this is for the test before release.
    Given the master version >= "4.3"
    And I store master major version in the clipboard
    And evaluation of `cluster_version('version').version` is stored in the :cf_environment_version clipboard
    And evaluation of `cluster_version('version').cluster_id` is stored in the :cluster_id clipboard

    Given the first user is cluster-admin
    And I open admin console in a browser
    When I run the :click_report_bug_link_in_helpmenu web action
    Then the step should succeed
    When I wait up to 60 seconds for the steps to pass:
    """
    When I perform the :check_page_contains web action in ":url=>bugzilla" window with:
      | content | Red Hat Bugzilla |
    Then the step should succeed
    """
    Then the expression should be true> @result[:url].include? "bugzilla.redhat.com/enter_bug"
    And the expression should be true> @result[:url].include? "product=OpenShift%20Container%20Platform"
    And the expression should be true> @result[:url].include? "version=<%= cb.master_version %>"
    And the expression should be true> @result[:url].include? "cf_environment=Version%3A%20<%= cb.cf_environment_version %>"
    And the expression should be true> @result[:url].include? "Cluster%20ID%3A%20<%= cb.cluster_id %>"

  # @author yapei@redhat.com
  # @case_id OCP-25803
  @admin
  @destructive
  Scenario: Pipelines resources are added into Admin perspective
    Given the master version >= "4.3"
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators:latest"
    Given I switch to the first user
    Given the first user is cluster-admin
    And I open admin console in a browser
    Given admin ensures "openshift-pipelines-operator-rh" subscription is deleted from the "openshift-operators" project after scenario
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | openshift-pipelines-operator-rh  |
      | catalog_name     | ui-auto-operators                |
      | target_namespace | openshift-operators              |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed

    # first subscription will be created
    Given admin waits for the "openshift-pipelines-operator-rh" subscriptions to become ready in the "openshift-operators" project up to 360 seconds
    # get exact CSV name
    And evaluation of `subscription("openshift-pipelines-operator-rh").current_csv` is stored in the :current_csv clipboard

    # make sure CSV is removed
    Given admin ensures "<%= cb.current_csv %>" clusterserviceversions is deleted from the "openshift-operators" project after scenario

    # wait until operator is installed successfully, that is CSV.status.phase == Succeeded
    Given admin wait for the "<%= cb.current_csv %>" clusterserviceversions to become ready in the "openshift-operators" project up to 240 seconds

    # wait until CRD is ready then creation will succeed
    Given admin wait for the "tasks.tekton.dev" customresourcedefinitions to become ready up to 120 seconds
    Given admin wait for the "taskruns.tekton.dev" customresourcedefinitions to become ready up to 120 seconds
    Given admin wait for the "pipelineresources.tekton.dev" customresourcedefinitions to become ready up to 120 seconds
    Given admin wait for the "pipelines.tekton.dev" customresourcedefinitions to become ready up to 120 seconds
    Given admin wait for the "pipelineruns.tekton.dev" customresourcedefinitions to become ready up to 120 seconds

    # create test project and pipeline related resources after operator is successfully installed
    Given admin ensures "autotest-pipeline-tutorial" project is deleted after scenario
    When I run the :new_project client command with:
      | project_name | autotest-pipeline-tutorial |
    Then the step should succeed
    Given I obtain test data file "pipeline/apply_manifest_task.yaml"
    Given I obtain test data file "pipeline/update_deployment_task.yaml"
    Given I obtain test data file "pipeline/pipeline_resource.yaml"
    Given I obtain test data file "pipeline/pipeline.yaml"
    When I run the :create client command with:
      | f | apply_manifest_task.yaml    |
      | f | update_deployment_task.yaml |
      | f | pipeline_resource.yaml      |
      | f | pipeline.yaml               |
      | n | autotest-pipeline-tutorial                                                           |
    Then the step should succeed

    When I run the :goto_projects_list_page web action
    Then the step should succeed
    When I run the :check_pipeline_related_menus web action
    Then the step should succeed

    When I perform the :goto_pipelines_list_page web action with:
      | project_name | autotest-pipeline-tutorial |
    Then the step should succeed
    When I perform the :check_pipeline_resource_item web action with:
      | pipeline_name | build-and-deploy           |
      | project_name  | autotest-pipeline-tutorial |
    Then the step should succeed

    When I perform the :goto_pipeline_resources_list_page web action with:
      | project_name | autotest-pipeline-tutorial |
    Then the step should succeed
    When I perform the :check_pipeline_resources_resource_item web action with:
      | pipelineresource_name | api-image                  |
      | project_name          | autotest-pipeline-tutorial |
    Then the step should succeed
    When I perform the :check_pipeline_resources_resource_item web action with:
      | pipelineresource_name | api-repo                   |
      | project_name          | autotest-pipeline-tutorial |
    Then the step should succeed
    When I perform the :check_pipeline_resources_resource_item web action with:
      | pipelineresource_name | ui-image                   |
      | project_name          | autotest-pipeline-tutorial |
    Then the step should succeed
    When I perform the :check_pipeline_resources_resource_item web action with:
      | pipelineresource_name | ui-repo                    |
      | project_name          | autotest-pipeline-tutorial |
    Then the step should succeed

    When I perform the :goto_tasks_list_page web action with:
      | project_name | autotest-pipeline-tutorial |
    Then the step should succeed
    When I perform the :check_task_resource_item web action with:
      | task_name    | apply-manifests            |
      | project_name | autotest-pipeline-tutorial |
    Then the step should succeed
    When I perform the :check_task_resource_item web action with:
      | task_name    | update-deployment          |
      | project_name | autotest-pipeline-tutorial |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-24270
  @admin
  @destructive
  Scenario: Check Chargeback Reports
    Given the master version >= "4.3"
    Given metering service has been installed successfully
    Given I switch to the first user
    And the first user is cluster-admin
    And I open admin console in a browser
    When I perform the :goto_chargeback_reports_page web action with:
      | namespace | <%= cb.metering_namespace.name %> |
    Then the step should succeed
    Given admin ensures "namespace-memory-request" report is deleted from the "<%= cb.metering_namespace.name %>" project after scenario
    When I run the :create_resource_by_default_yaml web action
    Then the step should succeed
    Given admin wait for the "namespace-memory-request" report to appear in the "<%= cb.metering_namespace.name %>" project up to 10 seconds
    When I perform the :check_reports_table web action with:
      | namespace         | <%= cb.metering_namespace.name %>  |
      | report_name       | namespace-memory-request           |
      | reportquery_name  | namespace-memory-request           |
    Then the step should succeed
    When I perform the :check_reportquery_details web action with:
      | namespace           | <%= cb.metering_namespace.name %> |
      | reportquery_name    | namespace-memory-request          |
      | meteringconfig_name | <%= cb.meteringconfig_name %>     |
    Then the step should succeed
    When I perform the :check_owner_reference web action with:
      | owner_resource_namespace | <%= cb.metering_namespace.name %> |
      | owner_resource_group     | metering.openshift.io             |
      | owner_resource_version   | v1                                |
      | owner_resource_kind      | MeteringConfig                    |
      | owner_resource_name      | <%= cb.meteringconfig_name %>     |
    Then the step should succeed
    When I perform the :check_usage_report_table web action with:
      | namespace   | <%= cb.metering_namespace.name %> |
      | report_name | namespace-memory-request          |
    Then the step should succeed
    Given admin ensures "node-cpu-capacity-invalid" report is deleted from the "<%= cb.metering_namespace.name %>" project after scenario
    Given admin ensures "namespace-memory-request-invalid" report is deleted from the "<%= cb.metering_namespace.name %>" project after scenario
    Given I obtain test data file "metering/reports/invalid-date.yaml"
    Given I obtain test data file "metering/reports/non-exist-reportquery.yaml"
    When I run the :create admin command with:
      | f | invalid-date.yaml                 |
      | f | non-exist-reportquery.yaml        |
      | n | <%= cb.metering_namespace.name %> |
    Then the step should succeed
    When I perform the :goto_one_report_page web action with:
      | namespace   | <%= cb.metering_namespace.name %> |
      | report_name | node-cpu-capacity-invalid         |
    Then the step should succeed
    When I run the :check_invalid_start_end_date_conditions_table web action
    Then the step should succeed
    When I perform the :goto_one_report_page web action with:
      | namespace   | <%= cb.metering_namespace.name %> |
      | report_name | namespace-memory-request-invalid  |
    Then the step should succeed
    When I run the :check_non_exist_reportquery_conditions_table web action
    Then the step should succeed