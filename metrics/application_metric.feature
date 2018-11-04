Feature: Application metric related tests
  # @author pruan@redhat.com
  # @case_id OCP-15860
  @admin
  @destructive
  Scenario: Undeploy HOSA via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15860/inventory |
    Then all Hawkular agent related resources exist in the project
    And metrics service is uninstalled with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15860/uninstall_inventory |
    Then no Hawkular agent resources exist in the project

