Feature: Egress router related features
  # @author bmeng@redhat.com
  # @case_id OCP-11579
  @admin
  Scenario: Connection from pods on same node can be redirect to the target IP by egress router
    Given the cluster is running on OpenStack
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egress-ingress/egress-router/legacy-egress-router-list.json" replacing paths:
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-on-node.json" replacing paths:
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
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egress-ingress/egress-router/legacy-egress-router-list.json" replacing paths:
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-on-node.json" replacing paths:
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
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egress-ingress/egress-router/legacy-egress-router-list.json" replacing paths:
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
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router with init mode and single IP as destination
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egress-ingress/egress-router/egress-router-init-container.json" replacing paths:
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
    And I store a random unused IP address from the reserved range to the :valid_ip clipboard
    And the node's default gateway is stored in the clipboard
    And default router image is stored into the :router_image clipboard

    # Create egress router with init mode and port-protocol-ip as destination
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egress-ingress/egress-router/egress-router-init-container.json" replacing paths:
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
