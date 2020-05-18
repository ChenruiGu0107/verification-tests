Feature: Egress router related features
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
