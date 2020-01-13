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
    When I perform the :check_resource_details web action with:
      | termination_type | passthrough |
      | insecure_traffic | Redirect    |
    Then the step should succeed

    And the expression should be true> route('passthroughroute').spec.tls_termination == "passthrough"
    And the expression should be true> route('passthroughroute').spec.tls_insecure_edge_termination_policy == "Redirect"

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

    When I perform the :check_resource_details web action with:
      | termination_type | edge                 |
      | insecure_traffic | Allow                |
      | hostname         | edgetest.example.com |
      | path             | /test                |
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

    When I perform the :check_resource_details web action with:
      | termination_type | reencrypt            |
      | insecure_traffic | Redirect             |
      | hostname         | reentest.example.com |
      | path             | /test                |
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

  # @author xiaocwan@redhat.com
  # @case_id OCP-21461
  @admin
  Scenario: Check monitoring routes on console
    Given the master version >= "4.1"
    Given I open admin console in a browser
    Given the first user is cluster-admin
    And I use the "openshift-monitoring" project
    When I run the :goto_node_page web action
    Then the step should succeed
    When I perform the :expand_primary_menu web action with:
      | primary_menu | Monitoring |
    Then the step should succeed
    When I perform the :check_monitoring_urls web action with:
      | alert_ui_route           | <%= route('alertmanager-main').spec.host %> |
      | prometheus_ui_route      | <%= route('prometheus-k8s').spec.host %>    |
      | dashboards_grafana_route | <%= route('grafana').spec.host %>           |
    Then the step should succeed
 
  # @author yanpzhan@redhat.com
  # @case_id OCP-23580
  Scenario: Check canonical router hostname and popover help
    Given the master version >= "4.2"
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                 |
      | code         | https://github.com/sclorg/django-ex.git |
      | name         | python-sample                           |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | svc           |
      | resource_name | python-sample |
    Then the step should succeed
    Given I open admin console in a browser
    Given I store default router subdomain in the :subdomain clipboard
    When I perform the :goto_one_route_page web action with:
      | project_name | <%= project.name %> |
      | route_name   | python-sample       |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | canonical_hostname | <%= cb.subdomain %> |
    Then the step should succeed

    When I run the :annotate client command with:
      | resource     | route                               |
      | resourcename | python-sample                       |
      | keyval       | openshift.io/host.generated='false' |
      | overwrite    | true                                |
    Then the step should succeed

    When I run the :check_custom_dns_help_link web action
    Then the step should succeed
    When I run the :open_custom_dns_help_modal web action
    Then the step should succeed
    When I run the :check_custom_dns_help_info web action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-26170
  Scenario: Support create route with multiple services
    Given the master version >= "4.3"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure.json   |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-2.json |
    Then the step should succeed

    # create route with multiple services
    Given I open admin console in a browser
    When I perform the :goto_routes_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :click_create_route_button web action
    Then the step should succeed
    When I perform the :create_route web action with:
      | route_name                 | mytestroute        |
      | service_name               | service-unsecure   |
      | service_weight             | 30                 |
      | alternative_service_name   | service-unsecure-2 |
      | alternative_service_weight | 70                 |
      | target_port                | http               |
    Then the step should succeed

    # check Traffic table is shown
    When I run the :check_route_traffic_table_shown web action
    Then the step should succeed

    # check data in Traffic table
    When I perform the :check_data_in_traffic_table web action with:
      | resource_type | Service          |
      | resource_name | service-unsecure |
      | resource_link | /k8s/ns/<%= project.name %>/services/service-unsecure |
      | weight        | 30               |
      | percent       | 30.0%            |
    Then the step should succeed
    When I perform the :check_data_in_traffic_table web action with:
      | resource_type | Service            |
      | resource_name | service-unsecure-2 |
      | resource_link | /k8s/ns/<%= project.name %>/services/service-unsecure-2 |
      | weight        | 70                 |
      | percent       | 70.0%              |
    Then the step should succeed

    # Remove Alternative Service will remove entry for alternative service
    When I perform the :goto_route_creation_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :set_service_name web action with:
      | service_name | service-unsecure |
    Then the step should succeed
    When I run the :click_add_alternative_service web action
    Then the step should succeed
    When I run the :check_inputs_for_alternative_services_exists web action
    Then the step should succeed
    When I run the :click_remove_alternative_service web action
    Then the step should succeed
    When I run the :check_inputs_for_alternative_services_missing web action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-26040
  @admin
  Scenario: Check metrics charts on route page
    Given the master version >= "4.3"
    Given the first user is cluster-admin
    Given I open admin console in a browser
    When I perform the :goto_one_route_page web action with:
      | project_name | openshift-console |
      | route_name   | console           |
    Then the step should succeed
    When I run the :check_metrics_charts_on_route_overview web action
    Then the step should succeed
