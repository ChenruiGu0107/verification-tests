Feature: MachineHealthCheck Test Scenarios

  # @author jhou@redhat.com
  # @case_id OCP-25741
  @admin
  @destructive
  Scenario: Using external remediation
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user

    Given I use the "openshift-machine-api" project
    And I clone a machineset named "machineset-clone-25741"

    # Create MHC
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cloud/mhc/mhc1.yaml" replacing paths:
      | n                                                                                  | openshift-machine-api       |
      | ["metadata"]["name"]                                                               | mhc-<%= machine_set.name %> |
      | ["spec"]["selector"]["matchLabels"]["machine.openshift.io/cluster-api-cluster"]    | <%= machine_set.cluster %>  |
      | ["spec"]["selector"]["matchLabels"]["machine.openshift.io/cluster-api-machineset"] | <%= machine_set.name %>     |
    Then the step should succeed
    And I ensure "mhc-<%= machine_set.name %>" machinehealthcheck is deleted after scenario

    # Annotate external remediation
    When I run the :annotate client command with:
      | resource     | machinehealthcheck                                           |
      | resourcename | mhc-<%= machine_set.name %>                                  |
      | namespace    | openshift-machine-api                                        |
      | overwrite    | true                                                         |
      | keyval       | machine.openshift.io/remediation-strategy=external-baremetal |
    Then the step should succeed

    # Create unhealthyCondition to trigger machine remediation
    When I create the 'Ready' unhealthyCondition

    Then I wait up to 600 seconds for the steps to pass:
    """
    the expression should be true> machine.annotation("host.metal3.io/external-remediation") == ""
    the expression should be true> machine.instance_state == "running"
    """
