Feature: AutoScaler relative cases
  # @author yapei@redhat.com
  # @case_id 528864
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
    When I perform the :check_warning_info_for_rc_with_multiple_autoscale web console action with:
      | project_name | <%= project.name%> |
      | dc_name      | myrun              |
      | dc_number    |  1                 |
    Then the step should succeed

