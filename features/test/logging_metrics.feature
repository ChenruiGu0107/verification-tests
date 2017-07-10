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
  Scenario: test install that allow user_write
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory| https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory |

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

    # test single data file format
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                   |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
      | metrics_id   | deadbeef                                                                                          |
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
      | metrics_id   | deadbeef            |
    Then the expression should be true> cb.metrics_data[0][:parsed]['minTimestamp'] == 1460111065369
    Then the expression should be true> cb.metrics_data[0][:parsed]['maxTimestamp'] == 1460413065369
