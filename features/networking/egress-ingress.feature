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
    And the output should match "resource .*unreasonably"
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
  @destructive
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


  # @author yadu@redhat.com
  # @case_id 533247
  @admin
  @destructive
  Scenario: All the traffics should be dropped when the single egressnetworkpolicy points to multiple projects
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egressnetworkpolicy/policy.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I have a pod-for-ping in the project
    When I run the :oadm_pod_network_join_projects admin command with:
      | project | <%= cb.proj1 %> |
      | to      | <%= cb.proj2 %> |
    Then the step should succeed
    Given I select a random node's host
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "30 seconds ago" \| grep controller.go |
    Then the step should succeed
    And the output should contain:
      | EgressNetworkPolicy not allowed in shared NetNamespace |
      | <%= cb.proj1 %>                                        |
      | <%= cb.proj2 %>                                        |
      | dropping all traffic                                   |
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 |
    Then the step should succeed
    And the output should contain 1 times:
      | priority=1   |
      | actions=drop |
    When I use the "<%= cb.proj2 %>" project
    When I execute on the "hello-pod" pod:
      | curl           |
      | --head         |
      | www.google.com |
    Then the step should fail
    And the output should contain "Couldn't resolve host"

    When I run the :delete admin command with:
      | object_type       | egressnetworkpolicy |
      | object_name_or_id | default             |
      | n                 | <%= cb.proj1 %>     |
    Then the step should succeed
    When I execute on the "hello-pod" pod:
      | curl           |
      | --head         |
      | www.google.com |
    Then the step should succeed
    And the output should contain "HTTP/1.1 200"
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 |
    Then the step should succeed
    And the output should not contain:
      | priority=1   |
      | actions=drop |

    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    Given I have a pod-for-ping in the project
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj4 clipboard
    When I run the :oadm_pod_network_join_projects admin command with:
      | project | <%= cb.proj3 %> |
      | to      | <%= cb.proj4 %> |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egressnetworkpolicy/policy.json |
      | n | <%= cb.proj3 %> |
    Then the step should succeed
    Given I select a random node's host
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "30 seconds ago" \| grep controller.go |
    Then the step should succeed
    And the output should contain:
      | EgressNetworkPolicy not allowed in shared NetNamespace |
      | <%= cb.proj3 %>                                        |
      | <%= cb.proj4 %>                                        |
      | dropping all traffic                                   |
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 |
    Then the step should succeed
    And the output should contain 1 times:
      | priority=1   |
      | actions=drop |
    When I use the "<%= cb.proj3 %>" project
    When I execute on the pod:
      | curl           |
      | --head         |
      | www.google.com |
   Then the step should fail
    And the output should contain "Couldn't resolve host"


  # @author yadu@redhat.com
  # @case_id 533248
  @admin
  @destructive
  Scenario: egressnetworkpolicy cannot take effect when adding to a globel project
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I have a pod-for-ping in the project
    And the pod named "hello-pod" becomes ready
    Given a "policy1.yaml" file is created with the following lines:
    """
    apiVersion: v1
    kind: EgressNetworkPolicy
    metadata:
      name: policy1
    spec:
      egress:
      - to:
          cidrSelector: 0.0.0.0/32
        type: Deny
    """
    When I run the :create admin command with:
      | f | policy1.yaml    |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    Given I select a random node's host 
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 |
    Then the step should succeed
    And the output should contain 1 times:
      | priority=1   |
      | actions=drop |
    When I execute on the pod:
      | curl           |
      | --head         |
      | www.google.com |
    Then the step should fail
    And the output should contain "Couldn't resolve host"

    When I run the :oadm_pod_network_make_projects_global admin command with:
      | project | <%= cb.proj1 %> |
    Then the step should succeed
    When I use the "<%= cb.proj1 %>" project
    When I execute on the pod:
      | curl           |
      | --head         |
      | www.google.com |
    Then the step should succeed
    And the output should contain "HTTP/1.1 200"
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "30 seconds ago" \| grep controller.go |
    Then the step should succeed
    And the output should contain:
      | EgressNetworkPolicy in global network namespace is not allowed (<%= cb.proj1 %>:policy1) |
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 |
    Then the step should succeed
    And the output should not contain:
      | priority=1   |
      | actions=drop |
    And the project is deleted
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :oadm_pod_network_make_projects_global admin command with:
      | project | <%= cb.proj2 %> |
    Then the step should succeed
    Given a "policy1.yaml" file is created with the following lines:
    """
    apiVersion: v1
    kind: EgressNetworkPolicy
    metadata:
      name: policy1
    spec:
      egress:
      - to:
          cidrSelector: 0.0.0.0/32
        type: Deny
    """
    When I run the :create admin command with:
      | f | policy1.yaml    |
      | n | <%= cb.proj2 %> |
    Given I select a random node's host
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "30 seconds ago" \| grep controller.go |
    Then the step should succeed
    And the output should contain:
      | EgressNetworkPolicy in global network namespace is not allowed (<%= cb.proj2 %>:policy1) |
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O OpenFlow13 \| grep table=9 |
    Then the step should succeed
    And the output should not contain:
      | priority=1   |
      | actions=drop |
    When I use the "<%= cb.proj2 %>" project
    Given I have a pod-for-ping in the project
    And the pod named "hello-pod" becomes ready
    When I execute on the pod:
      | curl           |
      | --head         |
      | www.google.com | 
   Then the step should succeed
   And the output should contain "HTTP/1.1 200"
