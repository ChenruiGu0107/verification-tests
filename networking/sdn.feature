Feature: SDN related networking scenarios
  # @author bmeng@redhat.com
  # @case_id OCP-11795
  @admin
  @destructive
  Scenario: k8s iptables sync loop and openshift iptables sync loop should work together
    Given I have a project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource | svc |
      | resource_name | service-unsecure |
      | template | {{.spec.clusterIP}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :service_ip clipboard
    Given I select a random node's host
    And the node iptables config is verified
    And the node service is restarted on the host after scenario
    When I run commands on the host:
      | iptables -S -t nat \| grep "\-s <%= cb.clusternetwork %>" \| cut -d ' ' -f 2- |
    Then the step should succeed
    And evaluation of `@result[:response].chomp` is stored in the :nat_rule1 clipboard
    When I run commands on the host:
      | iptables -S -t nat \| grep <%= cb.service_ip %> \| cut -d ' ' -f 2- |
    Then the step should succeed
    And evaluation of `@result[:response].chomp` is stored in the :nat_rule2 clipboard

    When I run commands on the host:
      | iptables -t nat -D <%= cb.nat_rule1 %> |
      | iptables -t nat -D <%= cb.nat_rule2 %> |
    Then the step should succeed
    And I wait up to 40 seconds for the steps to pass:
    """
    When I run commands on the host:
      | iptables -S -t nat |
    Then the step should succeed
    And the output should contain:
      | <%= cb.nat_rule1 %> |
      | <%= cb.nat_rule2 %> |
    """

  # @author bmeng@redhat.com
  # @case_id OCP-12549
  @admin
  @destructive
  Scenario: The openshift master should handle the node subnet when the node added/removed
    Given environment has at least 2 nodes
    And I select a random node's host
    Given I switch to cluster admin pseudo user
    And the node network is verified
    And the node service is verified
    And the node labels are restored after scenario
    When I run the :get admin command with:
      | resource | hostsubnet |
    Then the step should succeed
    And the output should contain "<%= node.name %>"
    When I run the :delete admin command with:
      | object_type | node |
      | object_name_or_id | <%= node.name %> |
    Then the step should succeed
    Given I wait for the networking components of the node to be terminated
    When I run the :get admin command with:
      | resource | hostsubnet |
    Then the step should succeed
    And the output should not contain "<%= node.name %>"

    Given the node service is restarted on the host
    And I wait for the networking components of the node to become ready
    When I run the :get admin command with:
      | resource | hostsubnet |
    Then the step should succeed
    And the output should contain "<%= node.name %>"
    When I run the :get admin command with:
      | resource | hostsubnet |
      | template | {{(index .items 0).subnet}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :node0_ip clipboard
    When I run the :get admin command with:
      | resource | hostsubnet |
      | template | {{(index .items 1).subnet}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :node1_ip clipboard
    When I run commands on the host:
      | ping -c 2 $(echo "<%= cb.node0_ip %>" \| sed 's/.\{4\}$/1/g') |
    Then the step should succeed
    When I run commands on the host:
      | ping -c 2 $(echo "<%= cb.node1_ip %>" \| sed 's/.\{4\}$/1/g') |
    Then the step should succeed

  # @author zzhao@redhat.com
  # @case_id OCP-9753
  @admin
  Scenario: ovs-port should be deleted after delete pods
    Given I have a project
    And I have a pod-for-ping in the project
    Then evaluation of `pod.node_name` is stored in the :node_name clipboard
    When I execute on the pod:
      | bash | -c | ip link show eth0 \| awk -F@ '{ print $2 }' \| awk -F: '{ print $1 }' |
    Then the output should contain "if"
    And evaluation of `@result[:response].strip` is stored in the :ifindex clipboard
    When I run command on the "<%= cb.node_name %>" node's sdn pod:
      | bash | -c | ip addr show <%= cb.ifindex %> \| head -1 \| awk -F@ '{ print $1 }' \| awk '{ print $2 }' |
    Then the output should contain "veth"
    And evaluation of `@result[:response].strip` is stored in the :veth_index clipboard
    When I run command on the "<%= cb.node_name %>" node's sdn pod:
      | bash | -c | ovs-ofctl -O openflow13 show br0 |
    Then the output should contain "<%= cb.veth_index %>"
    Given I ensure "hello-pod" pod is deleted
    And I wait up to 100 seconds for the steps to pass:
    """
    When I run command on the "<%= cb.node_name %>" node's sdn pod:
      | bash | -c | ip a |
    Then the output should not contain "<%= cb.veth_index %>"
    When I run command on the "<%= cb.node_name %>" node's sdn pod:
      | bash | -c | ovs-ofctl -O openflow13 show br0 |
    Then the output should not contain "<%= cb.veth_index %>"
    """

  # @author hongli@redhat.com
  # @case_id OCP-14271
  @admin
  @destructive
  Scenario: add rule to OPENSHIFT-ADMIN-OUTPUT-RULES chain
    Given the master version >= "3.6"
    Given I have a project
    # create target pod and services for ping or curl
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=caddy-pods |
    And evaluation of `pod.ip` is stored in the :target_pod_ip clipboard
    And evaluation of `service("service-unsecure").ip(user: user)` is stored in the :service_unsecure_ip clipboard
    And evaluation of `service("service-secure").ip(user: user)` is stored in the :service_secure_ip clipboard

    # create a pod which under controlled by the rule
    Given I have a pod-for-ping in the project
    Then I use the "<%= pod.node_name(user: user) %>" node
    And evaluation of `pod.ip` is stored in the :pod_ip clipboard
    Given I register clean-up steps:
    """
    When I run commands on the host:
      | iptables -D OPENSHIFT-ADMIN-OUTPUT-RULES -s <%= cb.pod_ip %> -j REJECT |
    Then the step should succeed
    """
    When I run commands on the host:
      | iptables -A OPENSHIFT-ADMIN-OUTPUT-RULES -s <%= cb.pod_ip %> -j REJECT |
    Then the step should succeed

    # ensure external traffic is rejected but the connection between pods or services is not affected
    When I execute on the pod:
      | curl | --connect-timeout | 5 | www.redhat.com |
    Then the step should fail
    And the output should contain "Connection refused"
    When I execute on the pod:
      | ping | -c | 5 | <%= cb.target_pod_ip %> |
    Then the step should succeed
    And the output should contain "0% packet loss"
    When I execute on the pod:
      | curl | --connect-timeout | 5 | http://<%= cb.service_unsecure_ip %>:27017 |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    When I execute on the pod:
      | curl | --connect-timeout | 5 | https://<%= cb.service_secure_ip %>:27443 | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

  # @author hongli@redhat.com
  # @case_id OCP-14273
  @admin
  @destructive
  Scenario: the rules in OPENSHIFT-ADMIN-OUTPUT-RULES should be applied after EgressNetworkPoliy
    Given the master version >= "3.6"
    Given I have a project
    And I have a pod-for-ping in the project
    Then I use the "<%= pod.node_name(user: user) %>" node
    And evaluation of `pod.ip` is stored in the :pod_ip clipboard

    # add one rule to log all traffic from the pod
    Given I register clean-up steps:
    """
    When I run commands on the host:
      | iptables -D OPENSHIFT-ADMIN-OUTPUT-RULES -s <%= cb.pod_ip %> -j LOG --log-prefix "ADMIN-RULES: " --log-level 4 |
    Then the step should succeed
    """
    When I run commands on the host:
      | iptables -A OPENSHIFT-ADMIN-OUTPUT-RULES -s <%= cb.pod_ip %> -j LOG --log-prefix "ADMIN-RULES: " --log-level 4 |
    Then the step should succeed

    # ensure the logs can be observed before apply EgressNetworkPolicy
    When I execute on the pod:
      | curl | --connect-timeout | 5 | www.redhat.com |
    Then the step should succeed
    When I run commands on the host:
      | journalctl -k --since "10 seconds ago" |
    Then the step should succeed
    And the output should match "ADMIN-RULES.*SRC=<%= cb.pod_ip %>"

    # apply the EgressNetworkPolicy to drop all external traffic
    Given I switch to cluster admin pseudo user
    Given I obtain test data file "networking/egressnetworkpolicy/internal-policy.json"
    When I run the :create client command with:
      | f | internal-policy.json |
      | n | <%= project.name %> |
    Then the step should succeed

    # ensure the logs cannot be observed after apply EgressNetworkPolicy
    Given I switch to the first user
    When I execute on the pod:
      | curl | --connect-timeout | 5 | www.redhat.com |
    Then the step should fail
    And the output should contain "Connection timed out"
    When I run commands on the host:
      | journalctl -k --since "10 seconds ago" |
    Then the step should succeed
    And the output should not contain "ADMIN-RULES"

  # @author hongli@redhat.com
  # @case_id OCP-14354
  @admin
  @destructive
  Scenario: Deleting a node should not breaks node to node networking for the cluster
    Given environment has at least 3 nodes
    And environment has at least 2 schedulable nodes
    And I store the schedulable workers in the clipboard
    Given I switch to cluster admin pseudo user

    # Delete the nodes[0]
    Given I use the "<%= cb.nodes[0].name %>" node
    And the node network is verified
    And the node service is verified
    And I register clean-up steps:
    """
    Given I wait for the networking components of the node to become ready
    """
    # re-create the node, this won't work we have to save in a clipboard
    And I store the node "<%= cb.nodes[0].name %>" YAML to the clipboard
    And the node labels are restored after scenario
    And the node service is restarted on the host after scenario
    # do this first
    And the node in the clipboard is restored from YAML after scenario
    When I run the :delete admin command with:
      | object_type       | node                    |
      | object_name_or_id | <%= cb.nodes[0].name %> |
    Then the step should succeed
    Given I wait for the networking components of the node to be terminated
    When I run the :get admin command with:
      | resource | hostsubnet |
    Then the step should succeed
    And the output should not contain "<%= cb.nodes[0].name %>"

    # Check if nodes are reachable from a pod
    Given host subnets are stored in the clipboard
    And evaluation of `IPAddr.new(host_subnet.subnet).succ` is stored in the :nodeA_ip clipboard
    And evaluation of `IPAddr.new(host_subnet(-2).subnet).succ` is stored in the :nodeB_ip clipboard

    Given I switch to the first user
    And I have a project
    And I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | -c | ping -c 2 <%= cb.nodeA_ip %> |
    Then the step should succeed
    When I execute on the pod:
      | bash | -c | ping -c 2 <%= cb.nodeB_ip %> |
    Then the step should succeed

    # Check if connections between nodes are reachable
    Given I switch to cluster admin pseudo user
    Given I use the "<%= cb.nodes[1].name %>" node
    When I run commands on the host:
      | ping -c 2 <%= cb.nodeA_ip %> |
    Then the step should succeed
    When I run commands on the host:
      | ping -c 2 <%= cb.nodeB_ip %> |
    Then the step should succeed

  # @author zzhao@redhat.com
  # @case_id OCP-19807
  @admin
  @destructive
  Scenario: The stale flows can be deleted when the new br0 created
    Given the master version >= "3.9"
    And I select a random node's host
    And the node service is verified
    And the node network is verified
    When I run the ovs commands on the host:
      | ovs-ofctl -O openflow13 add-flow br0 "table=99, actions=drop" |
    Then the step should succeed
    #Delete the table=253 and make the sdn re-setup
    When I run the ovs commands on the host:
      | ovs-ofctl -O openflow13 del-flows br0 "table=253" |
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should succeed
    Given I wait up to 120 seconds for the steps to pass:
    """
    When I run the ovs commands on the host:
      | ovs-ofctl -O openflow13 dump-flows br0 "table=253" |
    Then the output should contain "table=253"
    When I run the ovs commands on the host:
      | ovs-ofctl -O openflow13 dump-flows br0 "table=99" |
    Then the output should not contain "table=99"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-22655
  @admin
  @destructive
  Scenario: The openflow should be clear up when namespaces is deleted
    Given the master version >= "3.7"
    And the env is using networkpolicy plugin
    And I have a project
    And I have a pod-for-ping in the project
    Then evaluation of `pod.node_name` is stored in the :node_name clipboard
    When I run the :get admin command with:
      | resource | netnamespace |
      | resource_name | <%= project.name %> |
      | template | {{.netid}} |
    Then the step should succeed
    And evaluation of `@result[:response].strip.to_f.to_i.to_s(16)` is stored in the :proj1netid clipboard
    When I run command on the "<%= cb.node_name %>" node's sdn pod:
      | bash | -c | ovs-ofctl dump-flows br0 -O openflow13 \| grep <%= cb.proj1netid %> |
    Then the step should succeed
    And the output should contain "table=80"
    When I run the :delete client command with:
      | object_type       | project             |
      | object_name_or_id | <%= project.name %> |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run command on the "<%= cb.node_name %>" node's sdn pod:
      | bash | -c | ovs-ofctl dump-flows br0 -O openflow13 |
    Then the step should succeed
    And the output should not contain "<%= cb.proj1netid %>"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-24395
  @admin
  Scenario: The arping should be installed in openshift-sdn
    Given I store the ready and schedulable nodes in the :nodes clipboard
    When I run command on the "<%= cb.nodes[0].name %>" node's sdn pod:
      | bash | -c | which arping |
    Then the step should succeed
    And the output should contain "/usr/sbin/arping"

  # @author zzhao@redhat.com
  # @case_id OCP-23337
  @admin
  @destructive
  Scenario: Application pod should NOT be killed after the ovs restart
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    #Create one test pod and check it's ip did not be changed when ovs pod is restarted.
    And I have a pod-for-ping in the project
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    Then evaluation of `pod.node_name` is stored in the :node_name clipboard
    Given I restart the ovs pod on the "<%= cb.node_name %>" node
    Then the step should succeed
    Then the expression should be true> cb.pod_ip == cb.ping_pod.ip(cached: false)
    #Create another pod and check the above pod if work well
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.pod_ip %>:8080 |
    And the output should contain "Hello"

  # @author zzhao@redhat.com
  # @case_id OCP-23213
  @admin
  @destructive
  Scenario: SDN pod should be working well after the node reboot
    Given I have a project
    #Create pod before node reboot
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `service("test-service").url` is stored in the :svc_url clipboard
    And evaluation of `pod(0).node_name` is stored in the :node_name clipboard
    Given I use the "<%= cb.node_name %>" node
    And the host is rebooted and I wait it up to 600 seconds to become available
    And the node network is verified

    Given I obtain test data file "networking/aosqe-pod-for-ping.json"
    When I run oc create over "aosqe-pod-for-ping.json" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.node_name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=hello-pod |
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.svc_url %> |
    Then the step should succeed
    And the output should contain "Hello"

  # @author zzhao@redhat.com
  # @case_id OCP-23215
  @admin
  @destructive
  Scenario: SDN pod should be working well after the node service is restarted
    Given I have a project
    #Create pod before node service restarted
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `service("test-service").url` is stored in the :svc_url clipboard
    And evaluation of `pod(0).node_name` is stored in the :node_name clipboard
    Given I use the "<%= cb.node_name %>" node
    And the node service is restarted on the host
    And the node network is verified

    Given I obtain test data file "networking/aosqe-pod-for-ping.json"
    When I run oc create over "aosqe-pod-for-ping.json" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.node_name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=hello-pod |
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.svc_url %> |
    Then the step should succeed
    And the output should contain "Hello"

  # @author zzhao@redhat.com
  # @case_id OCP-23249
  @admin
  @destructive
  Scenario: SDN pod should be working well after the crio service is reboot
    Given I have a project
    #Create pod before node service restarted
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `service("test-service").url` is stored in the :svc_url clipboard
    And evaluation of `pod(0).node_name` is stored in the :node_name clipboard
    Given I use the "<%= cb.node_name %>" node
    When I run commands on the host:
      | systemctl restart crio |
    And the node network is verified

    Given I obtain test data file "networking/aosqe-pod-for-ping.json"
    When I run oc create over "aosqe-pod-for-ping.json" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.node_name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=hello-pod |
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.svc_url %> |
    Then the step should succeed
    And the output should contain "Hello"

  # @author zzhao@redhat.com
  # @case_id OCP-23274
  @admin
  Scenario: warn message to user when idling service for networkpolicy mode
    Given I have a project
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    When I run the :idle admin command with:
      | svc_name | test-service        |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain "WARNING: idling when network policies are in place may cause connections to bypass network policy entirely"
