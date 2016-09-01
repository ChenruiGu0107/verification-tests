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
    Given the env is using multitenant network
    Given I have a project
    Given I switch to cluster admin pseudo user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egressnetworkpolicy/invalid_policy.json |
      | n | <%= project.name %> |
    Then the step should fail
    And the output should contain "invalid CIDR address"


  # @author yadu@redhat.com
  # @case_id 533249
  @admin
  Scenario: Only the cluster-admins can create EgressNetworkPolicy
    Given the env is using multitenant network
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egressnetworkpolicy/policy.json |
      | n | <%= project.name %> |
    Then the step should fail
    And the output should contain "cannot create egressnetworkpolicies"
    Given I switch to cluster admin pseudo user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egressnetworkpolicy/policy.json |
      | n | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | egressnetworkpolicy |
      | created             |
    When I run the :get client command with:
      | resource | egressnetworkpolicy |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain "default"
    Given I switch to the first user
    When I run the :get client command with:
      | resource | egressnetworkpolicy |
      | n        | <%= project.name %> |
    Then the step should fail
    And the output should contain "cannot list egressnetworkpolicies"
    When I run the :delete client command with:
      | object_type       | egressnetworkpolicy |
      | object_name_or_id | default             |
    Then the step should fail
    And the output should contain "cannot delete egressnetworkpolicies"
    Given I switch to cluster admin pseudo user
    When I run the :delete client command with:
      | object_type       | egressnetworkpolicy |
      | object_name_or_id | default             |
      | n                 | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | egressnetworkpolicy |
      | deleted             |

  # @author yadu@redhat.com
  # @case_id 534293
  @admin
  Scenario: EgressNetworkPolicy can be deleted after the project deleted
    Given the env is using multitenant network
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egressnetworkpolicy/policy.json |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | egressnetworkpolicy |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain "default"
    And the project is deleted
    When I run the :get admin command with:
      | resource | egressnetworkpolicy |
      | n        | <%= project.name %> |
    And the output should not contain "default"


  # @author yadu@redhat.com
  # @case_id 533858
  @admin
  Scenario: Dropping all traffic when multiple egressnetworkpolicy in one project
    Given the env is using multitenant network
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egressnetworkpolicy/policy.json |
      | n | <%= project.name %> |
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egressnetworkpolicy/533253_policy.json |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | egressnetworkpolicy |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | default |
      | policy1 |
    Given I select a random node's host
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep controller.go |
    Then the step should succeed
    And the output should contain:
      | multiple EgressNetworkPolicies in same network namespace |
      | dropping all traffic                                     |
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 |
    Then the step should succeed
    And the output should contain 1 times:
      | priority=1   |
      | actions=drop |
