Feature: Testing haproxy router

  # @author zzhao@redhat.com
  # @case_id 512275
  @admin
  Scenario: HTTP response header should return for default haproxy 503
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And I execute on the pod:
      | /usr/bin/curl | -v  | 127.0.0.1:80 |
    Then the output should contain "HTTP/1.0 503 Service Unavailable"

  # @author zzhao@redhat.com
  # @case_id 510357
  @admin
  Scenario: Should expose the status monitoring endpoint for haproxy router
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And I execute on the pod:
      | /usr/bin/curl |  127.0.0.1:1936/healthz |
    Then the output should contain "Service ready"

  # @author bmeng@redhat.com
  # @case_id 505814
  @admin
  Scenario: The routekey should use underline instead of dash as connector
    Given I have a project
    And evaluation of `project.name` is stored in the :pj_name clipboard
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc505814/route_unsecure.json|
    Then the step should succeed
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc505814/route_edge.json|
    Then the step should succeed
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc505814/route_reencrypt.json|
    Then the step should succeed
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc505814/route_pass.json|
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | cat |
      | os_http_be.map |
    Then the output should contain "<%= cb.pj_name %>_route"
    When I execute on the "<%= cb.router_pod %>" pod:
      | cat |
      | os_edge_http_be.map |
    Then the output should contain "<%= cb.pj_name %>_secured-edge-route"
    When I execute on the "<%= cb.router_pod %>" pod:
      | cat |
      | os_reencrypt.map |
    Then the output should contain "<%= cb.pj_name %>_route-reencrypt"
    When I execute on the "<%= cb.router_pod %>" pod:
      | cat |
      | os_tcp_be.map |
    Then the output should contain "<%= cb.pj_name %>_route-passthrough"

