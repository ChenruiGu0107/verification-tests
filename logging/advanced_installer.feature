Feature: advanced installer related tests
  # @author pruan@redhat.com
  # @case_id OCP-17156
  @admin
  @destructive
  Scenario: Deploy cluster with new NFS Host
    Given the master version <= "3.9"
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    Given I run oc create as admin with "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17156/pv.yaml" replacing paths:
      | ["spec"]["nfs"]["server"] | <%= env.master_hosts.first %> |
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17156/inventory |
    Then the expression should be true> pvc('logging-es-0').capacity == '10Gi'
    Then the expression should be true> pv('logging-volume').capacity_raw == '10Gi'

