Feature: AutoScaler relative cases
  # @author yapei@redhat.com
  # @case_id OCP-12157
  Scenario: Show the warnings when multiple HPAs target the same resource
    Given I have a project
    When I run the :run client command with:
      | name  | myrun                 |
      | image | aosqe/hello-openshift |
    Then the step should succeed
    Given I wait until the status of deployment "myrun" becomes :running
    When I perform the :add_autoscaler_set_max_pod_and_cpu_req_per_from_dc_page web console action with:
      | project_name | <%= project.name%> |
      | dc_name      | myrun              |
      | max_pods     | 10                 |
      | cpu_req_per  | 50                 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | hpa |
    Then the step should succeed
    And the output should contain:
      | DeploymentConfig/myrun |
    When I run the :autoscale client command with:
      | name | rc/myrun-1 |
      | min  | 2          |
      | max  | 8          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | hpa |
    Then the step should succeed
    And the output should contain:
      | ReplicationController/myrun-1 |
    Given I wait until replicationController "myrun-1" is ready
    When I perform the :check_warning_info_for_rc_with_multiple_autoscale web console action with:
      | project_name | <%= project.name%> |
      | dc_name      | myrun              |
      | dc_number    |  1                 |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-11961
  Scenario: Show the warning when metrics not configured and CPU request not set
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/nodejs:latest                |
      | code         | https://github.com/sclorg/nodejs-ex |
      | name         | nodejs-sample                          |
    Then the step should succeed
    When I perform the :check_warning_info_when_create_hpa_without_metrics_and_cpu_request web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | nodejs-sample       |
    Then the step should succeed
    When I perform the :add_autoscaler_set_max_pod_and_cpu_req_per_from_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | nodejs-sample       |
      | max_pods     | 10                  |
      | cpu_req_per  | 50                  |
    Then the step should succeed

    When I run the :get client command with:
      | resource | hpa |
    Then the step should succeed
    And the output should contain:
      | DeploymentConfig/nodejs-sample |

    When I perform the :check_warning_info_after_create_hpa_without_metrics_and_cpu_request web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | nodejs-sample       |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-11817
  Scenario: Labels management in edit autoscaler page on web console
    Given I have a project
    When I run the :run client command with:
      | name  | myrun                 |
      | image | yapei/hello-openshift |
    Then the step should succeed
    Given I wait until the status of deployment "myrun" becomes :running
    When I perform the :add_label_on_edit_autoscaler_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
      | min_pods     | 1                   |
      | max_pods     | 10                  |
      | cpu_req_per  | 55                  |
      | label_key    | test1               |
      | label_value  | value1              |
    Then the step should succeed
    When I run the :get client command with:
      | resource | hpa |
    Then the step should succeed
    And the output should contain "myrun"
    When I perform the :check_hpa_labels_on_other_resources_page web console action with:
      | project_name | <%= project.name %> |
      | hpa_name     | myrun               |
      | label_key    | test1               |
      | label_value  | value1              |
    Then the step should succeed
    When I perform the :update_label_on_edit_autoscaler_page web console action with:
      | project_name    | <%= project.name %> |
      | dc_name         | myrun               |
      | label_key       | test1               |
      | new_label_value | value1update        |
    Then the step should succeed
    When I perform the :check_hpa_labels_on_other_resources_page web console action with:
      | project_name | <%= project.name %> |
      | hpa_name     | myrun               |
      | label_key    | test1               |
      | label_value  | value1update        |
    Then the step should succeed
    When I perform the :delete_label_on_edit_autoscaler_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
      | label_key    | test1               |
    Then the step should succeed
    When I perform the :check_redirection_to_dc_page web console action with:
      | dc_name | myrun |
    Then the step should succeed
    When I perform the :check_hpa_labels_on_other_resources_page_missing web console action with:
      | project_name | <%= project.name %> |
      | hpa_name     | myrun               |
      | label_key    | test1               |
      | label_value  | value1update        |
    Then the step should succeed
    And the output should contain "element not found"

  # @author yanpzhan@redhat.com
  # @case_id OCP-11287
  Scenario: Create,Edit and Delete HPA from replication controller page
    Given I have a project
    # Create a standalone rc
    When I run the :run client command with:
      | name       | myrun-rc              |
      | image      | aosqe/hello-openshift |
      | generator  | run-controller/v1     |
      | limits     | memory=256Mi          |
    Then the step should succeed

    When I perform the :add_autoscaler_on_standalone_rc_page web console action with:
      | project_name | <%= project.name %> |
      | rc_name      | myrun-rc            |
      | min_pods     | 1                   |
      | max_pods     | 2                   |
      | cpu_req_per  | 50                  |
    Then the step should succeed

    When I perform the :check_autoscaler_info web console action with:
      | min_pods            | 1            |
      | max_pods            | 2            |
      | cpu_request_target  | 50           |
    Then the step should succeed

    When I perform the :update_min_max_cpu_request_for_autoscaler_from_standalone_rc_page web console action with:
      | project_name | <%= project.name %> |
      | rc_name      | myrun-rc            |
      | min_pods     | 1                   |
      | max_pods     | 4                   |
      | cpu_req_per  | 50                  |
    Then the step should succeed

    When I perform the :check_autoscaler_info web console action with:
      | min_pods            | 1            |
      | max_pods            | 4            |
      | cpu_request_target  | 50           |
    Then the step should succeed

    When I run the :delete_autoscaler web console action
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I perform the :check_autoscaler_info_missing web console action with:
      | min_pods           | 1             |
      | max_pods           | 4             |
      | cpu_request_target | 50            |
    Then the step should succeed
    """
    
    When I perform the :check_autoscaler_info_missing_on_overview_page web console action with:
      | project_name  | <%= project.name %>    |
      | resource_type | replication controller |
      | resource_name | myrun-rc               |
      | min_pods      | 1                      |
      | max_pods      | 4                      |
    Then the step should succeed
