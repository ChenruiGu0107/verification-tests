Feature: Features about k8s deployments
  # @author yapei@redhat.com
  # @case_id OCP-12273
  Scenario: Attach storage for k8s deployment
    Given the master version >= "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/tc536590/k8s-deployment.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/claim-rwo-ui.json |
    Then the step should succeed
    When I perform the :click_to_goto_one_deployment_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_deployments_name | hello-openshift     |
    Then the step should succeed
    When I perform the :add_storage_to_k8s_deployments web console action with:
      | mount_path  |  /hello-openshift-data |
      | volume_name | hello-openshift-volume |
    Then the step should succeed
    When I perform the :check_mount_info_configuration web console action with:
      | mount_path  |  /hello-openshift-data |
      | volume_name | hello-openshift-volume |
    Then the step should succeed
    When I perform the :click_pvc_link_on_dc_page web console action with:
      | pvc_name | nfsc |
    Then the step should succeed
    And the expression should be true> browser.url.include? "browse/persistentvolumeclaims"
    When I run the :set_volume client command with:
      | resource      | deployment                 |
      | resource_name | hello-openshift            |
      | action        | --remove                   |
      | name          | hello-openshift-volume     |
    Then the step should succeed
    When I perform the :check_mount_info_on_one_deployment_page web console action with:
      | project_name         | <%= project.name %>    |
      | k8s_deployments_name | hello-openshift        |
      | mount_path           | /hello-openshift-data  |
      | volume_name          | hello-openshift-volume |
    Then the step should fail

  # @author etrott@redhat.com
  # @case_id OCP-12411
  Scenario: Pause and Resume k8s deployment
    Given the master version >= "3.4"
    Given I have a project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/deployment/tc536600/hello-deployment-1.yaml" replacing paths:
      | ["spec"]["replicas"] | 1 |
    Then the step should succeed

    And I wait for the steps to pass:
    """
    When I perform the :pause_k8s_deployment web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
    Then the step should succeed

    When I perform the :check_pause_message web console action with:
      | resource_name | hello-openshift |
    Then the step should succeed
    """
    When I perform the :check_pause_message_on_k8s_deployment_page web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I perform the :check_pause_message_on_overview_page web console action with:
      | project_name  | <%= project.name %> |
      | resource_name | hello-openshift     |
      | resource_type | deployment          |
    Then the step should succeed
    """

    When I run the :patch client command with:
      | resource      | deployment                                                                                                     |
      | resource_name | hello-openshift                                                                                                |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","image":"aosqe/hello-openshift"}]}}}} |
    Then the step should succeed
    When I perform the :check_latest_k8s_deployment_version web console action with:
      | project_name                  | <%= project.name %> |
      | k8s_deployment_name           | hello-openshift     |
      | latest_k8s_deployment_version | 1                   |
    Then the step should succeed
    When I perform the :click_resume_on_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_resource_paused_message_missing web console action with:
      | resource_name | hello-openshift |
    Then the step should succeed

    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 1 |
    Then the step should succeed
    When I perform the :check_latest_k8s_deployment_version web console action with:
      | project_name                  | <%= project.name %> |
      | k8s_deployment_name           | hello-openshift     |
      | latest_k8s_deployment_version | 2                   |
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-11382
  Scenario: AutoScale management for k8s deployment
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/tc536600/hello-deployment-1.yaml |
    Then the step should succeed
    Given I wait until number of replicas match "1" for deployment "hello-openshift"
    When I perform the :add_label_on_edit_autoscaler_page_for_k8s_deployment web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
      | min_pods            | 1                   |
      | max_pods            | 10                  |
      | cpu_req_per         | 50                  |
      | label_key           | autoscaler          |
      | label_value         | deployment          |
    Then the step should succeed
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 1  |
      | max_pods           | 10 |
      | cpu_request_target | 50 |
    Then the step should succeed
    When I perform the :check_hpa_labels_on_other_resources_page web console action with:
      | project_name | <%= project.name %> |
      | hpa_name     | hello-openshift     |
      | label_key    | autoscaler          |
      | label_value  | deployment          |
    Then the step should succeed
    When I perform the :update_min_max_cpu_request_for_autoscaler_from_k8s_deployment_page web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
      | min_pods            | 1                   |
      | max_pods            | 15                  |
      | cpu_req_per         | 50                  |
    Then the step should succeed
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 1  |
      | max_pods           | 15 |
      | cpu_request_target | 50 |
    Then the step should succeed
    When I run the :delete_autoscaler web console action
    Then the step should succeed
    When I perform the :check_autoscaler_info_missing web console action with:
      | min_pods           | 1  |
      | max_pods           | 15 |
      | cpu_request_target | 50 |
    Then the step should succeed
    When I run the :click_add_autoscaler_link web console action
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-12301
  Scenario: Check Events and Environment handling for k8s deployment
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/tc536600/hello-deployment-1.yaml |
    Then the step should succeed
    When I perform the :goto_deployments_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_on_one_deployment web console action with:
      | k8s_deployments_name | hello-openshift |
    Then the step should succeed
    When I run the :click_on_events_tab web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource | rs   |
      | o        | json |
    Then the step succeeded
    Given evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :rs_name clipboard
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Scaling                                      |
      | message | Scaled up replica set <%= cb.rs_name %>      |
    Then the step should succeed
    When I run the :goto_environment_tab web console action
    Then the step should succeed
    When I perform the :add_env_vars web console action with:
      | env_var_key   | deployment1 |
      | env_var_value | value1      |
    Then the step should succeed
    When I perform the :add_env_vars web console action with:
      | env_var_key   | deployment2 |
      | env_var_value | value2      |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    And I wait until number of replicas match "0" for replicaSet "<%= cb.rs_name %>"
    When I run the :click_on_events_tab web console action
    Then the step should succeed
    # https://bugzilla.redhat.com/show_bug.cgi?id=1423461
    When I perform the :check_event_message web console action with:
      | reason  | Scaling                                        |
      | message | Scaled down replica set <%= cb.rs_name %> to 0 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | rs   |
      | o        | json |
    Then the step succeeded
    Given evaluation of `@result[:parsed]['items'].find{ |rs| rs['metadata']['name'] != cb.rs_name }['metadata']['name']` is stored in the :rs_name_new clipboard
    When I perform the :check_event_message web console action with:
      | reason  | Scaling                                          |
      | message | Scaled up replica set <%= cb.rs_name_new %>      |
    Then the step should succeed

    When I perform the :filter_by_keyword web console action with:
      | keyword | <%= cb.rs_name %> |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Scaling                                      |
      | message | Scaled up replica set <%= cb.rs_name %>      |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | reason  | Scaling                                          |
      | message | Scaled up replica set <%= cb.rs_name_new %>      |
    Then the step should succeed

    When I perform the :filter_by_keyword web console action with:
      | keyword | <%= cb.rs_name_new %> |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | reason  | Scaling                                      |
      | message | Scaled up replica set <%= cb.rs_name %>      |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Scaling                                          |
      | message | Scaled up replica set <%= cb.rs_name_new %>      |
    Then the step should succeed

    When I perform the :filter_by_keyword web console action with:
      | keyword | test |
    Then the step should succeed
    When I run the :check_all_events_hidden_by_filter web console action
    Then the step should succeed

    When I run the :goto_environment_tab web console action
    Then the step should succeed

    When I perform the :check_environment_tab web console action with:
      | env_var_key   | deployment1 |
      | env_var_value | value1      |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | deployment2 |
      | env_var_value | value2      |
    Then the step should succeed

    When I perform the :change_env_vars web console action with:
      | env_variable_name | deployment1   |
      | new_env_value     | value1updated |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | deployment1   |
      | env_var_value | value1updated |
    Then the step should succeed

    When I perform the :delete_env_var web console action with:
      | env_var_key | deployment2 |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | deployment2 |
      | env_var_value | value2      |
    Then the step should fail

  # @author etrott@redhat.com
  # @case_id OCP-12350
  Scenario: Check k8s deployments on Overview and Monitoring page
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f      | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/tc536600/hello-deployment-1.yaml |
      | record | true                                                                                                           |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_overview_tile web console action with:
      | image_name    | openshift/hello-openshift |
      | resource_type | deployment                |
      | resource_name | hello-openshift           |
      | scaled_number | 1                         |
    Then the step should succeed
    When I perform the :check_latest_deployment_version_on_overview web console action with:
      | resource_type | deployment      |
      | resource_name | hello-openshift |
      | version       | #1              |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | deployment                                                                                                  |
      | resource_name | hello-openshift                                                                                             |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"aosqe/hello-openshift", "name":"hello-openshift"}]}}}} |
    Then the step should succeed
    Given a pod is present with labels:
      | app=hello-openshift |
    When I perform the :check_overview_tile web console action with:
      | resource_type | deployment            |
      | resource_name | hello-openshift       |
      | image_name    | aosqe/hello-openshift |
      | scaled_number | 1                     |
    Then the step should succeed
    When I perform the :check_latest_deployment_version_on_overview web console action with:
      | resource_type | deployment      |
      | resource_name | hello-openshift |
      | version       | #2              |
    Then the step should succeed
    Given I run the steps 1 times:
    """
    When I run the :scale_up_once web console action
    Then the step should succeed
    """
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 2 |
    Then the step should succeed

    Given I run the steps 1 times:
    """
    When I run the :scale_down_once web console action
    Then the step should succeed
    """
    Given a pod is present with labels:
      | app=hello-openshift |
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 1 |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | deployment                                                                                                       |
      | resource_name | hello-openshift                                                                                                  |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"aosqe/hello-openshift-test", "name":"hello-openshift"}]}}}} |
    Then the step should succeed
    When I perform the :goto_monitoring_page web console action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments               |
      | image_name    | openshift/hello-openshift |
    Then the step should fail
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments           |
      | image_name    | aosqe/hello-openshift |
    Then the step should fail
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments                |
      | image_name    | aosqe/hello-openshift-test |
    Then the step should succeed
    When I run the :click_on_hide_older_resources web console action
    Then the step should succeed
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments               |
      | image_name    | openshift/hello-openshift |
    Then the step should succeed
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments           |
      | image_name    | aosqe/hello-openshift |
    Then the step should succeed
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments                |
      | image_name    | aosqe/hello-openshift-test |
    Then the step should succeed
    When I perform the :expand_resource_logs_by_image web console action with:
      | resource_type | Deployments           |
      | image_name    | aosqe/hello-openshift |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should contain:
      | Logs are not available for replica sets. |
    When I perform the :expand_resource_logs_by_image web console action with:
      | resource_type | Deployments                |
      | image_name    | aosqe/hello-openshift-test |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should contain:
      | To see application logs, view the logs for one of the replica set's |
    And I click the following "a" element:
      | text  | pods |
    Then the step should succeed
    Given the expression should be true> browser.url.start_with? "#{browser.base_url}/console/project/#{project.name}/browse/pods"
