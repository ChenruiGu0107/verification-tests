Feature: machineconfig/machineconfig pool related

  # @author yanpzhan@redhat.com
  # @case_id OCP-22308
  @admin
  @destructive
  Scenario: Check Machine Config Pools/Machine Configs page
    Given the master version >= "4.1"
    And I open admin console in a browser

    Given the first user is cluster-admin
    When I run the :goto_machineconfig_pools_page web action
    Then the step should succeed
    Given admin ensures "example" machineconfigpool is deleted after scenario
    When I run the :create_resource_by_default_yaml web action
    Then the step should succeed
    
    # Page needs some time to load below detail info after created by yaml
    Given I wait up to 30 seconds for the steps to pass:
    """    
    When I perform the :check_resource_details web action with:
      | name                    | example          |
      | current_configuration   | rendered-example |
      | node_selector           | node-role.kubernetes.io/master                |
      | machine_config_selector | machineconfiguration.openshift.io/role=master |
    Then the step should succeed
    """

    When I perform the :click_tab web action with:
      | tab_name | Machine Configs |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | <%= machine_config_pool('example').spec.configuration_source[0]["name"] %> |
      | link_url | <%= machine_config_pool('example').spec.configuration_source[0]["name"] %> |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | <%= machine_config_pool('example').spec.configuration_source[1]["name"] %> |
      | link_url | <%= machine_config_pool('example').spec.configuration_source[1]["name"] %> |
    Then the step should succeed

    # filter on machine configs page
    Given I store all machineconfigs in the :machineconfigs clipboard
    When I run the :goto_machineconfigs_page web action
    Then the step should succeed
    When I perform the :set_filter_strings web action with:
      | filter_text | <%= cb.machineconfigs[0].name %> |
    Then the step should succeed
    When I perform the :check_item_in_table web action with:
      | item | <%= cb.machineconfigs[0].name %> |
    Then the step should succeed
    When I perform the :check_item_in_table web action with:
      | item | <%= cb.machineconfigs[1].name %> |
    Then the step should fail

  # @author yapei@redhat.com
  # @case_id OCP-23688
  @admin
  @destructive
  Scenario: Machine Autoscaler support on console
    Given the master version >= "4.2"
    Given the first user is cluster-admin
    Given I store all machinesets in the "openshift-machine-api" project to the :machinesets clipboard
    And I open admin console in a browser
    When I run the :goto_machine_sets_page web action
    Then the step should succeed
    When I run the :wait_table_loaded web action
    Then the step should succeed
    When I perform the :click_on_resource_name web action with:
      | item | <%= cb.machinesets[0].name %> |
    Then the step should succeed

    # Create Machine Autoscaler
    Given admin ensures "<%= cb.machinesets[0].name %>" machineautoscaler is deleted from the "openshift-machine-api" project after scenario
    When I run the :create_autoscaler_action web action
    Then the step should succeed
    When I perform the :set_minimum_replicas web action with:
      | replicas | 4 |
    Then the step should succeed
    When I perform the :set_maximum_replicas web action with:
      | replicas | 9 |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed
    Given I use the "openshift-machine-api" project
    And the expression should be true> machine_autoscaler('<%= cb.machinesets[0].name %>').minreplicas == 4
    And the expression should be true> machine_autoscaler('<%= cb.machinesets[0].name %>').maxreplicas == 9
    Given evaluation of `machine_autoscaler('<%= cb.machinesets[0].name %>').scaletargetref` is stored in the :machineautoscaler_scaleref clipboard

    # Check MachineAutoscaler info on list page
    When I run the :goto_machineautoscaler_list_page web action
    Then the step should succeed
    When I run the :check_machineautoscaler_list_table_struc web action
    Then the step should succeed
    When I perform the :check_machineautoscaler_name_and_link web action with:
      | resource_name | <%= cb.machinesets[0].name %> |
    Then the step should succeed
    When I perform the :check_machineset_name_and_link web action with:
      | resource_name | <%= cb.machineautoscaler_scaleref['name'] %> |
    Then the step should succeed
    When I perform the :check_table_text_data web action with:
      | text_data | 4 |
    Then the step should succeed
    When I perform the :check_table_text_data web action with:
      | text_data | 9 |
    Then the step should succeed

    # Check MachineAutoscaler info on Overview
    When I perform the :goto_one_machineautoscaler_page web action with:
      | machineautoscaler_name | <%= cb.machinesets[0].name %> |
    Then the step should succeed
    When I perform the :check_min_replicas web action with:
      | replicas_value | 4 |
    Then the step should succeed
    When I perform the :check_max_replicas web action with:
      | replicas_value | 9 |
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-25800
  @admin
  Scenario: check MachineHealthCheck page on console
    Given the master version >= "4.3"
    And I open admin console in a browser
    Given I have a project
    Given the first user is cluster-admin
    When I perform the :goto_machinehealthcheck_page web action with:
     | project_name  | <%= project.name %>  |
    Then the step should succeed
    When I run the :create_resource_by_default_yaml web action
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name              | example  |
      | max_unhealthy     | 40%      |
      | expected_machines | -        |
      | current_healthy   | -        |
    Then the step should succeed
    When I perform the :check_unhealthy_conditions_table web action with:
      | status  | Unknown |
      | timeout | 300s    |
      | type    | Ready   |
    Then the step should succeed
    When I perform the :check_unhealthy_conditions_table web action with:
      | status  | False |
      | timeout | 300s  |
      | type    | Ready |
    Then the step should succeed
    When I perform the :add_annotation_for_resource web action with:
      | annotation_key   | machinecheck     |
      | annotation_value | test             |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | machinehealthcheck |
      | resource_name | example   |
      | o             | yaml      |
    Then the output should contain:
      | machinecheck: test |
    # filter on MachineHealthCheck page
    When I perform the :goto_machinehealthcheck_page web action with:
      | project_name  | <%= project.name %>  |
    Then the step should succeed
    When I perform the :set_filter_strings web action with:
      | filter_text | filterout |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | No Machine Health Checks Found |
    Then the step should succeed
    When I perform the :goto_machinehealthcheck_page web action with:
      | project_name  | <%= project.name %>  |
    Then the step should succeed
    When I perform the :click_one_operation_in_kebab web action with:
      | resource_name | example  |
      | kebab_item    | Delete Machine Health Check |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed
    And I check that there are no machinehealthcheck in the project
