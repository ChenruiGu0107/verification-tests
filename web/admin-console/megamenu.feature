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
  Scenario: Pipelines resources are added into Admin perspective
    Given the master version >= "4.3"
    Given the first user is cluster-admin
    And I open admin console in a browser
    Given admin ensures "openshift-pipelines-operator-rh" subscription is deleted from the "openshift-operators" project after scenario
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | openshift-pipelines-operator-rh  |
      | catalog_name     | redhat-operators                 |
      | target_namespace | openshift-operators              |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed

    # first subscription will be created
    Given admin waits for the "openshift-pipelines-operator-rh" subscription to appear in the "openshift-operators" project up to 120 seconds

    # make clusterserviceversion is created before runnning subscription('x').csv
    Given I use the "openshift-operators" project
    Given I wait up to 120 seconds for the steps to pass:
    """
    When I get project clusterserviceversions
    Then the output should contain "openshift-pipelines-operator.v"
    """

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
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pipeline/apply_manifest_task.yaml    |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pipeline/update_deployment_task.yaml |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pipeline/pipeline_resource.yaml      |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pipeline/pipeline.yaml               |
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
