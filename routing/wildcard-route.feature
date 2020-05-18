Feature: Testing wildcard routes
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
