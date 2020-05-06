Feature: Testing IPv6 related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-13840
  @admin
  @destructive
  Scenario: The haproxy support terminate IPv6 traffic at the router if set ROUTER_IP_V4_V6_MODE to v4v6	
    Given the master version >= "3.6"
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_IP_V4_V6_MODE=v4v6 |
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    And evaluation of `pod.node_name` is stored in the :node clipboard

    Given I switch to the first user
    And I have a project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/routing/list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=caddy-pods |

    # create unsecure and reencrypt route
    When I expose the "service-unsecure" service
    Then the step should succeed

    Given I obtain test data file "routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | reen-route              |
      | service    | service-secure          |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed

    Given I use the "<%= cb.node %>" node
    When I run commands on the host:
      | netstat -anlp \| grep "haproxy" |
    Then the step should succeed
    And the output should match:
      | :::80 .* LISTEN  |
      | :::443 .* LISTEN |

    # access routes via loopback IPv6 address [::1] from the node
    Given I wait up to 15 seconds for the steps to pass:
    """
    When I run commands on the host:
      | curl --resolve <%= route("service-unsecure").dns(by: user) %>:80:::1 http://<%= route("service-unsecure").dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

    Given I wait up to 15 seconds for the steps to pass:
    """
    When I run commands on the host:
      | curl --resolve <%= route("reen-route").dns(by: user) %>:443:::1 https://<%= route("reen-route").dns(by: user) %>/ -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

    # can also access the route via IPv4 address
    When I wait up to 15 seconds for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("reen-route").dns(by: user) %>:443:<%= cb.router_ip %> |
      | https://<%= route("reen-route").dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

  # @author hongli@redhat.com
  # @case_id OCP-13845
  @admin
  @destructive
  Scenario: The haproxy support terminate IPv6 traffic at the router if set ROUTER_IP_V4_V6_MODE to v6
    Given the master version >= "3.6"
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_IP_V4_V6_MODE=v6 |
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    And evaluation of `pod.node_name` is stored in the :node clipboard

    Given I switch to the first user
    And I have a project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/routing/list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=caddy-pods |

    # create edge and passthrough route
    When I run the :create_route_edge client command with:
      | name    | edge-route       |
      | service | service-unsecure |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name    | pass-route     |
      | service | service-secure |
    Then the step should succeed

    Given I use the "<%= cb.node %>" node
    When I run commands on the host:
      | netstat -anlp \| grep "haproxy" |
    Then the step should succeed
    And the output should match:
      | :::80 .* LISTEN  |
      | :::443 .* LISTEN |

    # access routes via loopback IPv6 address [::1] from the node
    Given I wait up to 15 seconds for the steps to pass:
    """
    When I run commands on the host:
      | curl --resolve <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:::1 https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/ -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

    Given I wait up to 15 seconds for the steps to pass:
    """
    When I run commands on the host:
      | curl --resolve <%= route("pass-route", service("pass-route")).dns(by: user) %>:443:::1 https://<%= route("pass-route", service("pass-route")).dns(by: user) %>/ -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

    # CANNOT access the route via IPv4
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/ |
      | -k |
    Then the step should fail
    And the output should not contain "Hello-OpenShift"

    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("pass-route", service("pass-route")).dns(by: user) %>:443:<%= cb.router_ip %> |
      | https://<%= route("pass-route", service("pass-route")).dns(by: user) %>/ |
      | -k |
    Then the step should fail
    And the output should not contain "Hello-OpenShift"

