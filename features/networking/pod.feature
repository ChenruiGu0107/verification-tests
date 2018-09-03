Feature: Pod related networking scenarios
  # @author bmeng@redhat.com
  # @case_id OCP-9747
  @admin
  Scenario: Pod cannot claim UDP port 4789 on the node as part of a port mapping
    Given I have a project
    And SCC "privileged" is added to the "system:serviceaccounts:<%= project.name %>" group
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod_with_udp_port_4789.json |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource      | pod   |
    Then the output should contain "address already in use"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-9802
  @admin
  Scenario: The user created docker container in openshift cluster should have outside network access
    Given I select a random node's host
    And I run commands on the host:
      | docker run -td --name=test-container bmeng/hello-openshift |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run commands on the host:
      | docker rm -f test-container |
    the step should succeed
    """
    When I run commands on the host:
      | docker exec test-container curl -sIL www.redhat.com |
    Then the step should succeed
    And the output should contain "HTTP/1.1 200 OK"

  # @author bmeng@redhat.com
  # @case_id OCP-10016
  Scenario: The Completed/Failed pod should not run into TeardownNetworkError
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/completed-pod.json |
    Then the step should succeed
    And a pod is present with labels:
      | name=completed-pod |
    And evaluation of `pod.name` is stored in the :completed_pod clipboard
    Given the pod named "<%= cb.completed_pod %>" status becomes :succeeded
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/failed-pod.json |
    Then the step should succeed
    Given the pod named "fail-pod" status becomes :failed
    When I run the :describe client command with:
      | resource | pod |
      | name | <%= cb.completed_pod %> |
      | name | fail-pod |
    Then the step should succeed
    And the output should not contain "TeardownNetworkError"

  # @author yadu@redhat.com
  # @case_id OCP-10031
  @smoke
  Scenario: Container could reach the dns server
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc528410/tc_528410_pod.json |
    And the pod named "hello-pod" becomes ready
    And I run the steps 20 times:
    """
    Given I execute on the pod:
      | getent | hosts | google.com |
    Then the step should succeed
    And the output should contain "google.com"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-12675
  Scenario: containers can use vxlan as they want
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/udp4789-pod.json |
    Then the step should succeed
    And the pod named "udp4789-pod" becomes ready
    And evaluation of `pod.ip` is stored in the :udp_pod clipboard
    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | bash |
      | -c |
      | (echo "Connection test to vxlan port") \| /usr/bin/ncat --udp <%= cb.udp_pod %> 4789 |
    Then the step should succeed
    When I run the :logs client command with:
      | resource_name | udp4789-pod |
    Then the step should succeed
    And the output should contain "Connection test to vxlan port"

  # @author yadu@redhat.com
  # @case_id OCP-14986
  @admin
  Scenario: The openflow list will be cleaned after delete the pods
    Given I have a project
    Given I have a pod-for-ping in the project
    Then I use the "<%= pod.node_name(user: user) %>" node
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    When I run ovs dump flows commands on the host
    Then the step should succeed
    And the output should contain:
      | <%=cb.pod_ip %> |
    When I run the :delete client command with:
      | object_type       | pod       |
      | object_name_or_id | hello-pod |
    Then the step should succeed
    Given I select a random node's host
    When I run ovs dump flows commands on the host
    Then the step should succeed
    And the output should not contain:
      | <%=cb.pod_ip %> |

  # @author hongli@redhat.com
  # @case_id OCP-15027
  Scenario: The pod MAC should be generated based on it's IP address
    Given I have a project
    And I have a pod-for-ping in the project
    And evaluation of `pod.ip` is stored in the :pod_ip clipboard
    When I execute on the pod:
      | bash |
      | -c   |
      | IP_ADDR=<%= cb.pod_ip %>; printf ':%02x' ${IP_ADDR//./ } |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :pod_mac clipboard
    When I execute on the pod:
      | bash |
      | -c   |
      | ip address show eth0 |
    Then the step should succeed
    And the output should contain:
      | link/ether 0a:58<%= cb.pod_mac %> |
      | inet <%= cb.pod_ip %> |

  # @author yadu@redhat.com
  # @case_id OCP-16729
  @admin
  @destructive
  Scenario: KUBE-HOSTPORTS chain rules won't be flushing when there is no pod with hostPort
    Given I have a project
    And SCC "privileged" is added to the "system:serviceaccounts:<%= project.name %>" group
    Given I store the schedulable nodes in the :nodes clipboard
    Given I select a random node's host
    # Add a fake rule
    Given I register clean-up steps:
    """
    When I run commands on the host:
      | iptables -t nat -D KUBE-HOSTPORTS -p tcp --dport 110 -j ACCEPT |
    """
    When I run commands on the host:
      | iptables -t nat -A KUBE-HOSTPORTS -p tcp --dport 110 -j ACCEPT |
    Then the step should succeed
    When I run commands on the host:
      | iptables-save \| grep HOSTPORT |
    Then the step should succeed
    And the output should contain:
      | -A PREROUTING -m comment --comment "kube hostport portals" -m addrtype --dst-type LOCAL -j KUBE-HOSTPORTS |
      | -A OUTPUT -m comment --comment "kube hostport portals" -m addrtype --dst-type LOCAL -j KUBE-HOSTPORTS     |
      | -A KUBE-HOSTPORTS -p tcp -m tcp --dport 110 -j ACCEPT |
    #Create a normal pod without hostport
    Given I switch to the first user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_nodename.json" replacing paths:
      | ["spec"]["nodeName"] | <%= node.name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=nodename-pod |
    Given 30 seconds have passed
    When I run commands on the host:
      | iptables-save \| grep HOSTPORT |
    Then the step should succeed
    #The rule won't be flushing when there is no pod with hostport
    And the output should contain:
      | -A PREROUTING -m comment --comment "kube hostport portals" -m addrtype --dst-type LOCAL -j KUBE-HOSTPORTS |
      | -A OUTPUT -m comment --comment "kube hostport portals" -m addrtype --dst-type LOCAL -j KUBE-HOSTPORTS     |
      | -A KUBE-HOSTPORTS -p tcp -m tcp --dport 110 -j ACCEPT |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/nodeport_pod.json" replacing paths:
      | ["spec"]["template"]["spec"]["nodeName"] | <%= node.name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=rc-test |
    When I run commands on the host:
      | iptables-save \| grep HOSTPORT |
    Then the step should succeed
    And the output should contain:
      | hostport 6061" -m tcp --dport 6061 |
    # The fake rule disappeared after creating a pod with hostport
    And the output should not contain:
      | -A KUBE-HOSTPORTS -p tcp --dport 110 -j ACCEPT |


  # @author bmeng@redhat.com
  # @case_id OCP-10549
  @admin
  @destructive
  Scenario: The broadcast IP address should not be assigned to a pod
    Given I select a random node's host
    And the node network is verified
    And the node service is verified

    # Get the node hostsubnet
    And evaluation of `host_subnet(node.name).subnet` is stored in the :hostnetwork clipboard
    # Get the max available IP
    And evaluation of `IPAddr.new("<%= cb.hostnetwork.chomp %>").to_range().max` is stored in the :broadcastip clipboard
    And evaluation of `IPAddr.new("<%= cb.broadcastip %>").to_i - 1` is stored in the :maxipint clipboard
    And evaluation of `IPAddr.new(<%= cb.maxipint %>, Socket::AF_INET).to_s` is stored in the :maxip clipboard
    # Write the max IP to the cni last reserved ip file
    When I run commands on the host:
      | printf "<%= cb.maxip %>" > $(find /var/lib/cni/networks/openshift-sdn/ -name "last_reserve*") |
    Then the step should succeed

    # Create a pod and make sure it will not use the broadcast ip
    Given I switch to the first user
    And I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_nodename.json" replacing paths:
      | ["spec"]["nodeName"] | <%= node.name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=nodename-pod |
    When I run the :get client command with:
      | resource      | pods |
      | o             | wide |
    Then the step should succeed
    And the output should not contain "<%= cb.broadcastip %>"


  # @author bmeng@redhat.com
  # @case_id OCP-19994
  Scenario: The completed pod should also have IP address
    Given I have a project
    And I run the steps 25 times:
    """
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/completed-pod.json |
    Then the step should succeed
    """
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pods |
      | l | name=completed-pod |
    Then the step should succeed
    And the output should contain 25 times:
      | Completed |
    """
    When I run the :get client command with:
      | resource | pods |
      | l | name=completed-pod |
      | template | {{range .items}}{{.status.podIP}}{{"\\n"}}{{end}} |
    Then the step should succeed
    And the output should match 25 times:
      | \d+\.\d+\.\d+\.\d+ |
