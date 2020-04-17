Feature: Route test in online environments
  # @author zhaliu@redhat.com
  # @case_id OCP-10047
  Scenario: Custom route with passthrough termination is not permitted
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/passthrough/service_secure.json |
    Then the step should succeed
    And I wait for the "service-secure" service to become ready
    When I run the :create_route_passthrough client command with:
      | name | passthrough-route-custom |
      | hostname | <%= rand_str(5, :dns) %>-pass.example.com |
      | service | service-secure |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I run the :create_route_passthrough client command with:
      | name | passthrough-route |
      | service | service-secure |
    Then the step should succeed
    And I wait for a secure web server to become available via the "passthrough-route" route
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("passthrough-route-custom", service("service-secure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("passthrough-route-custom", service("service-secure")).dns(by: user) %> |
      | -I |
      | -k |
    Then the output should match "HTTP/.* 503 Service Unavailable"

  # @author zhaliu@redhat.com
  # @case_id OCP-10046
  Scenario: Custom route with edge termination is not permitted
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    And I wait for the "service-unsecure" service to become ready
    Given I obtain test data file "routing/edge/route_edge-www.edge.com.crt"
    And I obtain test data file "routing/edge/route_edge-www.edge.com.key"
    And I obtain test data file "routing/ca.pem"
    When I run the :create_route_edge client command with:
      | name | edge-route-custom |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
      | cacert | ca.pem |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | service-unsecure |
    Then the step should succeed
    And I wait for a secure web server to become available via the "edge-route" route

    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("edge-route-custom", service("service-unsecure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route-custom", service("service-unsecure")).dns(by: user) %>/ |
      | -I |
      | -k |
      | -v |
    Then the output should match "HTTP/.* 503 Service Unavailable"
    Then the output should not contain "CN=*.example.com"

  # @author zhaliu@redhat.com
  # @case_id OCP-16357
  Scenario: There should be no privilege of creating custom routes in admin and edit role
    Given I have a project
    When I run the :get client command with:
      | resource      | clusterrole                             |
      | resource_name | admin                                   |
      | o             | template                                |
      | template      | {{range .rules}} {{.resources}} {{end}} |
    Then the step should succeed
    And the output should contain "cicd-is-disabling-routes/custom-host"

    When I run the :get client command with:
      | resource      | clusterrole                             |
      | resource_name | edit                                    |
      | o             | json                                    |
      | template      | {{range .rules}} {{.resources}} {{end}} |
    Then the step should succeed
    And the output should contain "cicd-is-disabling-routes/custom-host"

