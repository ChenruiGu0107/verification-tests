Feature: Testing wildcard routes

  # @author bmeng@redhat.com
  # @case_id OCP-11403 OCP-11671 OCP-11855
  @admin
  @destructive
  Scenario Outline: Create wildcard domain routes
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ALLOW_WILDCARD_ROUTES=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | "<service>" |
    Then the step should succeed
    When I run the :create client command with:
      | f | "<route>" |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | wildcard.<route-suffix>:443:<%= cb.router_ip[0] %> |
      | https://wildcard.<route-suffix>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    Given an 8 characters random string of type :dns952 is stored into the :wildcard_route clipboard
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | <%= cb.wildcard_route %>.<route-suffix>:443:<%= cb.router_ip[0] %> |
      | https://<%= cb.wildcard_route %>.<route-suffix>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

    Examples:
      | route_type | service | route | route-suffix |
      | edge | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/route_edge.json | edge.example.com |
      | reencrypt | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/service_secure.json | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/route_reencrypt.json | reen.example.com |
      | passthrough | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/route_pass.json | pass.example.com |


  # @author bmeng@redhat.com
  # @case_id OCP-12003
  @admin
  @destructive
  Scenario: Create wildcard domain route for unsecure route
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ALLOW_WILDCARD_ROUTES=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/route_unsecure_test.example.com.json |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | www.test.example.com:80:<%= cb.router_ip[0] %> |
      | http://www.test.example.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    Given an 8 characters random string of type :dns952 is stored into the :wildcard_route clipboard
    When I execute on the "hello-pod" pod:
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
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ALLOW_WILDCARD_ROUTES=true |
      | e        | ROUTER_DENIED_DOMAINS=edge.example.com |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/route_edge.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
      | resource_name | wildcard-edge-route |
    Then the step should succeed
    And the output should contain "RouteNotAdmitted"
    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
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
    When I execute on the "hello-pod" pod:
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
    When I execute on the "hello-pod" pod:
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
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ALLOWED_DOMAINS=test.example.com |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
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
    When I execute on the "hello-pod" pod:
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
    When I execute on the "hello-pod" pod:
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
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ALLOW_WILDCARD_ROUTES=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/route_edge.json |
    Then the step should succeed

    When I run the :patch client command with:
      | resource | route |
      | resource_name | wildcard-edge-route |
      | p | {"spec":{"tls": { "insecureEdgeTerminationPolicy":"Allow"}}} |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | test1.edge.example.com:443:<%= cb.router_ip[0] %> |
      | https://test1.edge.example.com/ |
      | -ksS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    When I execute on the "hello-pod" pod:
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
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | test3.edge.example.com:443:<%= cb.router_ip[0] %> |
      | --resolve |
      | test3.edge.example.com:80:<%= cb.router_ip[0] %> |
      | http://test3.edge.example.com/ |
      | -ksSL |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | test4.edge.example.com:443:<%= cb.router_ip[0] %> |
      | https://test4.edge.example.com/ |
      | -ksS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"


  # @author bmeng@redhat.com
  # @case_id OCP-10488
  @admin
  @destructive
  Scenario: The route matches more should win the routing
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ALLOW_WILDCARD_ROUTES=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/route_unsecure_test.example.com.json |
    Then the step should succeed

    Given I switch to the second user
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker-2.json |
    Then the step should succeed
    And the pod named "caddy-docker-2" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/route_unsecure_sub.test.example.com.json |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    And an 6 characters random string of type :dns952 is stored into the :wildcard_route clipboard
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= cb.wildcard_route %>.test.example.com:80:<%= cb.router_ip[0] %> |
      | http://<%= cb.wildcard_route %>.test.example.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | <%= cb.wildcard_route %>.sub.test.example.com:80:<%= cb.router_ip[0] %> |
      | http://<%= cb.wildcard_route %>.sub.test.example.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-2"

  # @author bmeng@redhat.com
  # @case_id OCP-10495
  @admin
  @destructive
  Scenario: Should not be able to create a wildcard enabled route when the host is not specified
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ALLOW_WILDCARD_ROUTES=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/route_wildcard_no_host.json |
    Then the step should fail
    And the output should match "Invalid value.*host name not specified"
