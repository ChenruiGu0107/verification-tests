Feature: Pod related networking scenarios

  # @author bmeng@redhat.com
  # @case_id OCP-10016
  Scenario: The Completed/Failed pod should not run into TeardownNetworkError
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/completed-pod.json |
    Then the step should succeed
    And a pod is present with labels:
      | name=completed-pod |
    And evaluation of `pod.name` is stored in the :completed_pod clipboard
    Given the pod named "<%= cb.completed_pod %>" status becomes :succeeded
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/failed-pod.json |
    Then the step should succeed
    Given the pod named "fail-pod" status becomes :failed
    When I run the :describe client command with:
      | resource | pod |
      | name | <%= cb.completed_pod %> |
      | name | fail-pod |
    Then the step should succeed
    And the output should not contain "TeardownNetworkError"

  # @author bmeng@redhat.com
  # @case_id OCP-12675
  Scenario: containers can use vxlan as they want
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/udp4789-pod.json |
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

  # @author bmeng@redhat.com
  # @case_id OCP-10549
  @admin
  @destructive
  Scenario: The broadcast IP address should not be assigned to a pod
    Given I have a project
    And I have a pod-for-ping in the project
    Then evaluation of `pod.node_name` is stored in the :node_name clipboard

    # Get the node hostsubnet
    And evaluation of `host_subnet(cb.node_name).subnet` is stored in the :hostnetwork clipboard
    # Get the max available IP
    And evaluation of `IPAddr.new(cb.hostnetwork.chomp).to_range().max` is stored in the :broadcastip clipboard
    And evaluation of `IPAddr.new(cb.broadcastip).to_i - 1` is stored in the :maxipint clipboard
    And evaluation of `IPAddr.new(cb.maxipint, Socket::AF_INET).to_s` is stored in the :maxip clipboard
    # Write the max IP to the cni last reserved ip file
    When I run command on the "<%= cb.node_name %>" node's sdn pod:
      | bash | -c | printf "<%= cb.maxip %>" > $(find /var/lib/cni/networks/openshift-sdn/ -name "last_reserve*") |
    Then the step should succeed

    # Create a pod and make sure it will not use the broadcast ip
    Given I switch to the first user
    And I have a project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/pod_with_nodename.json" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.node_name%> |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/completed-pod.json |
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

  # @author bmeng@redhat.com
  # @case_id OCP-11578
  @admin
  @destructive
  Scenario: Other pod could work normally when a pod in high network io
    Given I have a project
    # setup iperf server to receive the traffic
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/qos/iperf-server.json |
    Then the step should succeed
    And the pod named "iperf-server" becomes ready
    And evaluation of `pod.ip` is stored in the :iperf_server clipboard

    # setup iperf client to send traffic to server with qos configured
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/qos/iperf-rc.json" replacing paths:
      | ["spec"]["replicas"] | 2 |
      | ["spec"]["template"]["metadata"]["annotations"]["kubernetes.io/ingress-bandwidth"] | 100M |
      | ["spec"]["template"]["metadata"]["annotations"]["kubernetes.io/egress-bandwidth"] | 100M |
    Then the step should succeed
    And 2 pods become ready with labels:
      | name=iperf-pods |
    And evaluation of `@pods[-1].name` is stored in the :iperf_client1 clipboard
    And evaluation of `@pods[-2].name` is stored in the :iperf_client2 clipboard

    # run two pods with both ingress and egress to increase the network io
    When I run the :exec background client command with:
      | pod              | <%= cb.iperf_client1 %> |
      | oc_opts_end      |                  |
      | exec_command     | iperf3           |
      | exec_command_arg | -c               |
      | exec_command_arg | <%= cb.iperf_server %>  |
      | exec_command_arg | -t               |
      | exec_command_arg | 600              |
    Then the step should succeed
    When I run the :exec background client command with:
      | pod              | <%= cb.iperf_client2 %> |
      | oc_opts_end      |                  |
      | exec_command     | iperf3           |
      | exec_command_arg | -c               |
      | exec_command_arg | <%= cb.iperf_server %>  |
      | exec_command_arg | -t               |
      | exec_command_arg | 600              |
      | exec_command_arg | -R               |
    Then the step should succeed

    # the other pod should work well with the high network io
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl | -kL | https://kubernetes.default.svc.cluster.local/ |
    Then the step should succeed
    And the output should contain "oapi"
    Given I run the steps 10 times:
    """
    When I execute on the pod:
      | time | curl | --connect-timeout | 2 | -Is | www.google.com |
    Then the step should succeed
    And the output should match "real.*0m 0\.\d{2}s"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-23774
  @admin
  Scenario: Non-host-network pod cannot be accessed the aws metadata
    Given I have a project
    And I have a pod-for-ping in the project
    When I execute on the pod:
      | curl | 169.254.169.254 |
    Then the output should contain "Connection refused"
    Given SCC "privileged" is added to the "system:serviceaccounts:<%= project.name %>" group
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/hostnetwork-pod.json |
    Then the step should succeed
    And the pod named "hostnetwork-pod" becomes ready
    When I execute on the pod:
      | curl | -I | 169.254.169.254 |
    Then the output should contain "200 OK"    
