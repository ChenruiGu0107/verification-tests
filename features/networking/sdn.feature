Feature: SDN related networking scenarios
  # @author bmeng@redhat.com
  # @case_id 519348
  @admin
  @destructive
  Scenario: set MTU on vovsbr and vlinuxbr
    Given I select a random node's host
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O openflow13 \| grep "table=253" |
    Then the step should succeed
    And the output should contain "actions=note"
    When I run commands on the host:
      | grep -i mtu /etc/origin/node/node-config.yaml \| sed 's/[^0-9]*//g' \| tr -d '\n' |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :mtu clipboard
    When I run commands on the host:
      | ip link show lbr0 |
    Then the output should contain "<%= cb.mtu %>"
    When I run commands on the host:
      | ovs-ofctl dump-flows br0 -O openflow13 \| grep "table=253" |
    Then the step should succeed
    And the output should contain "actions=note"
    Given the node service is restarted on the host after scenario
    And the "/etc/origin/node/node-config.yaml" file is restored on host after scenario
    Given I register clean-up steps:
    """
    I run commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    the step should succeed
    """
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
