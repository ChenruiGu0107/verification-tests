Feature: Testing timeout route

  # @author yadu@redhat.com
  # @case_id OCP-11982
  Scenario: Set timeout server for unsecure route
    Given I have a project
    Given I obtain test data file "routing/routetimeout/httpbin-pod.json"
    When I run the :create client command with:
      | f  |  httpbin-pod.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=httpbin-pod |
    Given I obtain test data file "routing/routetimeout/service_unsecure.json"
    When I run the :create client command with:
      | f  | service_unsecure.json |
    Then the step should succeed
    Given I wait for the "service-unsecure" service to become ready
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :annotate client command with:
      | resource         | route                                  |
      | resourcename     | service-unsecure                       |
      | overwrite        | true                                   |
      | keyval           | haproxy.router.openshift.io/timeout=3s |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route.dns(by: user) %>/delay/1" url
    Then the step should succeed
    And the output should contain:
      | "X-Forwarded-Host": "service-unsecure |
      | delay/1                               |
    When I open web server via the "http://<%= route.dns(by: user) %>/delay/5" url
    Then the output should contain "504 Gateway"
    """

  # @author yadu@redhat.com
  # @case_id OCP-11347
  Scenario: Set timeout server for edge route
    Given I have a project
    And I store an available router IP in the :router_ip clipboard
    Given I obtain test data file "routing/routetimeout/httpbin-pod.json"
    When I run the :create client command with:
      | f  |  httpbin-pod.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=httpbin-pod |
    Given I obtain test data file "routing/routetimeout/service_unsecure.json"
    When I run the :create client command with:
      | f  | service_unsecure.json |
    Then the step should succeed
    Given I wait for the "service-unsecure" service to become ready
    When I run the :create_route_edge client command with:
      | name     | edge-route       |
      | service  | service-unsecure |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource         | route                                  |
      | resourcename     | edge-route                             |
      | overwrite        | true                                   |
      | keyval           | haproxy.router.openshift.io/timeout=3s |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl                                                                                       |
      | --resolve                                                                                  |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/delay/2            |
      | -k                                                                                         |
    Then the step should succeed
    Then the output should contain:
      | "X-Forwarded-Host": "edge-route |
      | delay/2                         |
    When I execute on the pod:
      | curl                                                                                       |
      | --resolve                                                                                  |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/delay/4            |
      | -k                                                                                         |
    Then the output should contain "504 Gateway"

  # @author yadu@redhat.com
  # @case_id OCP-11826
  Scenario: Set timeout server for reencrypt route
    Given I have a project
    And I store an available router IP in the :router_ip clipboard
    Given I obtain test data file "routing/routetimeout/httpbin-pod-2.json"
    When I run the :create client command with:
      | f  | httpbin-pod-2.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=httpbin-pod |
    Given I obtain test data file "routing/routetimeout/service_secure.json"
    When I run the :create client command with:
      | f  | service_secure.json |
    Then the step should succeed
    Given I wait for the "service-secure" service to become ready
    Given I obtain test data file "routing/reencrypt/route_reencrypt-reen.example.com.crt"
    Given I obtain test data file "routing/reencrypt/route_reencrypt-reen.example.com.key"
    Given I obtain test data file "routing/reencrypt/route_reencrypt.ca"
    Given I obtain test data file "routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | reen-route                                                                                             |
      | hostname   | <%= rand_str(5, :dns) %>-reen.example.com                                                              |
      | service    | service-secure                                                                                         |
      | cert       | route_reencrypt-reen.example.com.crt |
      | key        | route_reencrypt-reen.example.com.key |
      | cacert     | route_reencrypt.ca                   |
      | destcacert | route_reencrypt_dest.ca              |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource         | route                                  |
      | resourcename     | reen-route                             |
      | overwrite        | true                                   |
      | keyval           | haproxy.router.openshift.io/timeout=3s |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl                                                                                       |
      | --resolve                                                                                  |
      | <%= route("reen-route", service("reen-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("reen-route", service("reen-route")).dns(by: user) %>/delay/2            |
      | -k                                                                                         |
    Then the step should succeed
    Then the output should contain:
      | reen.example.com/delay/2 |
    When I execute on the pod:
      | curl                                                                                       |
      | --resolve                                                                                  |
      | <%= route("reen-route", service("reen-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("reen-route", service("reen-route")).dns(by: user) %>/delay/5            |
      | -k                                                                                         |
    Then the output should contain "504 Gateway"

  # @author yadu@redhat.com
  # @case_id OCP-10943
  @admin
  Scenario: Set invalid timeout server for route
    Given I have a project
    Given I obtain test data file "routing/routetimeout/service_unsecure.json"
    When I run the :create client command with:
      | f  | service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :annotate client command with:
      | resource         | route                                   |
      | resourcename     | service-unsecure                        |
      | overwrite        | true                                    |
      | keyval           | haproxy.router.openshift.io/timeout=-3s |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | service-unsecure |
      | \-A              |
      | 15               |
      | haproxy.config   |
    Then the output should not contain "timeout server  -3s"
    Given I switch to the first user
    When I run the :annotate client command with:
      | resource         | route                                   |
      | resourcename     | service-unsecure                        |
      | overwrite        | true                                    |
      | keyval           | haproxy.router.openshift.io/timeout=abc |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | service-unsecure |
      | \-A              |
      | 15               |
      | haproxy.config   |
    Then the output should not contain "timeout server  abc"
    Given I switch to the first user
    When I run the :annotate client command with:
      | resource         | route                                   |
      | resourcename     | service-unsecure                        |
      | overwrite        | true                                    |
      | keyval           | haproxy.router.openshift.io/timeout=*^% |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | service-unsecure |
      | \-A              |
      | 15               |
      | haproxy.config   |
    Then the output should not contain "timeout server  *^%"
