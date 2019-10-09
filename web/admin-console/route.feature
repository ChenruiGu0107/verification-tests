Feature: route related

  # @author yanpzhan@redhat.com
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

  # @author yanpzhan@redhat.com
  # @case_id OCP-21007
  Scenario: Create edge route from form
    Given the master version >= "4.1"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.key"
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.crt"
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem"
    Then the step should succeed

    Given I open admin console in a browser

    When I perform the :goto_routes_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Create Route |
    Then the step should succeed

    When I perform the :create_route web action with:
      | route_name            | edgeroute            |
      | route_hostname        | edgetest.example.com |
      | route_path            | /test                |
      | service_name          | service-unsecure     |
      | target_port           | http                 |
      | secure_route          | true                 |
      | tls_termination_type  | edge                 |
      | insecure_traffic_type | Allow                |
      | certificate_path      | <%= File.join(localhost.workdir, "route_edge-www.edge.com.crt") %> |
      | private_key_path      | <%= File.join(localhost.workdir, "route_edge-www.edge.com.key") %> |
      | ca_certificate_path   | <%= File.join(localhost.workdir, "ca.pem") %>                      |
    Then the step should succeed

    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Termination Type |
      | value | edge             |
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Insecure Traffic |
      | value | Allow            |
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Hostname             |
      | value | edgetest.example.com |
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Path  |
      | value | /test |
    Then the step should succeed
    And the expression should be true> route('edgeroute').spec.host == "edgetest.example.com"
    And the expression should be true> route('edgeroute').spec.target_port == "http"
    And the expression should be true> route('edgeroute').spec.tls_termination == "edge"
    And the expression should be true> route('edgeroute').spec.tls_insecure_edge_termination_policy == "Allow"
    And the expression should be true> route('edgeroute').spec.path == "/test"
    And the expression should be true> route('edgeroute').spec.tls_certificate != ""
    And the expression should be true> route('edgeroute').spec.tls_key != ""
    And the expression should be true> route('edgeroute').spec.tls_ca_certificate != ""

  # @author yanpzhan@redhat.com
  # @case_id OCP-21023
  Scenario: Create re-encrypt route from form
    Given the master version >= "4.1"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/service_secure.json |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.crt"
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.key"
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt.ca"
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    Then the step should succeed

    Given I open admin console in a browser

    When I perform the :goto_routes_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Create Route |
    Then the step should succeed

    When I perform the :create_route web action with:
      | route_name                 | reenroute            |
      | route_hostname             | reentest.example.com |
      | route_path                 | /test                |
      | service_name               | service-secure       |
      | target_port                | https                |
      | secure_route               | true                 |
      | tls_termination_type       | reencrypt            |
      | insecure_traffic_type      | Redirect             |
      | certificate_path           | <%= File.join(localhost.workdir, "route_reencrypt-reen.example.com.crt") %> |
      | private_key_path           | <%= File.join(localhost.workdir, "route_reencrypt-reen.example.com.key") %> |
      | ca_certificate_path        | <%= File.join(localhost.workdir, "route_reencrypt.ca") %>                   |
      | destination_ca_certificate | <%= File.join(localhost.workdir, "route_reencrypt_dest.ca") %>              |
    Then the step should succeed

    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Termination Type |
      | value | reencrypt        |
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Insecure Traffic |
      | value | Redirect         |
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Hostname             |
      | value | reentest.example.com |
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Path  |
      | value | /test |
    Then the step should succeed

    And the expression should be true> route('reenroute').spec.host == "reentest.example.com"
    And the expression should be true> route('reenroute').spec.path == "/test"
    And the expression should be true> route('reenroute').spec.target_port == "https"
    And the expression should be true> route('reenroute').spec.tls_termination == "reencrypt"
    And the expression should be true> route('reenroute').spec.tls_insecure_edge_termination_policy == "Redirect"
    And the expression should be true> route('reenroute').spec.tls_certificate != ""
    And the expression should be true> route('reenroute').spec.tls_key != ""
    And the expression should be true> route('reenroute').spec.tls_ca_certificate != ""
    And the expression should be true> route('reenroute').spec.tls_destination_ca_certificate != ""

  # @author xiaocwan
  # @case_id OCP-21461
  @admin
  Scenario: Check monitoring routes on console
    Given the master version >= "4.1"
    Given the first user is cluster-admin
    And I use the "openshift-monitoring" project
    And evaluation of `route('grafana').spec.host` is stored in the :route_grafana clipboard

    Given I open admin console in a browser
    When I perform the :expand_primary_menu web action with:
      | primary_menu | Monitoring |
    Then the step should succeed
    When I perform the :check_monitoring_urls web action with:
      | dashboards_grafana_route | <%= cb.route_grafana %> |
    Then the step should succeed
