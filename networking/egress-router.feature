Feature: Egress router related features
  # @author bmeng@redhat.com
  # @case_id OCP-11579
  @admin
  Scenario: Connection from pods on same node can be redirect to the target IP by egress router
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router
    # IP 10.4.205.4 points to the redhat internal service bugzilla.redhat.com
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/legacy-egress-router-list.json" replacing paths:
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][2]["value"] | 10.4.205.4 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.ip` is stored in the :egress_router_ip clipboard
    Then evaluation of `pod.node_name` is stored in the :egress_router_node clipboard
    Given I use the "egress-svc" service
    And evaluation of `service.ip(user: user)` is stored in the :egress_router_svc clipboard

    # Create a pod on the same node with egress router above
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/pod-on-node.json" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.egress_router_node %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=hello-pod |

    # Access the egress router and it will be redirected to the destination
    When I execute on the pod:
      | curl | --connect-timeout | 5 | -sILk | <%= cb.egress_router_ip %> |
    Then the step should succeed
    And the output should contain "Bugzilla"
    When I execute on the pod:
      | curl | --connect-timeout | 5 | -sILk | -H | host: bugzilla.redhat.com | <%= cb.egress_router_svc %>:80 |
    Then the step should succeed
    And the output should contain "Bugzilla"

  # @author bmeng@redhat.com
  # @case_id OCP-11786
  @admin
  Scenario: The egress router can be reallocated to another node and continue work if the current node goes down
    Given the cluster is running on OpenStack
    And environment has at least 2 schedulable nodes
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router
    # IP 10.4.205.4 points to the redhat internal service bugzilla.redhat.com
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/legacy-egress-router-list.json" replacing paths:
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][2]["value"] | 10.4.205.4 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.ip` is stored in the :egress_router_ip clipboard
    Then evaluation of `pod.node_name` is stored in the :egress_router_node clipboard

    # Create a pod on the same node with egress router above
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/pod-on-node.json" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.egress_router_node %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=hello-pod |
    And evaluation of `pod.name` is stored in the :worker_pod clipboard

    # Access the egress router and it will be redirected to the destination
    When I execute on the pod:
      | curl | --connect-timeout | 5 | -sSILk | <%= cb.egress_router_ip %> |
    Then the step should succeed
    And the output should contain "Bugzilla"

    # delete the existing egress router pod and make sure it lands on the different node
    Given I wait up to 120 seconds for the steps to pass:
    """
    Given I run the :scale client command with:
      | resource | replicationcontrollers |
      | name | egress-rc |
      | replicas | 0 |
    And 0 pods become ready with labels:
      | name=egress-router |
    Given I run the :scale client command with:
      | resource | replicationcontrollers |
      | name | egress-rc |
      | replicas | 1 |
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.node_name` is stored in the :new_node clipboard
    And evaluation of `pod.ip` is stored in the :new_ip clipboard
    And the expression should be true> "<%= cb.new_node %>" != "<%= cb.egress_router_node %>"
    """

    # Access the egress router and it will be redirected to the destination
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.worker_pod %>" pod:
      | curl | --connect-timeout | 5 | -sSILk | <%= cb.new_ip %> |
    Then the step should succeed
    And the output should contain "Bugzilla"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-10824
  @admin
  Scenario: Cannot connect to the opening ports on the node where the egress router is running via the EGRESS_SOURCE
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router
    # IP 10.4.205.4 points to the redhat internal service bugzilla.redhat.com
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/legacy-egress-router-list.json" replacing paths:
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][2]["value"] | 10.4.205.4 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.ip` is stored in the :egress_router_ip clipboard
    And evaluation of `pod.node_name` is stored in the :egress_router_node clipboard
    And evaluation of `pod.node_ip` is stored in the :egress_router_nodeip clipboard

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | ncat | -z | <%= cb.egress_router_nodeip %> | 22 |
    Then the step should succeed
    When I execute on the pod:
      | ncat | -z | <%= cb.valid_ip %> | 22 |
    Then the step should fail

  # @author bmeng@redhat.com
  # @case_id OCP-14107
  @admin
  Scenario: InitConatainer egress router works with single IP destination
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router with init mode and single IP as destination
    # IP 10.4.205.4 points to the redhat internal service bugzilla.redhat.com
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/egress-router-init-container.json" replacing paths:
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][2]["value"] | 10.4.205.4 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.ip` is stored in the :egress_router_ip clipboard
    Given I use the "egress-svc" service
    And evaluation of `service.ip(user: user)` is stored in the :egress_router_svc clipboard

    # Try to access the egress router pod and svc, it should be redirected to the destination
    Given I have a pod-for-ping in the project
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | --connect-timeout | 5 | -sILk | <%= cb.egress_router_ip %> |
    Then the step should succeed
    And the output should contain "Bugzilla"
    When I execute on the pod:
      | curl | --connect-timeout | 5 | -sILk | -H | host: bugzilla.redhat.com | <%= cb.egress_router_svc %>:80 |
    Then the step should succeed
    And the output should contain "Bugzilla"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-14109
  @admin
  Scenario: InitConatainer egress router works with port-protocol-destip format destination
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router with init mode and port-protocol-ip as destination
    # IP 10.4.205.4 points to the redhat internal service bugzilla.redhat.com
    # IP 8.8.8.8 points to the public dns server provided by Google
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/egress-router-init-container.json" replacing paths:
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][2]["value"] | "443 tcp 10.4.205.4\\n53 udp 8.8.8.8" |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.ip` is stored in the :egress_router_ip clipboard

    # Test only the configured destination can be reached with port and protocol
    Given I have a pod-for-ping in the project
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -ksISL | --connect-timeout | 5 | https://<%= cb.egress_router_ip %>:443 |
    Then the step should succeed
    And the output should contain "Bugzilla"
    When I execute on the pod:
      | curl | -ksISL | --connect-timeout | 5 | http://<%= cb.egress_router_ip %>:80 |
    Then the step should fail
    And the output should not contain "Bugzilla"
    When I execute on the pod:
      | ncat | -uz | <%= cb.egress_router_ip %> | 53 |
    Then the step should succeed
    When I execute on the pod:
      | ncat | -z | <%= cb.egress_router_ip %> | 53 |
    Then the step should fail
    """

  # @author bmeng@redhat.com
  # @case_id OCP-14111
  @admin
  Scenario: InitConatainer egress router works with port-protocol-destip-destport format destination
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router with init mode and port-protocol-destip-destport as destination
    # IP 10.4.205.4 points to the redhat internal service bugzilla.redhat.com
    # IP 8.8.8.8 points to the public dns server provided by Google
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/egress-router-init-container.json" replacing paths:
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][2]["value"] | "8443 tcp 10.4.205.4 443\\n5353 udp 8.8.8.8 53" |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.ip` is stored in the :egress_router_ip clipboard

    # Test only the configured destination can be reached with port and protocol
    Given I have a pod-for-ping in the project
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -ksISL | --connect-timeout | 5 | https://<%= cb.egress_router_ip %>:8443 |
    Then the step should succeed
    And the output should contain "Bugzilla"
    When I execute on the pod:
      | curl | -ksISL | --connect-timeout | 5 | <%= cb.egress_router_ip %> |
    Then the step should fail
    And the output should not contain "Bugzilla"
    When I execute on the pod:
      | ncat | -uz | <%= cb.egress_router_ip %> | 5353 |
    Then the step should succeed
    When I execute on the pod:
      | ncat | -uz | <%= cb.egress_router_ip %> | 53 |
    Then the step should fail
    """

  # @author bmeng@redhat.com
  # @case_id OCP-14112
  @admin
  Scenario: It will fallback to the IP in the last line if the connection does not match any port and proto
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router with init mode and has fallback IP in destination
    # IP 10.4.205.4 points to the redhat internal service bugzilla.redhat.com
    # IP 5.196.70.86 to the external web services portquiz.net which serves on all the TCP ports
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/egress-router-init-container.json" replacing paths:
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][2]["value"] | "443 tcp 10.4.205.4\\n5.196.70.86" |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.ip` is stored in the :egress_router_ip clipboard

    # Test the connection will be redirect to the fallback IP if there is no port and procotol matched in the previous rules
    Given I have a pod-for-ping in the project
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -ksISL | --connect-timeout | 5 | https://<%= cb.egress_router_ip %>/ |
    Then the step should succeed
    And the output should contain "Bugzilla"
    When I execute on the pod:
      | curl | -skSL | --connect-timeout | 5 | -H | host: portquiz.net:9999 |  <%= cb.egress_router_ip %>:9999 |
    Then the step should succeed
    And the output should contain "Port 9999 test successful"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-14472
  @admin
  Scenario: Using a ConfigMap to specify EGRESS_DESTINATION
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create configmap for egress router
    # IP 10.4.205.4 points to the redhat internal service bugzilla.redhat.com
    # IP 5.196.70.86 to the external web services portquiz.net which serves on all the TCP ports
    # IP 8.8.8.8 points to the public dns server provided by Google
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    And a "egress-routes.txt" file is created with the following lines:
    """
    # Redirect connection for udp port 53 to destination
    53 udp 8.8.8.8

    # Redirect connection for tcp port 8443 to detination IP with port 443
    8443 tcp 10.4.205.4 443

    # Fallback IP
    5.196.70.86
    """
    When I run the :create_configmap client command with:
      | name      | egress-routes |
      | from_file | destination=egress-routes.txt |
    Then the step should succeed

    # Create egress router which points to the configmap above
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/egress-router-configmap.json" replacing paths:
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][1]["value"] | <%= cb.gateway %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.ip` is stored in the :egress_router_ip clipboard

    # Test the connection will follow the rules defined in configmap
    Given I have a pod-for-ping in the project
    And I wait up to 90 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -ksISL | --connect-timeout | 5 | https://<%= cb.egress_router_ip %>:8443 |
    Then the step should succeed
    And the output should contain "Bugzilla"
    When I execute on the pod:
      | ncat | -uz | <%= cb.egress_router_ip %> | 53 |
    Then the step should succeed
    When I execute on the pod:
      | curl | -skSL | --connect-timeout | 5 | -H | host: portquiz.net:9999 |  <%= cb.egress_router_ip %>:9999 |
    Then the step should succeed
    And the output should contain "Port 9999 test successful"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-14419
  @admin
  Scenario: Deploy multiple egress-router on a single node
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router
    # IP 10.4.205.4 points to the redhat internal service bugzilla.redhat.com
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/egress-router-init-container.json" replacing paths:
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][2]["value"] | 10.4.205.4 |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][3]["value"] | init |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.ip` is stored in the :egress_router1_ip clipboard
    Then evaluation of `pod.node_name` is stored in the :egress_router1_node clipboard

    # Create 2nd egress router on the same node
    # IP 5.196.70.86 to the external web services portquiz.net which serves on all the TCP ports
    Given I store a random unused IP address from the reserved range to the :valid_ip2 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/legacy-egress-router-list.json" replacing paths:
      | ["items"][0]["metadata"]["labels"]["name"] | egress-rc-2 |
      | ["items"][0]["metadata"]["name"] | egress-rc-2 |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][0]["value"] | <%= cb.valid_ip2 %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["env"][2]["value"] | 5.196.70.86 |
      | ["items"][0]["spec"]["template"]["spec"]["containers"][0]["name"] | egress-router-2 |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | egress-router-2 |
      | ["items"][0]["spec"]["template"]["spec"]["nodeName"] | <%= cb.egress_router1_node %> |
      | ["items"][1]["metadata"]["name"] | egress-svc-2 |
      | ["items"][1]["spec"]["selector"]["name"] | egress-router-2 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router-2 |
    Then evaluation of `pod.ip` is stored in the :egress_router2_ip clipboard

    Given I have a pod-for-ping in the project
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -ksISL | --connect-timeout | 5 | <%= cb.egress_router1_ip %> |
    Then the step should succeed
    And the output should contain "Bugzilla"
    When I execute on the pod:
      | curl | -skSL | --connect-timeout | 5 | -H | host: portquiz.net |  <%= cb.egress_router2_ip %> |
    Then the step should succeed
    And the output should contain "Port 80 test successful"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-18509
  @admin
  Scenario: Support the subnet length to be set in the EGRESS_SOURCE
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router with init mode and dest ip
    # IP 10.4.205.4 points to the internal web service bugzilla.redhat.com
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/egress-router-init-container.json" replacing paths:
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][0]["value"] | <%= cb.valid_ip %>/23 |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["items"][0]["spec"]["template"]["spec"]["initContainers"][0]["env"][2]["value"] | 10.4.205.4 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-router |
    Then evaluation of `pod.ip` is stored in the :egress_router_ip clipboard

    # Access the egress router and it should work fine
    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -IskSL | --connect-timeout | 5 | <%= cb.egress_router_ip %> |
    Then the step should succeed
    And the output should contain "Bugzilla"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-13777
  @admin
  Scenario: Check http access when egress-router service used in env http_proxy
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress http proxy which works for www.youdao.com only
    Given I have a project
    And evaluation of `project.name` is stored in the :project clipboard
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/egress-http-proxy.yaml" replacing paths:
      | ["spec"]["initContainers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["spec"]["initContainers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["spec"]["initContainers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["spec"]["initContainers"][0]["env"][2]["value"] | http-proxy |
      | ["spec"]["containers"][0]["image"] | <%= cb.router_image.gsub("haproxy-router","egress-http-proxy") %> |
      | ["spec"]["containers"][0]["env"][0]["value"] | "www.youdao.com" |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-http-proxy |
    Then evaluation of `pod.ip` is stored in the :egress_http_proxy_ip clipboard

    # expose the service for the egress http proxy pod
    When I run the :expose client command with:
      | resource       | pod          |
      | resource_name  | egress-http-proxy      |
      | port           | 8080         |
      | protocol       | TCP          |
    Then the step should succeed

    # access the remote http service with the egress http proxy
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl | -IsS | --proxy | <%= cb.egress_http_proxy_ip %>:8080 | --connect-timeout | 5 | http://www.youdao.com/ |
    Then the step should succeed
    And the output should contain "200 OK"
    When I execute on the pod:
      | curl | -IsS | --proxy | egress-http-proxy.<%= cb.project %>.svc:8080 | --connect-timeout | 5 | http://www.youdao.com/ |
    Then the step should succeed
    And the output should contain "200 OK"
    When I execute on the pod:
      | curl | -IsS | --proxy | egress-http-proxy.<%= cb.project %>.svc:8080 | --connect-timeout | 5 | http://portquiz.net/ |
    Then the output should contain "403 Forbidden"
    When I execute on the pod:
      | curl | -IsS | --proxy | <%= cb.egress_http_proxy_ip %>:8080 | --connect-timeout | 5 | http://www.baidu.com/ |
    Then the output should contain "403 Forbidden"

  # @author bmeng@redhat.com
  # @case_id OCP-13779
  @admin
  Scenario: Check https access when egress-router service used in env http_proxy
    Given the cluster is running on OpenStack
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress http proxy works for subnet 10.4.0.0/16 which holding the bugzilla.redhat.com
    Given I have a project
    And evaluation of `project.name` is stored in the :project clipboard
    And SCC "privileged" is added to the "default" service account
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/egress-http-proxy.yaml" replacing paths:
      | ["spec"]["initContainers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["spec"]["initContainers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["spec"]["initContainers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["spec"]["initContainers"][0]["env"][2]["value"] | http-proxy |
      | ["spec"]["containers"][0]["image"] | <%= cb.router_image.gsub("haproxy-router","egress-http-proxy") %> |
      | ["spec"]["containers"][0]["env"][0]["value"] | "10.4.0.0/16" |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-http-proxy |
    Then evaluation of `pod.ip` is stored in the :egress_http_proxy_ip clipboard

    # expose the service for the egress http proxy pod
    When I run the :expose client command with:
      | resource       | pod          |
      | resource_name  | egress-http-proxy      |
      | port           | 8080         |
      | protocol       | TCP          |
    Then the step should succeed

    # access the remote https service with the egress http proxy
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl | -Isk | --proxy | <%= cb.egress_http_proxy_ip %>:8080 | --connect-timeout | 5 | https://bugzilla.redhat.com/ |
    Then the step should succeed
    And the output should contain "200"
    When I execute on the pod:
      | curl | -Isk | --proxy | <%= cb.egress_http_proxy_ip %>:8080 | --connect-timeout | 5 | https://www.google.com/ |
    Then the output should contain "403 Forbidden"
    When I execute on the pod:
      | curl | -Isk | --proxy | egress-http-proxy.<%= cb.project %>.svc:8080 | --connect-timeout | 5 | https://bugzilla.redhat.com/ |
    Then the step should succeed
    And the output should contain "200"
    When I execute on the pod:
      | curl | -Isk | --proxy | egress-http-proxy.<%= cb.project %>.svc:8080 | --connect-timeout | 5 | https://www.amazon.com/ |
    Then the output should contain "403 Forbidden"

  # @author bmeng@redhat.com
  # @case_id OCP-13781
  @admin
  Scenario: Deny rules in EgressNetworkPolicy will not effect the traffic through egress-router
    Given the cluster is running on OpenStack
    And the env is using multitenant or networkpolicy network
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress network policy in the project
    Given I have a project
    And evaluation of `project.name` is stored in the :project clipboard
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run oc create as admin over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/dns-egresspolicy1.json" replacing paths:
      | ["spec"]["egress"][0]["type"] | Deny |
      | ["spec"]["egress"][0]["to"]["dnsName"] | bugzilla.redhat.com |
      | ["metadata"]["namespace"] | <%= cb.project %> |
    Then the step should succeed

    # access the remote service directly should fail
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl | -Isk | --connect-timeout | 5 | https://bugzilla.redhat.com/ |
    Then the step should fail
    And the output should not contain "200 OK"
    And the output should not contain "Bugzilla"

    # Create the egress http proxy to point to the denied network
    Given SCC "privileged" is added to the "default" service account
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/egress-ingress/egress-router/egress-http-proxy.yaml" replacing paths:
      | ["spec"]["initContainers"][0]["image"] | <%= cb.router_image.gsub("haproxy","egress") %> |
      | ["spec"]["initContainers"][0]["env"][0]["value"] | <%= cb.valid_ip %> |
      | ["spec"]["initContainers"][0]["env"][1]["value"] | <%= cb.gateway %> |
      | ["spec"]["initContainers"][0]["env"][2]["value"] | http-proxy |
      | ["spec"]["containers"][0]["image"] | <%= cb.router_image.gsub("haproxy-router","egress-http-proxy") %> |
      | ["spec"]["containers"][0]["env"][0]["value"] | 10.4.205.4 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=egress-http-proxy |
    Then evaluation of `pod.ip` is stored in the :egress_http_proxy_ip clipboard

    # access the remote service with the egress http proxy should succeed
    When I execute on the "hello-pod" pod:
      | curl | -Isk | --proxy | <%= cb.egress_http_proxy_ip %>:8080 | --connect-timeout | 5 | https://bugzilla.redhat.com/ |
    Then the step should succeed
    And the output should contain "200 OK"
    And the output should contain "Bugzilla"

