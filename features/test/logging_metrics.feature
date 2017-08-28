Feature: test logging and metrics related steps
  @admin
  @destructive
  Scenario: test uninstall
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is uninstalled from the "openshift-infra" project with ansible using:
      | inventory| https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/generic_uninstall_inventory |

  @admin
  @destructive
  Scenario: test install logging <= 3.4
    Given the master version <= "3.4"
    Given I create a project with non-leading digit name
    Given logging service is installed in the project using deployer:
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_deployer.yaml |

  @admin
  @destructive
  Scenario: test install metrics <= 3.4
    Given the master version <= "3.4"
    Given I create a project with non-leading digit name
    Given metrics service is installed in the project using deployer:
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_deployer.yaml |


  Scenario: test bulk insertions
    Given I have a project
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                                    |
      | path         | /metrics/gauges                                                                                        |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data_bulk.json |
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
    Then the expression should be true> cb.metrics_data.count == 2
    # due to fact the top level query does not usually return the same order as the original
    # file, we need to specific to which metric to query if we want verify the contents stored
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
      | metrics_id   | free_memory         |
    Then the expression should be true> cb.metrics_data[0][:parsed]['minTimestamp'] == 1460111065369
    Then the expression should be true> cb.metrics_data[0][:parsed]['maxTimestamp'] == 1460151065369
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
      | metrics_id   | used_memory         |
    Then the expression should be true> cb.metrics_data[0][:parsed]['minTimestamp'] == 1234567890123
    Then the expression should be true> cb.metrics_data[0][:parsed]['maxTimestamp'] == 1321098211412

  @admin
  @destructive
  Scenario: Test unified logging installation
    Given I create a project with non-leading digit name
    Given logging service is installed in the system

  @admin
  @destructive
  Scenario: Test unified metrics installation
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system

  @admin
  @destructive
  Scenario: Test unified metrics installation with user param
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12305/inventory |
