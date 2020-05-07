Feature: functions about resource limits on pod
  # @author yapei@redhat.com
  # @case_id OCP-12178
  Scenario: Set Resource Limits for k8s deployment
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/tc536600/hello-deployment-1.yaml |
    Then the step should succeed
    When I perform the :check_latest_k8s_deployment_version web console action with:
      | project_name                  | <%= project.name %> |
      | k8s_deployment_name           | hello-openshift     |
      | latest_k8s_deployment_version | 1                   |
    Then the step should succeed
    # set resource limits for k8s deployment
    When I perform the :goto_set_resource_limits_for_k8s_deployment web console action with:
      | project_name        | <%= project.name %>   |
      | k8s_deployment_name | hello-openshift       |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Request    |
      | amount_unit     | millicores |
      | resource_amount | 100        |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Limit      |
      | amount_unit     | cores      |
      | resource_amount | 1          |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      | Request    |
      | amount_unit     | MiB        |
      | resource_amount | 1000       |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      | Limit      |
      | amount_unit     | MB         |
      | resource_amount | 1100       |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # check resource limits on web console
    When I perform the :check_limits_on_k8s_deployment_page web console action with:
      | project_name        | <%= project.name %>      |
      | k8s_deployment_name | hello-openshift          |
      | container_name      | hello-openshift          |
      | cpu_range           | 100 millicores to 1 core |
      | memory_range        | 1000 MiB to 1100 MB      |
    Then the step should succeed
    # wait for new replica sets generated
    When I perform the :check_latest_k8s_deployment_version web console action with:
      | project_name                  | <%= project.name %> |
      | k8s_deployment_name           | hello-openshift     |
      | latest_k8s_deployment_version | 2                   |
    Then the step should succeed
    When I perform the :check_limits_on_specific_replica_set_page web console action with:
      | project_name        | <%= project.name %>      |
      | k8s_deployment_name | hello-openshift          |
      | container_name      | hello-openshift          |
      | spe_ver_of_rs       | 2                        |
      | cpu_range           | 100 millicores to 1 core |
      | memory_range        | 1000 MiB to 1100 MB      |
    Then the step should succeed
    When I perform the :check_limits_on_specific_replica_set_page web console action with:
      | project_name        | <%= project.name %>      |
      | k8s_deployment_name | hello-openshift          |
      | container_name      | hello-openshift          |
      | spe_ver_of_rs       | 1                        |
      | cpu_range           | 100 millicores to 1 core |
      | memory_range        | 1000 MiB to 1100 MB      |
    Then the step should fail
    When I perform the :goto_set_resource_limits_for_k8s_deployment web console action with:
      | project_name        | <%= project.name %>   |
      | k8s_deployment_name | hello-openshift       |
    Then the step should succeed
    # set Memory Limit < Memory Request
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      | Limit      |
      | amount_unit     | MB         |
      | resource_amount | 1000       |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Limit can't be less than request (1000 MiB) |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      | Request    |
      | amount_unit     | MiB        |
      | resource_amount | 900.8      |
    Then the step should succeed
    # set CPU Request to character
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Request    |
      | amount_unit     | millicores |
      | resource_amount | eee        |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Must be a number |
    Then the step should succeed
    # set CPU Request to negative number
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Request    |
      | amount_unit     | millicores |
      | resource_amount | -9         |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Can't be negative |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Request    |
      | amount_unit     | millicores |
      | resource_amount | 900        |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # check resource limits after update
    When I perform the :check_limits_on_k8s_deployment_page web console action with:
      | project_name        | <%= project.name %>      |
      | k8s_deployment_name | hello-openshift          |
      | container_name      | hello-openshift          |
      | cpu_range           | 900 millicores to 1 core |
      | memory_range        | 944557260800 mB to 1 GB  |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-12228
  Scenario: Set Resource Limits for k8s replicaset
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/replicaSet/tc536589/replica-set.yaml |
    Then the step should succeed
    When I perform the :goto_set_resource_limits_for_k8s_replicaset web console action with:
      | project_name        | <%= project.name %>   |
      | k8s_replicaset_name | frontend              |
    Then the step should succeed
    # set CPU Limit < CPU Request
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Limit      |
      | amount_unit     | millicores |
      | resource_amount | 50         |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Limit can't be less than request (100 millicores) |
    Then the step should succeed
    # set CPU Limit with invalid charcter
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Limit      |
      | amount_unit     | cores      |
      | resource_amount | Tx2        |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Must be a number |
    Then the step should succeed
    # set CPU Limit with negative number
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Limit      |
      | amount_unit     | cores      |
      | resource_amount | -7         |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Can't be negative |
    Then the step should succeed
    # set correct resource limit
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Limit      |
      | amount_unit     | cores      |
      | resource_amount | 0.2        |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      | Limit      |
      | amount_unit     | MB         |
      | resource_amount | 110        |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_limits_on_k8s_replicaset_page web console action with:
      | project_name        | <%= project.name %>              |
      | k8s_replicaset_name | frontend                         |
      | container_name      | hello-openshift                  |
      | cpu_range           | 100 millicores to 200 millicores |
      | memory_range        | 100 MiB to 110 MB                |
    Then the step should succeed
