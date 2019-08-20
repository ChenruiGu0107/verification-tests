Feature: route related

  # @author yanpzhan
  # @case_id OCP-21004
  Scenario: Create Passthrough route from form
    Given the master version >= "4.1"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker-2.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    Given I open admin console in a browser

    When I perform the :goto_routes_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Create Route |
    Then the step should succeed

    When I perform the :create_route web action with:
      | route_name            | passthroughroute |
      | service_name          | service-secure   |
      | target_port           | https            |
      | secure_route          | true             |
      | tls_termination_type  | passthrough      |
      | insecure_traffic_type | Redirect         |
    Then the step should succeed

    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Termination Type |
      | value | passthrough      |
    Then the step should succeed

    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Insecure Traffic |
      | value | Redirect         |
    Then the step should succeed

    When I run the :get client command with:
      | resource | route |
      | o        | yaml  |
    Then the step should succeed
    And the output should contain:
      | termination: passthrough                |
      | insecureEdgeTerminationPolicy: Redirect |

    Given I store default router subdomain in the :subdomain clipboard
    When I open web server via the "http://passthroughroute-<%= project.name %>.<%= cb.subdomain %>" url
    Then the output should contain "Hello-OpenShift-2 https-8443"
