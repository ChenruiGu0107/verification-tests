Feature: SDN related networking scenarios
  # @author bmeng@redhat.com
  # @case_id 519348
  @admin
  @destructive
  Scenario: set MTU on vovsbr and vlinuxbr
    Given I select a random node's host
    And the node network is verified
    And system verification steps are used:
    """
    When I run commands on the host:
      | grep -i mtu /etc/origin/node/node-config.yaml \| sed 's/[^0-9]*//g' |
    Then the step should succeed
    And evaluation of `@result[:response].chomp` is stored in the :mtu clipboard
    Given the expression should be true> cb.mtu != "3450"
    When I run commands on the host:
      | ip link show lbr0 |
    Then the expression should be true> @result[:response].include?(cb.mtu)
    When I run commands on the host:
      | ip link show vovsbr |
    Then the expression should be true> @result[:response].include?(cb.mtu)
    When I run commands on the host:
      | ip link show vlinuxbr |
    Then the expression should be true> @result[:response].include?(cb.mtu)
    When I run commands on the host:
      | ip link show tun0 |
    Then the expression should be true> @result[:response].include?(cb.mtu)
    """
    Given the node service is restarted on the host after scenario
    And I register clean-up steps:
    """
    When I run commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 \|\| docker exec openvswitch ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    """
    And the "/etc/origin/node/node-config.yaml" file is restored on host after scenario
    When I run commands on the host:
      | sed -i 's/mtu:.*/mtu: 3450/g' /etc/origin/node/node-config.yaml |
    Then the step should succeed
    When I run commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 \|\| docker exec openvswitch ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    When I run commands on the host:
      | systemctl restart atomic-openshift-node |
    Then the step should succeed
    When I run commands on the host:
      | ip link show vovsbr |
    Then the output should contain "mtu 3450"
    When I run commands on the host:
      | ip link show vlinuxbr |
    Then the output should contain "mtu 3450"
    When I run commands on the host:
      | ip link show tun0 |
    Then the output should contain "mtu 3450"

  # @author bmeng@redhat.com
  # @case_id 528291
  @admin
  @destructive
  Scenario: It should not block the node gets started when /etc/hosts has 127.0.0.1 equal to hostname
    Given I select a random node's host
    And the node network is verified
    And the node service is verified
    And system verification steps are used:
    """
    When I run commands on the host:
      | grep 127.0.0.1.*$(hostname) /etc/hosts |
    Then the step should fail
    """
    Given the node service is restarted on the host after scenario
    And I register clean-up steps:
    """
    When I run commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 \|\| docker exec openvswitch ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    """
    And the "/etc/hosts" file is restored on host after scenario
    When I run commands on the host:
      | echo "127.0.0.1  $(hostname)" >> /etc/hosts |
    Then the step should succeed
    When I run commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 \|\| docker exec openvswitch ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    When I run commands on the host:
      | systemctl restart atomic-openshift-node |
    Then the step should succeed
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "30s ago" |
    Then the step should succeed
    And the output should contain:
      | Failed to determine node address from hostname |
      | using default interface                        |
    When I run commands on the host:
      | systemctl status atomic-openshift-node |
    Then the output should contain "active (running)"

  # @author yadu@redhat.com
  # @case_id 517334
  @admin
  @destructive
  Scenario: bridge-nf-call-iptables should be disable on node
    Given I select a random node's host
    And the node network is verified
    And the node service is verified
    And system verification steps are used:
    """
    When I run commands on the host:
      | sysctl --all --pattern 'bridge.*iptables' |
    Then the step should succeed
    And the output should contain "net.bridge.bridge-nf-call-iptables = 0"
    """
    Given the node service is restarted on the host after scenario
    And I register clean-up steps:
    """
    When I run commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 \|\| docker exec openvswitch ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    """
    When I run commands on the host:
      | systemctl stop atomic-openshift-node |
    Then the step should succeed
    When I run commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 \|\| docker exec openvswitch ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    When I run commands on the host:
      | sysctl -w net.bridge.bridge-nf-call-iptables=1 |
    Then the step should succeed
    When I run commands on the host:
      | systemctl start atomic-openshift-node |
    Then the step should succeed
    When I run commands on the host:
      | systemctl status atomic-openshift-node |
    Then the output should contain "active (running)"
    When I run commands on the host:
      | sysctl --all --pattern 'bridge.*iptables' |
    Then the step should succeed
    And the output should contain "net.bridge.bridge-nf-call-iptables = 0"

  # @author bmeng@redhat.com
  # @case_id 521640
  @admin
  @destructive
  Scenario: SDN will be re-initialized when the version in openflow does not match the one in controller
    Given I select a random node's host
    And the node network is verified
    And the node service is verified
    When I run commands on the host:
      | (ovs-ofctl dump-flows br0 -O openflow13 2>/dev/null \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O openflow13) \| sed -n -e 's/^.*note://p' \| cut -c 1,2 |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :plugin_type clipboard
    When I run commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:<%= cb.plugin_type.chomp %>.ff" -O openflow13 \|\| docker exec openvswitch ovs-ofctl mod-flows br0 "table=253, actions=note:<%= cb.plugin_type.chomp %>.ff" -O openflow13 |
    Then the step should succeed
    When I run commands on the host:
      | systemctl restart atomic-openshift-node |
    Then the step should succeed
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep controller.go |
    Then the step should succeed
    And the output should contain "[SDN setup] full SDN setup required"

  # @author yadu@redhat.com
  # @case_id 528378
  @admin
  @destructive
  Scenario: [Bug 1308701] kubelet proxy could change to userspace mode
    Given I select a random node's host
    And the node network is verified
    And the node service is verified
    And system verification steps are used:
    """
    When I run commands on the host:
      | grep -A 1 proxy-mode /etc/origin/node/node-config.yaml |
    Then the step should succeed
    Then the output should contain "- iptables"
    """
    Given the node service is restarted on the host after scenario
    And the "/etc/origin/node/node-config.yaml" file is restored on host after scenario
    When I run commands on the host:
      | sed -i "/proxy-mode/{n;s/iptables/userspace/g}" /etc/origin/node/node-config.yaml |
    Then the step should succeed
    When I run commands on the host:
      | systemctl restart atomic-openshift-node |
    Then the step should succeed
    When I run commands on the host:
      | systemctl status atomic-openshift-node |
    Then the output should contain "active (running)"
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep node.go |
    Then the step should succeed
    And the output should contain "Using userspace Proxier"

  # @author bmeng@redhat.com
  # @case_id 528505
  @admin
  @destructive
  Scenario: iptables rules will be repaired automatically once it gets destroyed
    Given I select a random node's host
    And the node iptables config is verified
    And the node service is restarted on the host after scenario
    When I run commands on the host:
      | iptables -S -t nat \| grep <%= cb.clusternetwork %> \| cut -d ' ' -f 2- |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :nat_rule clipboard
    When I run commands on the host:
      | iptables -S \| grep tun0 \| cut -d ' ' -f 2- |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :tun0_rule clipboard
    When I run commands on the host:
      | iptables -D INPUT -p udp -m multiport --dport 4789 -m comment --comment "001 vxlan incoming" -j ACCEPT |
      | iptables -D <%= cb.tun0_rule %> |
      | iptables -D FORWARD -s <%= cb.clusternetwork %> -j ACCEPT |
      | iptables -D FORWARD -d <%= cb.clusternetwork %> -j ACCEPT |
      | iptables -t nat -D <%= cb.nat_rule %> |
    Then the step should succeed
    And I wait up to 35 seconds for the steps to pass:
    """
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "5s ago" \| grep node_iptables.go |
    Then the output should contain "Syncing openshift iptables rules"
    And the output should contain "syncIPTableRules took"
    """
    When I run commands on the host:
      | iptables -S -t filter |
    Then the output should contain:
      | INPUT -p udp -m multiport --dports 4789 -m comment --comment "001 vxlan incoming" -j ACCEPT |
      | <%= cb.tun0_rule %> |
      | FORWARD -s <%= cb.clusternetwork %> -j ACCEPT |
      | FORWARD -d <%= cb.clusternetwork %> -j ACCEPT |
    When I run commands on the host:
      | iptables -S -t nat |
    Then the output should contain:
      | <%= cb.nat_rule %> |

  # @author bmeng@redhat.com
  # @case_id 528506
  @admin
  @destructive
  Scenario: iptablesSyncPeriod should be configurable
    Given I select a random node's host
    When I run commands on the host:
      | grep iptablesSyncPeriod /etc/origin/node/node-config.yaml |
    Then the output should match ".*30s"
    Given the node iptables config is verified
    And the node service is restarted on the host after scenario
    And the "/etc/origin/node/node-config.yaml" file is restored on host after scenario
    When I run commands on the host:
      | sed -i 's/iptablesSyncPeriod:.*/iptablesSyncPeriod: "10s"/g' /etc/origin/node/node-config.yaml |
    Then the step should succeed
    Given the node service is restarted on the host
    When I run commands on the host:
      | iptables -D INPUT -p udp -m multiport --dport 4789 -m comment --comment "001 vxlan incoming" -j ACCEPT |
    Then the step should succeed
    And I wait up to 15 seconds for the steps to pass:
    """
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "5s ago" \| grep node_iptables.go |
    Then the output should contain "Syncing openshift iptables rules"
    And the output should contain "syncIPTableRules took"
    """
    When I run commands on the host:
      | iptables -S -t filter |
    Then the output should contain:
      | INPUT -p udp -m multiport --dports 4789 -m comment --comment "001 vxlan incoming" -j ACCEPT |

  # @author bmeng@redhat.com
  # @case_id 528507
  @admin
  @destructive
  Scenario: k8s iptables sync loop and openshift iptables sync loop should work together
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
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
      | iptables -S -t nat \| grep <%= cb.clusternetwork %> \| cut -d ' ' -f 2- |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :nat_rule clipboard
    When I run commands on the host:
      | iptables -t nat -D <%= cb.nat_rule %> |
      | iptables -t filter -D OUTPUT -m comment --comment "kubernetes service portals" -j KUBE-SERVICES |
      | iptables -t nat -S \| grep <%= cb.service_ip %> \| cut -d ' ' -f2- \| xargs -L1 iptables -t nat -D |
    Then the step should succeed
    And I wait up to 40 seconds for the steps to pass:
    """
    When I run commands on the host:
      | iptables -S -t nat |
    Then the output should match:
      | KUBE-SERVICES -d <%= cb.service_ip %>/32 -p tcp -m comment --comment ".*/service-unsecure:http cluster IP" -m tcp --dport 27017 |
    """

  # @author bmeng@redhat.com
  # @case_id 529568
  @admin
  @destructive
  Scenario: Node cannot start when there is network plugin mismatch with master service
    Given I select a random node's host
    And the node service is verified
    And the node network is verified
    And the node service is restarted on the host after scenario
    And the "/etc/origin/node/node-config.yaml" file is restored on host after scenario
    And the network plugin is switched on the node
    When I run commands on the host:
      | systemctl restart atomic-openshift-node |
    Then the step should fail
    When I run commands on the host:
      | systemctl status atomic-openshift-node |
    Then the step should fail
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node -n 20 |
    Then the output should contain "detected network plugin mismatch"
    """

  # @author hongli@redhat.com
  # @case_id 536669
  @admin
  Scenario: Can get a hostsubnet for F5 from the cluster CIDR
    Given an 8 characters random string of type :dns952 is stored into the :hostsubnet_name clipboard
    And admin ensures "f5-<%= cb.hostsubnet_name %>" host_subnet is deleted after scenario
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/f5-hostsubnet.json" replacing paths:
       | ["metadata"]["name"] | f5-<%= cb.hostsubnet_name %> |
       | ["host"]             | f5-<%= cb.hostsubnet_name %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | hostsubnet                   |
      | resource_name | f5-<%= cb.hostsubnet_name %> |
      | o             | yaml                         |
    Then the step should succeed
    And the output should contain:
      | pod.network.openshift.io/fixed-vnid-host: "0" |
    And the output should not contain:
      | pod.network.openshift.io/assign-subnet |
    And evaluation of `@result[:parsed]['hostIP']` is stored in the :hostip clipboard
    And evaluation of `@result[:parsed]['subnet']` is stored in the :subnet clipboard

    Given I select a random node's host
    When I run commands on the host:
      | (ovs-ofctl dump-flows br0 -O openflow13  \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O openflow13) |
    Then the step should succeed
    And the output should contain:
      | arp_tpa=<%= cb.subnet %> actions=load:0->NXM_NX_TUN_ID[0..31],set_field:<%= cb.hostip %>->tun_dst,output:1 |
      | nw_dst=<%= cb.subnet %> actions=load:0->NXM_NX_TUN_ID[0..31],set_field:<%= cb.hostip %>->tun_dst,output:1  |

    # delete the hostsubnet
    When I run the :delete client command with:
      | object_type       | hostsubnet |
      | object_name_or_id | f5-<%= cb.hostsubnet_name %> |
    Then the step should succeed

    When I run commands on the host:
      | (ovs-ofctl dump-flows br0 -O openflow13  \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O openflow13) |
    Then the step should succeed
    And the output should not contain:
      | arp_tpa=<%= cb.subnet %> actions=load:0->NXM_NX_TUN_ID[0..31],set_field:<%= cb.hostip %>->tun_dst,output:1 |
      | nw_dst=<%= cb.subnet %> actions=load:0->NXM_NX_TUN_ID[0..31],set_field:<%= cb.hostip %>->tun_dst,output:1  |

  # @author bmeng@redhat.com
  # @case_id 483195
  @admin
  @destructive
  Scenario: The openshift master should handle the node subnet when the node added/removed
    Given environment has at least 2 nodes
    And I select a random node's host
    And the node labels are restored after scenario
    And the node network is verified
    And the node service is verified
    When I run the :get admin command with:
      | resource | hostsubnet |
    Then the step should succeed
    And the output should contain "<%= node.name %>"
    When I run the :delete admin command with:
      | object_type | node |
      | object_name_or_id | <%= node.name %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | hostsubnet |
    Then the step should succeed
    And the output should not contain "<%= node.name %>"
    Given the node service is restarted on the host
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
  # @case_id 515697
  @admin
  Scenario: ovs-port should be deleted after delete pods
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json |
    And the pod named "hello-pod" becomes ready
    And evaluation of `pod.container(user: user, name: 'hello-pod').id` is stored in the :container_id clipboard
    And evaluation of `pod("hello-pod").node_name(user: user)` is stored in the :pod_node clipboard
    Then I use the "<%= cb.pod_node %>" node
    When I run commands on the host:
      | docker inspect <%= cb.container_id %> \|grep Pid |
    Then the step should succeed
    And evaluation of `/"Pid":\s+(\d+)/.match(@result[:response])[1]` is stored in the :user_container_pid clipboard
    When I run commands on the host:
      | nsenter -n -t <%= cb.user_container_pid %> -- ethtool -S eth0 \| sed -n -e 's/.*peer_ifindex: //p' |
    Then the step should succeed
    And evaluation of `@result[:response].strip` is stored in the :ifindex clipboard
    When I run commands on the host:
      | ip a \| grep "<%= cb.ifindex %>:" \| awk -F@ '{ print $1 }' \| awk '{ print $2 }' |
    Then the output should contain "veth"
    And evaluation of `@result[:response].strip` is stored in the :veth_index clipboard
    When I run commands on the host:
      | (ovs-ofctl -O openflow13 show br0 \|\| docker exec openvswitch ovs-ofctl -O openflow13 show br0) |
    Then the output should contain "<%= cb.veth_index %>"
    When I run the :delete client command with:
      | object_type       | pods      |
      | object_name_or_id | hello-pod |
    Then the step should succeed
    Then I wait for the resource "pod" named "hello-pod" to disappear within 12 seconds
    When I run commands on the host:
      | ip a s <%= cb.veth_index %>: |
    Then the step should fail
    When I run commands on the host:
      | (ovs-ofctl -O openflow13 show br0 \|\| docker exec openvswitch ovs-ofctl -O openflow13 show br0) |
    Then the output should not contain "<%= cb.veth_index %>"
