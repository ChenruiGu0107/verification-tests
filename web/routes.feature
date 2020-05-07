Feature: Routes related features on web console
  # @author yanpzhan@redhat.com
  # @case_id OCP-12321
  Scenario: Create unsecured route on web console
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/authorization/scc/pod_requests_nothing.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-unsecure   |
    Then the step should succeed

    When I perform the :create_unsecured_route_from_service_or_overview_page web console action with:
      | route_name | service-unsecure-route |
    Then the step should succeed
    When I perform the :check_route_name_in_table_row web console action with:
      | route_name | service-unsecure-route |
    Then the step should succeed

    When I perform the :check_routes_page web console action with:
      | project_name | <%= project.name %>    |
      | route_name   | service-unsecure-route |
      | service_name | service-unsecure       |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-12258
  Scenario: Create route for multi-port services on web console
    Given the master version >= "3.3"
    When I create a new project
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/services/multi-portsvc.json |
    Then the step should succeed
    When I perform the :check_empty_routes_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :create_route_dont_specify_hostname_from_routes_page web console action with:
      | service_name | multi-portsvc       |
      | route_name   | myroute1            |
      | target_port  | 443                 |
    Then the step should succeed
    When I perform the :check_route_name_in_table_row web console action with:
      | route_name | myroute1 |
    Then the step should succeed
    When I perform the :create_route_dont_specify_hostname_from_routes_page web console action with:
      | project_name | <%= project.name %> |
      | service_name | multi-portsvc       |
      | route_name   | myroute2            |
      | target_port  | 80                  |
    Then the step should succeed
    When I perform the :check_route_name_in_table_row web console action with:
      | route_name | myroute2 |
    Then the step should succeed
    When I perform the :check_route_page_loaded_successfully web console action with:
      | project_name | <%= project.name %> |
      | route_name   | myroute1            |
      | service_name | multi-portsvc       |
    Then the step should succeed
    When I get the html of the web page
    Then the output should match:
      | route to.*27443.*443 |
    When I perform the :check_route_page_loaded_successfully web console action with:
      | project_name | <%= project.name %> |
      | route_name   | myroute2            |
      | service_name | multi-portsvc       |
    Then the step should succeed
    When I get the html of the web page
    Then the output should match:
      | route to.*27017.*80 |

  # @author yapei@redhat.com
  # @case_id OCP-12149
  Scenario: Create passthrough terminated route on web console
    Given I create a new project
    # create pod, service
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/caddy-docker.json               |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/passthrough/service_secure.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    # create passthrough route on web console
    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-secure     |
    Then the step should succeed
    When I perform the :select_tls_termination_type web console action with:
      | tls_termination_type | Passthrough |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    # check route is accessible
    And I wait up to 60 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= route("service-secure").dns %>" url
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |
    """
