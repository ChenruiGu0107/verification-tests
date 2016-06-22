Feature: SDN related networking scenarios
  # @author bmeng@redhat.com
  # @case_id 519348
  @admin
  @destructive
  Scenario: set MTU on vovsbr and vlinuxbr
    Given I select a random node's host
    And system verification steps are used:
    """
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O openflow13 \| grep "table=253" |
    Then the step should succeed
    And the output should contain "actions=note"
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
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    """
    And the "/etc/origin/node/node-config.yaml" file is restored on host after scenario
    When I run commands on the host:
      | sed -i 's/mtu:.*/mtu: 3450/g' /etc/origin/node/node-config.yaml |
    Then the step should succeed
    When I run commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
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
    And system verification steps are used:
    """
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O openflow13 \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O openflow13 |
    Then the step should succeed
    And the output should match "table=253.*actions=note"
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
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep common.go |
    Then the step should succeed
    And the output should contain "Failed to determine node address from hostname"
    And the output should contain "using default interface"
    When I run commands on the host:
      | systemctl status atomic-openshift-node |
    Then the output should contain "active (running)"


  # @author yadu@redhat.com
  # @case_id 517334
  @admin
  @destructive
  Scenario:  bridge-nf-call-iptables should be disable on node
    Given I select a random node's host
    And system verification steps are used:
    """
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O openflow13 \|\| docker exec openvswitch ovs-ofctl dump-flows br0 -O openflow13 |
    Then the step should succeed
    And the output should contain "actions=note"
    When I run commands on the host:
      | sysctl -a \| grep bridge.*iptables |
    Then the step should succeed
    Then the output should contain "net.bridge.bridge-nf-call-iptables = 0"
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
    And I run commands on the host: 
      | sysctl -a \| grep bridge.*iptables |
    Then the step should succeed
    Then the output should contain "net.bridge.bridge-nf-call-iptables = 0"
