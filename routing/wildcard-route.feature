Feature: Testing wildcard routes

  # @author bmeng@redhat.com
  # @case_id OCP-12003
  @admin
  @destructive
  Scenario: Create wildcard domain route for unsecure route
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_ALLOW_WILDCARD_ROUTES=true |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/wildcard_route/route_unsecure_test.example.com.json |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | --resolve |
      | www.test.example.com:80:<%= cb.router_ip[0] %> |
      | http://www.test.example.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    Given an 8 characters random string of type :dns952 is stored into the :wildcard_route clipboard
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= cb.wildcard_route %>.test.example.com:80:<%= cb.router_ip[0] %> |
      | http://<%= cb.wildcard_route %>.test.example.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"


  # @author bmeng@redhat.com
  # @case_id OCP-12181
  @admin
  @destructive
  Scenario: Use blacklist to forbid the specified hostname to be created
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_ALLOW_WILDCARD_ROUTES=true      |
      | ROUTER_DENIED_DOMAINS=edge.example.com |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/wildcard_route/route_edge.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
      | resource_name | wildcard-edge-route |
    Then the step should succeed
    And the output should contain "RouteNotAdmitted"
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | --resolve |
      | wildcard.edge.example.com:443:<%= cb.router_ip[0] %> |
      | https://wildcard.edge.example.com/ |
      | -ksS |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"

    Given an 6 characters random string of type :dns952 is stored into the :route_forbid clipboard
    When I run the :create_route_edge client command with:
      | name | route-edge-deny |
      | service | service-unsecure |
      | hostname | <%= cb.route_forbid %>.edge.example.com |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
      | resource_name | route-edge-deny |
    Then the step should succeed
    And the output should contain "RouteNotAdmitted"
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= cb.route_forbid %>.edge.example.com:443:<%= cb.router_ip[0] %> |
      | https://<%= cb.route_forbid %>.edge.example.com/ |
      | -ksS |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"

    Given an 6 characters random string of type :dns952 is stored into the :route_allow clipboard
    When I run the :create_route_edge client command with:
      | name | route-edge-allow |
      | service | service-unsecure |
      | hostname | <%= cb.route_allow %>.test.example.com |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
      | resource_name | route-edge-allow |
    Then the step should succeed
    And the output should not contain "RouteNotAdmitted"
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= cb.route_allow %>.test.example.com:443:<%= cb.router_ip[0] %> |
      | https://<%= cb.route_allow %>.test.example.com/ |
      | -ksS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

  # @author bmeng@redhat.com
  # @case_id OCP-12182
  @admin
  @destructive
  Scenario: Only allow the host which matches the whilelist to be created
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_ALLOWED_DOMAINS=test.example.com |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    Given an 6 characters random string of type :dns952 is stored into the :route_allow clipboard
    When I run the :expose client command with:
      | resource | service |
      | resource_name | service-unsecure |
      | hostname | <%= cb.route_allow %>.test.example.com |
      | name | route-allowed |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
      | resource_name | route-allowed |
    Then the step should succeed
    And the output should not contain "RouteNotAdmitted"
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= cb.route_allow %>.test.example.com:80:<%= cb.router_ip[0] %> |
      | http://<%= cb.route_allow %>.test.example.com/ |
      | -sS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

    Given an 6 characters random string of type :dns952 is stored into the :route_forbid clipboard
    When I run the :expose client command with:
      | resource | service |
      | resource_name | service-unsecure |
      | hostname | <%= cb.route_forbid %>.example.com |
      | name | route-denied |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
      | resource_name | route-denied |
    Then the step should succeed
    And the output should contain "RouteNotAdmitted"
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= cb.route_forbid %>.example.com:80:<%= cb.router_ip[0] %> |
      | http://<%= cb.route_forbid %>.example.com/ |
      | -sS |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"

  # @author bmeng@redhat.com
  # @case_id OCP-12230
  @admin
  @destructive
  Scenario: Wildcard domain should work well for edge route with different insecure policies
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_ALLOW_WILDCARD_ROUTES=true |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/wildcard_route/route_edge.json |
    Then the step should succeed

    When I run the :patch client command with:
      | resource | route |
      | resource_name | wildcard-edge-route |
      | p | {"spec":{"tls": { "insecureEdgeTerminationPolicy":"Allow"}}} |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | --resolve |
      | test1.edge.example.com:443:<%= cb.router_ip[0] %> |
      | https://test1.edge.example.com/ |
      | -ksS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    When I execute on the pod:
      | curl |
      | --resolve |
      | test2.edge.example.com:80:<%= cb.router_ip[0] %> |
      | http://test2.edge.example.com/ |
      | -sS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

    When I run the :patch client command with:
      | resource | route |
      | resource_name | wildcard-edge-route |
      | p | {"spec":{"tls": { "insecureEdgeTerminationPolicy":"Redirect"}}} |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | test3.edge.example.com:443:<%= cb.router_ip[0] %> |
      | --resolve |
      | test3.edge.example.com:80:<%= cb.router_ip[0] %> |
      | http://test3.edge.example.com/ |
      | -ksSL |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | test4.edge.example.com:443:<%= cb.router_ip[0] %> |
      | https://test4.edge.example.com/ |
      | -ksS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-11067
  Scenario: oc help information should contain option wildcard-policy
    Given I have a project
    When I run the :expose client command with:
      | resource | service   |
      | resource_name | service-secure |
      | help     |           |
    Then the step should succeed
    And the output should contain "--wildcard-policy="

    #check 'oc create route edge' help
    When I run the :create_route_edge client command with:
      | name   | route-edge |
      | help   |            |
    Then the step should succeed
    And the output should contain "--wildcard-policy="

    #Check 'oc create route passthrough' help
    When I run the :create_route_passthrough client command with:
      | name  | route-pass |
      | help  |            |
    Then the step should succeed
    And the output should contain "--wildcard-policy="

    #Test 'oc create route reencrypt' help
    When I run the :create_route_reencrypt client command with:
      | name | route-reen |
      | help |            |
    Then the step should succeed
    And the output should contain "--wildcard-policy="


  # @author bmeng@redhat.com
  # @case_id OCP-13484
  @admin
  @destructive
  Scenario: Use router with both allowed and denied domain list
    # Add both the allow and deny env to the router, and the allowed domain contains denied domain
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_ALLOWED_DOMAINS=example.com     |
      | ROUTER_DENIED_DOMAINS=test.example.com |

    Given I switch to the first user
    And I have a project
    And evaluation of `project.name` is stored in the :project clipboard
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    Given an 6 characters random string of type :dns952 is stored into the :route_allow clipboard
    When I run the :expose client command with:
      | resource | service |
      | resource_name | service-unsecure |
      | hostname | <%= cb.route_allow %>.example.com |
      | name | route-allowed |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
      | resource_name | route-allowed |
    Then the step should succeed
    And the output should not contain "RouteNotAdmitted"
    Given I have a pod-for-ping in the project
    And evaluation of `pod.name` is stored in the :pod_for_ping clipboard
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= cb.route_allow %>.example.com:80:<%= cb.router_ip[0] %> |
      | http://<%= cb.route_allow %>.example.com/ |
      | -sS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

    Given an 6 characters random string of type :dns952 is stored into the :route_forbid_1 clipboard
    When I run the :expose client command with:
      | resource | service |
      | resource_name | service-unsecure |
      | hostname | <%= cb.route_forbid_1 %>.test.example.com |
      | name | route-denied-1 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
      | resource_name | route-denied-1 |
    Then the step should succeed
    And the output should contain "RouteNotAdmitted"
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= cb.route_forbid_1 %>.test.example.com:80:<%= cb.router_ip[0] %> |
      | http://<%= cb.route_forbid_1 %>.test.example.com/ |
      | -sS |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"

    # Switch the value of the deny and allow rules, make the denied domain contains the allowed domain
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_ALLOWED_DOMAINS=test.example.com |
      | ROUTER_DENIED_DOMAINS=example.com |

    Given I switch to the first user
    And I use the "<%= cb.project %>" project
    And an 6 characters random string of type :dns952 is stored into the :route_forbid_2 clipboard
    And I store default router IPs in the :router_ip_1 clipboard
    When I run the :expose client command with:
      | resource | service |
      | resource_name | service-unsecure |
      | hostname | <%= cb.route_forbid_2 %>.example.com |
      | name | route-denied-2 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
      | resource_name | route-denied-2 |
    Then the step should succeed
    And the output should contain "RouteNotAdmitted"
    When I execute on the "<%= cb.pod_for_ping %>" pod:
      | curl |
      | --resolve |
      | <%= cb.route_forbid_2 %>.example.com:80:<%= cb.router_ip_1[0] %> |
      | http://<%= cb.route_forbid_2 %>.example.com/ |
      | -sS |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"

    Given an 6 characters random string of type :dns952 is stored into the :route_forbid_3 clipboard
    When I run the :expose client command with:
      | resource | service |
      | resource_name | service-unsecure |
      | hostname | <%= cb.route_forbid_3 %>.test.example.com |
      | name | route-denied-3 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
      | resource_name | route-denied-3 |
    Then the step should succeed
    And the output should contain "RouteNotAdmitted"
    When I execute on the "<%= cb.pod_for_ping %>" pod:
      | curl |
      | --resolve |
      | <%= cb.route_forbid_3 %>.test.example.com:80:<%= cb.router_ip_1[0] %> |
      | http://<%= cb.route_forbid_3 %>.test.example.com/ |
      | -sS |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-19798
  @admin
  @destructive
  Scenario: Secured Wildcard route should not takes over all unsecured routes
    Given the master version >= "3.9"
    And admin ensures new router pod becomes ready after following env added:
      | ROUTER_ALLOW_WILDCARD_ROUTES=true |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name           | route-edge                                |
      | hostname       | wildcard.edge.example.com                 |
      | service        | service-unsecure                          |
      | wildcardpolicy | Subdomain                                 |
      | insecure_policy | Allow                                    |
    Then the step should succeed

    #Create another app
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/header-test/dc.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=header-test |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/header-test/insecure-service.json |
    Then the step should succeed
    Given an 8 characters random string of type :dns952 is stored into the :header_route clipboard
    When I run the :expose client command with:
      | resource      | service                                 |
      | resource_name | header-test-insecure                    |
      | name          | route1                                  |
      | hostname      | <%= cb.header_route %>.edge.example.com |

    Given I have a pod-for-ping in the project
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= cb.header_route %>.edge.example.com:80:<%= cb.router_ip[0] %> |
      | http://<%= cb.header_route %>.edge.example.com/ |
    Then the step should succeed
    And the output should contain "edge.example.com"
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | test2.edge.example.com:80:<%= cb.router_ip[0] %> |
      | http://test2.edge.example.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
