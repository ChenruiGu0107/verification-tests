Feature: Egress-ingress related networking scenarios
  # @author yadu@redhat.com
  # @case_id 521634
  Scenario: Invalid QoS parameter could not be set for the pod
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egress-ingress/invalid-iperf.json |
    Then the step should succeed
    Then I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod   |
      | name     | iperf |
    Then the step should succeed
    And the output should contain "resource value -3000000 is unreasonably"
    """

  # @author yadu@redhat.com
  # @case_id 533252
  @admin
  Scenario: Set the CIDRselector in EgressNetworkPolicy to invalid value
    Given I have a project
    Given I switch to cluster admin pseudo user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egressnetworkpolicy/invalid_policy.json |
      | n | <%= project.name %> |
    Then the step should fail
    And the output should contain "invalid CIDR address"
