Feature: SDN related networking scenarios
  # @author bmeng@redhat.com
  # @case_id OCP-9844
  @admin
  @destructive
  Scenario: Configuring the Pod mtu in node config
    Given I store the schedulable nodes in the :nodes clipboard
    Given I use the "<%= cb.nodes[0].name %>" node
    And the node network is verified
    And system verification steps are used:
    """
    When I run commands on the host:
      | grep -i mtu /etc/origin/node/node-config.yaml \| sed 's/[^0-9]*//g' |
    Then the step should succeed
    And evaluation of `@result[:response].chomp` is stored in the :mtu clipboard
    Given the expression should be true> cb.mtu != "1234"
    When I run commands on the host:
      | ip link show tun0 |
    Then the expression should be true> @result[:response].include?(cb.mtu)
    """
    Given the node service is restarted on the host after scenario
    And I register clean-up steps:
    """
    When I run the ovs commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    """
    And the "/etc/origin/node/node-config.yaml" file is restored on host after scenario
    When I run commands on the host:
      | sed -i 's/mtu:.*/mtu: 1234/g' /etc/origin/node/node-config.yaml |
    Then the step should succeed
    When I run the ovs commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    When I run commands on the host:
      | systemctl restart atomic-openshift-node |
    Then the step should succeed
    # check mtu for tun0 and new create pod
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/aosqe-pod-for-ping.json" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.nodes[0].name %> |
    Then the step should succeed
    And the pod named "hello-pod" becomes ready
    When I execute on the pod:
      | bash | -c | ip addr |
    Then the output should contain "mtu 1234"
    When I run commands on the host:
      | ip link show tun0 |
    Then the output should contain "mtu 1234"

  # @author bmeng@redhat.com
  # @case_id OCP-10005
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
    When I run the ovs commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    """
    And the "/etc/hosts" file is restored on host after scenario
    When I run commands on the host:
      | echo "127.0.0.1  $(hostname)" >> /etc/hosts |
    Then the step should succeed
    When I run the ovs commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
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
  # @case_id OCP-9808
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
    When I run the ovs commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
    Then the step should succeed
    """
    When I run commands on the host:
      | systemctl stop atomic-openshift-node |
    Then the step should succeed
    When I run the ovs commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:01.ff" -O openflow13 |
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
  # @case_id OCP-11264
  @admin
  @destructive
  Scenario: SDN will be re-initialized when the version in openflow does not match the one in controller
    Given I select a random node's host
    And the node network is verified
    And the node service is verified
    When I run the ovs commands on the host:
      | ovs-ofctl dump-flows br0 -O openflow13 2>/dev/null \| grep table=253 \| sed -n -e 's/^.*note://p' \| cut -c 1,2 |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :plugin_type clipboard
    When I run the ovs commands on the host:
      | ovs-ofctl mod-flows br0 "table=253, actions=note:<%= cb.plugin_type.chomp %>.ff" -O openflow13 |
    Then the step should succeed
    When I run commands on the host:
      | systemctl restart atomic-openshift-node |
    Then the step should succeed
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep controller.go |
    Then the step should succeed
    And the output should contain "[SDN setup] full SDN setup required"

  # @author yadu@redhat.com
  # @case_id OCP-10025
  @admin
  @destructive
  Scenario: kubelet proxy could change to userspace mode
    Given the env is using one of the listed network plugins:
      | subnet      |
      | multitenant |
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
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "Using userspace Proxier" |
    Then the step should succeed

  # @author bmeng@redhat.com
  # @case_id OCP-11286
  @admin
  @destructive
  Scenario: iptables rules will be repaired automatically once it gets destroyed
    Given I select a random node's host
    And the node iptables config is verified
    And the node service is restarted on the host after scenario

    Given the node standard iptables rules are removed
    Given 35 seconds have passed
    Given the node iptables config is verified

  # @author bmeng@redhat.com
  # @case_id OCP-11592
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
      | iptables -S \| grep "4789.*incoming" \| cut -d ' ' -f 2- |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :vxlan_rule clipboard
    When I run commands on the host:
      | iptables -D <%= cb.vxlan_rule %> |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run commands on the host:
      | iptables -S -t filter |
    Then the output should contain:
      | <%= cb.vxlan_rule.chomp %> |
    """
    When I run commands on the host:
      | iptables -D <%= cb.vxlan_rule %> |
    Then the step should succeed
    And I wait up to 15 seconds for the steps to pass:
    """
    When I run commands on the host:
      | iptables -S -t filter |
    Then the output should contain:
      | <%= cb.vxlan_rule.chomp %> |
    """

  # @author bmeng@redhat.com
  # @case_id OCP-11795
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
  # @case_id OCP-11601
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
  # @case_id OCP-10997
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
    When I run ovs dump flows commands on the host
    Then the step should succeed
    And the output should contain:
      | arp_tpa=<%= cb.subnet %> actions=load:0->NXM_NX_TUN_ID[0..31],set_field:<%= cb.hostip %>->tun_dst,output:1 |
      | nw_dst=<%= cb.subnet %> actions=load:0->NXM_NX_TUN_ID[0..31],set_field:<%= cb.hostip %>->tun_dst,output:1  |

    # delete the hostsubnet
    When I run the :delete client command with:
      | object_type       | hostsubnet |
      | object_name_or_id | f5-<%= cb.hostsubnet_name %> |
    Then the step should succeed

    When I run ovs dump flows commands on the host
    Then the step should succeed
    And the output should not contain:
      | arp_tpa=<%= cb.subnet %> actions=load:0->NXM_NX_TUN_ID[0..31],set_field:<%= cb.hostip %>->tun_dst,output:1 |
      | nw_dst=<%= cb.subnet %> actions=load:0->NXM_NX_TUN_ID[0..31],set_field:<%= cb.hostip %>->tun_dst,output:1  |

  # @author bmeng@redhat.com
  # @case_id OCP-12549
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
  # @case_id OCP-9753
  @admin
  Scenario: ovs-port should be deleted after delete pods
    Given I have a project
    And I have a pod-for-ping in the project
    Then I use the "<%= pod.node_name(user: user) %>" node
    And evaluation of `pod.container(user: user, name: 'hello-pod').id` is stored in the :container_id clipboard
    When I run commands on the host:
      | docker inspect <%= cb.container_id %> \|grep Pid |
    Then the step should succeed
    And evaluation of `/"Pid":\s+(\d+)/.match(@result[:response])[1]` is stored in the :user_container_pid clipboard
    When I run commands on the host:
      | nsenter -n -t <%= cb.user_container_pid %> -- ethtool -S eth0 \| sed -n -e 's/.*peer_ifindex: //p' |
    Then the step should succeed
    And evaluation of `@result[:response].strip` is stored in the :ifindex clipboard
    When I run commands on the host:
      | ip addr show if<%= cb.ifindex %> \| head -1 \| awk -F@ '{ print $1 }' \| awk '{ print $2 }' |
    Then the output should contain "veth"
    And evaluation of `@result[:response].strip` is stored in the :veth_index clipboard
    When I run the ovs commands on the host:
      | ovs-ofctl -O openflow13 show br0 |
    Then the output should contain "<%= cb.veth_index %>"
    When I run the :delete client command with:
      | object_type       | pods      |
      | object_name_or_id | hello-pod |
    Then the step should succeed
    Then I wait for the resource "pod" named "hello-pod" to disappear within 12 seconds
    When I run commands on the host:
      | ip a s <%= cb.veth_index %>: |
    Then the step should fail
    When I run the ovs commands on the host:
      | ovs-ofctl -O openflow13 show br0 |
    Then the output should not contain "<%= cb.veth_index %>"

  # @author zzhao@redhat.com
  # @case_id OCP-9969
  @admin
  @destructive
  Scenario: The pod veth ports can be recovered when openvswitch restart
    Given I have a project
    And I have a pod-for-ping in the project
    Then I use the "<%= pod.node_name(user: user) %>" node
    When I run commands on the host:
      | systemctl restart openvswitch |
    Then the step should succeed
    #check the pod can access external network
    And I wait up to 300 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | curl -sS -w %{http_code} http://www.youdao.com -o /dev/null |
    Then the step should succeed
    And the output should contain "200"
    """

  # @author yadu@redhat.com
  # @case_id OCP-9934
  @admin
  @destructive
  Scenario: Restart master service could fix the invalid ip in hostip
    Given I select a random node's host
    Given host subnet "<%= node.name %>" is restored after scenario
    Given I switch to cluster admin pseudo user
    When I run the :get client command with:
      | resource      | hostsubnet       |
      | resource_name | <%= node.name %> |
      | o             | yaml             |
    Then the step should succeed
    And evaluation of `@result[:parsed]['hostIP']` is stored in the :hostip clipboard
    And I save the output to file>hostsubnet.yaml
    And I replace lines in "hostsubnet.yaml":
      | hostIP: <%= cb.hostip %> | hostIP: 8.8.8.8 |
    When I run the :replace client command with:
      | f | hostsubnet.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | hostsubnet       |
      | resource_name | <%= node.name %> |
    Then the step should succeed
    And the output should contain "8.8.8.8"
    And the master service is restarted on all master nodes
    When I run the :get client command with:
      | resource      | hostsubnet       |
      | resource_name | <%= node.name %> |
    Then the step should succeed
    And the output should not contain "8.8.8.8"
    And the output should contain:
      | <%= cb.hostip %> |

  # @author yadu@redhat.com
  # @case_id OCP-9754
  @admin
  @destructive
  Scenario: Master can be started normally when unset serviceNetworkCIDR
    Given master config is merged with the following hash:
    """
    networkConfig:
      serviceNetworkCIDR: null
    """
    Then the step should succeed
    And the master service is restarted on all master nodes


  # @author bmeng@redhat.com
  # @case_id OCP-10538
  @admin
  @destructive
  Scenario: IPAM garbage collection to release the un-used IPs on node
    Given I select a random node's host
    And the node service is verified
    And the node network is verified
    # Get the node hostsubnet
    When I run commands on the host:
      | ip -4 addr show tun0 \| grep -Eo '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}\/[0-9]{1,2}' |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :hostnetwork clipboard
    # Get the broadcast ip of the subnet
    When I run commands on the host:
      | ipcalc -b <%= cb.hostnetwork.chomp %> \| grep -Eo "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :broadcastip clipboard
    Given an 64 character random string of type :num is stored into the :cni_id clipboard
    # Fill up the IPAM to trigger the garbage collection later
    When I run commands on the host:
      | docker pull uzyexe/nmap |
    Then the step should succeed
    When I run commands on the host:
      | for i in `docker run --rm uzyexe/nmap -sL <%= cb.hostnetwork.chomp %> \| grep "Nmap scan" \| grep -Eo '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}'` ; do printf <%= cb.cni_id %> > /tmp/$i ; mv -n /tmp/$i /var/lib/cni/networks/openshift-sdn/ ; done |
    Then the step should succeed
    # Leave the broadcast IP available to test OCP-10549
    When I run commands on the host:
      | rm -f /var/lib/cni/networks/openshift-sdn/<%= cb.broadcastip %> |
    Then the step should succeed
    # Create one more pod on the node which is running out of IP
    Given I switch to the first user
    And I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_nodename.json" replacing paths:
      | ["spec"]["nodeName"] | <%= node.name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=nodename-pod |
    # Check the pod will not get broadcast ip assigned
    When I run the :get client command with:
      | resource      | pods |
      | o             | wide |
    Then the step should succeed
    And the output should not contain "<%= cb.broadcastip %>"
    # Check the GC was triggered
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node \| grep pod_linux.go |
    Then the step should succeed
    And the output should contain "Starting IP garbage collection"
    And the output should match "Releasing IP.*allocated to"
    When I run commands on the host:
      | ls /var/lib/cni/networks/openshift-sdn \| wc -l |
    Then the step should succeed
    And the expression should be true> @result[:response].to_i < 41

  # @author hongli@redhat.com
  # @case_id OCP-13847
  @admin
  Scenario: an empty OPENSHIFT-ADMIN-OUTPUT-RULES chain is created in filter table at startup
    Given the master version >= "3.6"
    Given I select a random node's host
    And the node service is verified

    When I run commands on the host:
      | iptables -S -t filter \| grep 'OPENSHIFT-ADMIN-OUTPUT-RULES' |
    Then the step should succeed
    And the output should contain:
      | -N OPENSHIFT-ADMIN-OUTPUT-RULES |
      | -A FORWARD -i tun0 ! -o tun0 -m comment --comment "administrator overrides" -j OPENSHIFT-ADMIN-OUTPUT-RULES |

  # @author hongli@redhat.com
  # @case_id OCP-14271
  @admin
  @destructive
  Scenario: add rule to OPENSHIFT-ADMIN-OUTPUT-RULES chain
    Given the master version >= "3.6"
    Given I have a project
    # create target pod and services for ping or curl
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
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
    Given the env is using multitenant network
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egressnetworkpolicy/internal-policy.json |
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
    And I store the schedulable nodes in the clipboard

    # Delete the nodes[0]
    Given I use the "<%= cb.nodes[0].name %>" node
    And the node service is verified
    And the node network is verified
    And the node service is restarted on the host after scenario
    When I run the :delete admin command with:
      | object_type       | node                    |
      | object_name_or_id | <%= cb.nodes[0].name %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | hostsubnet |
    Then the step should succeed
    And the output should not contain "<%= cb.nodes[0].name %>"

    # Check if nodes are reachable from a pod
    Given host subnets are stored in the clipboard
    And evaluation of `IPAddr.new(host_subnet.subnet).succ` is stored in the :nodeA_ip clipboard
    And evaluation of `IPAddr.new(host_subnet(-2).subnet).succ` is stored in the :nodeB_ip clipboard

    And I have a project
    And I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | -c | ping -c 2 <%= cb.nodeA_ip %> |
    Then the step should succeed
    When I execute on the pod:
      | bash | -c | ping -c 2 <%= cb.nodeB_ip %> |
    Then the step should succeed

    # Check if connections between nodes are reachable
    Given I use the "<%= cb.nodes[1].name %>" node
    When I run commands on the host:
      | ping -c 2 <%= cb.nodeA_ip %> |
    Then the step should succeed
    When I run commands on the host:
      | ping -c 2 <%= cb.nodeB_ip %> |
    Then the step should succeed

  # @author bmeng@redhat.com
  # @case_id OCP-16217
  @admin
  @destructive
  Scenario: SDN will detect the version and plugin type mismatch in openflow and restart node automatically
    Given the master version >= "3.7"
    And I select a random node's host
    Given the cluster network plugin type and version and stored in the clipboard
    And system verification steps are used:
    """
    When I run ovs dump flows commands on the host
    Then the step should succeed
    Then the output should contain "<%= cb.net_plugin[:type] %>.<%= cb.net_plugin[:version] %>"
    """
    And the node service is verified
    And the node network is verified

    When I run the ovs commands on the host:
      | ovs-ofctl -O openflow13 mod-flows br0 "table=253, actions=note:<%= cb.net_plugin[:type] %>.ff" |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "30s ago" \| grep SDN |
    Then the step should succeed
    And the output should contain:
      | SDN healthcheck detected unhealthy OVS server |
      | full SDN setup required |
    """

    When I run the ovs commands on the host:
      | ovs-ofctl -O openflow13 mod-flows br0 "table=253, actions=note:99.<%= cb.net_plugin[:version] %>" |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "30s ago" \| grep SDN |
    Then the step should succeed
    And the output should contain:
      | SDN healthcheck detected unhealthy OVS server |
      | full SDN setup required |
    """

  # @author yadu@redhat.com
  # @case_id OCP-15251
  @admin
  @destructive
  Scenario: net.ipv4.ip_forward should be always enabled on node service startup
    Given I select a random node's host
    And the node service is verified
    And the node network is verified
    And system verification steps are used:
    """
    When I run commands on the host:
      | sysctl net.ipv4.ip_forward |
    Then the step should succeed
    And the output should contain "net.ipv4.ip_forward = 1"
    """
    Given the node service is restarted on the host after scenario
    And I register clean-up steps:
    """
    When I run commands on the host:
      | sysctl -w net.ipv4.ip_forward=1 |
    Then the step should succeed
    """
    When I run commands on the host:
      | sysctl -w net.ipv4.ip_forward=0 |
    Then the step should succeed
    When I run commands on the host:
      | systemctl restart atomic-openshift-node |
    Then the step should fail
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "2 min ago" \| grep network.go |
    Then the step should succeed
    And the output should contain "net/ipv4/ip_forward=0, it must be set to 1"
    """

  # @author hongli@redhat.com
  # @case_id OCP-14985
  @admin
  @destructive
  Scenario: The openflow list will be cleaned after deleted the node
    Given environment has at least 2 nodes
    And I store the nodes in the :nodes clipboard

    # get node_1's host IP and save to clipboard
    Given I use the "<%= cb.nodes[1].name %>" node
    And the node service is restarted on the host after scenario
    And evaluation of `host_subnet(cb.nodes[1].name).ip` is stored in the :hostip clipboard

    # check ovs rule in node_0
    Given I use the "<%= cb.nodes[0].name %>" node
    When I run the ovs commands on the host:
      | ovs-ofctl dump-flows br0 -O openflow13 2>/dev/null \| grep <%= cb.hostip %> |
    Then the step should succeed
    And the output should match:
      | table=10,.*tun_src=<%= cb.hostip %> actions=goto_table:30 |
      | table=50,.*arp,.*set_field:<%= cb.hostip %>->tun_dst |
      | table=90,.*ip,.*set_field:<%= cb.hostip %>->tun_dst |
      | table=111,.*set_field:<%= cb.hostip %>->tun_dst,.*goto_table:120 |

    # delete the node_1
    When I run the :delete admin command with:
      | object_type       | node                    |
      | object_name_or_id | <%= cb.nodes[1].name %> |
    Then the step should succeed

    # again, check ovs rule in node_0
    When I run the ovs commands on the host:
      | ovs-ofctl dump-flows br0 -O openflow13 2>/dev/null |
    Then the step should succeed
    And the output should not contain "<%= cb.hostip %>"
