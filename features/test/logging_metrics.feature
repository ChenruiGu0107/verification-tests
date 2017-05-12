Feature: test logging and metrics related steps
  @admin
  @destructive
  Scenario: test uninstall
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is uninstalled from the "openshift-infra" project with ansible using:
      | inventory| https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/generic_uninstall_inventory |
