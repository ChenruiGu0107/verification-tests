Feature: Testing haproxy rate limit related features

  # @author hongli@redhat.com
  # @case_id OCP-18482
  Scenario Outline: limits backend pod max concurrent connections for unsecure, edge, reen route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/httpbin-pod.json |
    Then the step should succeed
    And the pod named "httpbin-pod" becomes ready

    When I run the :create client command with:
      | f | <service> |
    Then the step should succeed
    When I run the :create client command with:
      | f | <route> |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | -c | for i in {1..4} ; do curl -sS --resolve <resolve_str>:<%= cb.router_ip[0] %> <url>/delay/6 -k -I & done |
    Then the step should succeed
    And the output should contain 4 times:
      | 200 OK |

    When I run the :annotate client command with:
      | resource     | route        |
      | resourcename | <route_name> |
      | keyval       | haproxy.router.openshift.io/pod-concurrent-connections=<pass_num> |
    Then the step should succeed
    When I execute on the pod:
      | bash | -c | for i in {1..4} ; do curl -sS --resolve <resolve_str>:<%= cb.router_ip[0] %> <url>/delay/6 -k -I & done |
    Then the step should succeed
    And the output should contain <pass_num> times:
      | 200 OK |
    And the output should contain <fail_num> times:
      | 503 Service Unavailable |

    Examples:
      | route_type | route_name | service | route | resolve_str | url | pass_num | fail_num |
      | unsecure | route | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/unsecure/service_unsecure.json | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/route_unsecure.json | unsecure.example.com:80 | http://unsecure.example.com | 1 | 3 |
      | edge | secured-edge-route | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/edge/service_unsecure.json | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge.json | test-edge.example.com:443 | https://test-edge.example.com | 2 | 2 |
      | reen | route-reencrypt | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/reencrypt/service_secure.json | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt.json | test-reen.example.com:443 | https://test-reen.example.com | 3 | 1 |


  # @author hongli@redhat.com
  # @case_id OCP-18483
  Scenario Outline: set negative value for the max concurrent connections a pod can receive
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/httpbin-pod.json |
    Then the step should succeed
    And the pod named "httpbin-pod" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/unsecure/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed

    # annotatate with invalid value (should be ignored)
    When I run the :annotate client command with:
      | resource     | route            |
      | resourcename | service-unsecure |
      | keyval       | haproxy.router.openshift.io/pod-concurrent-connections=<conn> |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | -c | for i in {1..4} ; do curl -sS --resolve <%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>:80:<%= cb.router_ip[0] %> http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/delay/6 -I & done |
    Then the step should succeed
    And the output should contain 4 times:
      | 200 OK |

    Examples:
      | conn |
      | 0    |
      | -6   |
      | abc  |


  # @author hongli@redhat.com
  # @case_id OCP-18489
  Scenario: limits backend pod max concurrent connections for passthrough route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/httpbin-pod.json |
    Then the step should succeed
    And the pod named "httpbin-pod" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/passthough/service_secure.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name    | route-pass     |
      | service | service-secure |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | -c | for i in {1..4} ; do curl -sS --resolve <%= route("route-pass", service("service-secure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> https://<%= route("route-pass", service("service-secure")).dns(by: user) %>/delay/6 -k -I & done |
    Then the step should succeed
    And the output should contain 4 times:
      | 200 OK |
    When I run the :annotate client command with:
      | resource     | route      |
      | resourcename | route-pass |
      | keyval       | haproxy.router.openshift.io/pod-concurrent-connections=2 |
    Then the step should succeed
    When I execute on the pod:
      | bash | -c | for i in {1..4} ; do curl -sS --resolve <%= route("route-pass", service("service-secure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> https://<%= route("route-pass", service("service-secure")).dns(by: user) %>/delay/6 -k -I & done |
    Then the step should succeed
    And the output should contain 2 times:
      | 200 OK |
    And the output should contain 2 times:
      | ERROR |


  # @author hongli@redhat.com
  # @case_id OCP-18490
  Scenario: limits multiple backend pods max concurrent connections
    Given I have a project
    And I store default router IPs in the :router_ip clipboard

    # create two httpbin pods which have same labels
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/httpbin-pod.json |
    Then the step should succeed
    And the pod named "httpbin-pod" becomes ready
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/httpbin-pod.json" replacing paths:
      | ["metadata"]["name"] | "httpbin-pod2" |
    Then the step should succeed

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name    | route-edge       |
      | service | service-unsecure |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | -c | for i in {1..4} ; do curl -sS --resolve <%= route("route-edge", service("service-unsecure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> https://<%= route("route-edge", service("service-unsecure")).dns(by: user) %>/delay/6 -k -I & done |
    Then the step should succeed
    And the output should contain 4 times:
      | 200 OK |
    When I run the :annotate client command with:
      | resource     | route      |
      | resourcename | route-edge |
      | keyval       | haproxy.router.openshift.io/pod-concurrent-connections=1 |
    Then the step should succeed
    When I execute on the pod:
      | bash | -c | for i in {1..4} ; do curl -sS --resolve <%= route("route-edge", service("service-unsecure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> https://<%= route("route-edge", service("service-unsecure")).dns(by: user) %>/delay/6 -k -I & done |
    Then the step should succeed
    And the output should contain 2 times:
      | 200 OK |
    And the output should contain 2 times:
      | 503 Service Unavailable |
