Feature: Testing timeout route

  # @author: yadu@redhat.com
  # @case_id: 533703
  Scenario: Set timeout for unsecure route
    Given I have a project
    When I run the :create client command with:
      | f  |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/httpbin-pod.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/unsecure/service_unsecure.json |
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
    When I open web server via the "http://<%= route.dns(by: user) %>/delay/1" url
    Then the step should succeed
    Then the output should contain:
      | "X-Forwarded-Host": "service-unsecure |
      | delay/1                               |
    When I open web server via the "http://<%= route.dns(by: user) %>/delay/5" url
    Then the output should contain "504 Gateway"

  # @author: yadu@redhat.com
  # @case_id: 533700
  Scenario: Set timeout for edge route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f  |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/httpbin-pod.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/routetimeout/unsecure/service_unsecure.json |
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
