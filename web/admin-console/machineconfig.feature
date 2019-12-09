Feature: machineconfig/machineconfig pool related

  # @author yanpzhan@redhat.com
  # @case_id OCP-22308
  @admin
  Scenario: Check Machine Config Pools/Machine Configs page
    Given the master version >= "4.1"
    And I open admin console in a browser

    Given the first user is cluster-admin
    When I run the :goto_machineconfig_pools_page web action
    Then the step should succeed
    When I run the :create_resource_by_default_yaml web action
    Then the step should succeed
    Given admin ensures "example" machineconfigpool is deleted after scenario
    When I perform the :check_resource_details web action with:
      | name                    | example          |
      | current_configuration   | rendered-example |
      | machine_config_selector | machineconfiguration.openshift.io/role=master |
    Then the step should succeed

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
