Feature: test logging and metrics related steps
  @admin
  @destructive
  Scenario: test uninstall
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12234/inventory |
