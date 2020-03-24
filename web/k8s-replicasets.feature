Feature: Features about k8s replicasets
  # @author yapei@redhat.com
  # @case_id OCP-10991
  Scenario: Attach storage for k8s replicasets
    Given the master version >= "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/replicaSet/tc536589/replica-set.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/nfs/claim-rwo-ui.json |
    Then the step should succeed
    When I perform the :click_to_goto_one_replicaset_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicasets_name | frontend            |
    Then the step should succeed
    When I perform the :add_storage_to_k8s_replicasets web console action with:
      | mount_path  |  /hello-openshift-data |
      | volume_name | hello-openshift-volume |
    Then the step should succeed
    When I perform the :check_mount_info_configuration_for_replicaset web console action with:
      | mount_path  |  /hello-openshift-data |
      | volume_name | hello-openshift-volume |
    Then the step should succeed
    When I perform the :click_pvc_link_on_dc_page web console action with:
      | pvc_name | nfsc |
    Then the step should succeed
    And the expression should be true> browser.url.include? "browse/persistentvolumeclaims"
    When I run the :set_volume client command with:
      | resource      | replicaset                 |
      | resource_name | frontend                   |
      | action        | --remove                   |
      | name          | hello-openshift-volume     |
    Then the step should succeed
    When I perform the :check_mount_info_on_one_replicaset_page web console action with:
      | project_name         | <%= project.name %>    |
      | k8s_replicasets_name | frontend               |
      | mount_path           | /hello-openshift-data  |
      | volume_name          | hello-openshift-volume |
    Then the step should fail

  # @author etrott@redhat.com
  # @case_id OCP-11653
  Scenario: AutoScale management for k8s ReplicaSets
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/deployment/OCP-11653/replicas-set.yaml |
    Then the step should succeed
    When I perform the :add_autoscaler_set_max_pod_from_k8s_rs_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicasets_name | frontend            |
      | max_pods             | 10                  |
    Then the step should succeed
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 1  |
      | max_pods           | 10 |
      | cpu_request_target | 80 |
    Then the step should succeed
    When I perform the :update_min_max_cpu_request_for_autoscaler web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicasets_name | frontend            |
      | min_pods             | 2                   |
      | max_pods             | 10                  |
      | cpu_req_per          | 55                  |
    Then the step should succeed
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 2  |
      | max_pods           | 10 |
      | cpu_request_target | 55 |
    Then the step should succeed
    When I run the :delete_autoscaler web console action
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    I check that there are no hpa in the project
    """
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 2  |
      | max_pods           | 10 |
      | cpu_request_target | 55 |
    Then the step should fail
    When I run the :click_add_autoscaler_link web console action
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-11844
  Scenario: Check Events and Environment handling for ReplicaSet
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/deployment/OCP-11653/replicas-set.yaml |
    Then the step should succeed
    When I perform the :click_to_goto_one_replicaset_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicasets_name | frontend            |
    Then the step should succeed
    When I run the :goto_environment_tab web console action
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | GET_HOSTS_FROM |
      | env_var_value | dns            |
    Then the step should succeed

    When I perform the :add_env_vars web console action with:
      | env_var_key   | replicasets |
      | env_var_value | value1      |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | GET_HOSTS_FROM |
      | env_var_value | dns            |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | replicasets |
      | env_var_value | value1      |
    Then the step should succeed

    When I perform the :change_env_vars web console action with:
      | env_variable_name | replicasets   |
      | new_env_value     | value1updated |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | GET_HOSTS_FROM |
      | env_var_value | dns            |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | replicasets   |
      | env_var_value | value1updated |
    Then the step should succeed

    When I perform the :delete_env_var web console action with:
      | env_var_key | replicasets |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | GET_HOSTS_FROM |
      | env_var_value | dns            |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | replicasets   |
      | env_var_value | value1updated |
    Then the step should fail

    Given I run the steps 2 times:
    """
    When I run the :scale_down_once_on_rs_page web console action
    Then the step should succeed
    """
    When I perform the :check_pods_number_in_table web console action with:
      | pods_number | 1 |
    Then the step should succeed
    When I run the :click_on_events_tab web console action
    Then the step should succeed
    When I perform the :filter_by_keyword web console action with:
      | keyword | delete |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Successful   |
      | message | Deleted pod: |
    Then the step should succeed

    When I run the :scale_up_once_on_rs_page web console action
    Then the step should succeed
    When I perform the :check_pods_number_in_table web console action with:
      | pods_number | 2 |
    Then the step should succeed
    When I run the :click_on_events_tab web console action
    Then the step should succeed
    When I perform the :filter_by_keyword web console action with:
      | keyword | create |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Successful   |
      | message | Created pod: |
    Then the step should succeed
