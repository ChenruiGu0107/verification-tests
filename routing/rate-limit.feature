Feature: Testing haproxy rate limit related features

  # @author hongli@redhat.com
  # @case_id OCP-18483
  Scenario Outline: set negative value for the max concurrent connections a pod can receive
    Given I have a project
    And I store an available router IP in the :router_ip clipboard
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
  @admin
  Scenario: limits backend pod max concurrent connections for passthrough route
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/httpbin-pod.json |
    Then the step should succeed
    And the pod named "httpbin-pod" becomes ready
    And evaluation of `pod.ip` is stored in the :pod_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/passthough/service_secure.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name    | route-pass     |
      | service | service-secure |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route      |
      | resourcename | route-pass |
      | keyval       | haproxy.router.openshift.io/pod-concurrent-connections=2 |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain:
      | maxconn 2 |
    """


  # @author hongli@redhat.com
  # @case_id OCP-18490
  @admin
  Scenario: limits multiple backend pods max concurrent connections
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    # create two httpbin pods which have same labels
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/httpbin-pod.json |
    Then the step should succeed
    And the pod named "httpbin-pod" becomes ready
    And evaluation of `pod.ip` is stored in the :pod_ip clipboard
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
    When I run the :annotate client command with:
      | resource     | route      |
      | resourcename | route-edge |
      | keyval       | haproxy.router.openshift.io/pod-concurrent-connections=1 |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config | -C 1 |
    Then the output should contain 2 times:
      | maxconn 1 |
    """
