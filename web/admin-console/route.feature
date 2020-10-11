Feature: route related

  # @author yanpzhan@redhat.com
  # @case_id OCP-21004
  Scenario: Create Passthrough route from form
    Given the master version >= "4.1"
    Given I have a project
    Given I obtain test data file "routing/caddy-docker-2.json"
    When I run the :create client command with:
      | f | caddy-docker-2.json |
    Then the step should succeed
    Given I obtain test data file "routing/passthrough/service_secure.json"
    When I run the :create client command with:
      | f | service_secure.json |
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
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    Given I obtain test data file "routing/edge/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed

    Given I open admin console in a browser

    When I perform the :goto_routes_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Create Route |
    Then the step should succeed

    Given I obtain test data file "routing/edge/route_edge-www.edge.com.crt"
    Given I obtain test data file "routing/edge/route_edge-www.edge.com.key"
    Given I obtain test data file "routing/ca.pem"
    When I perform the :create_route web action with:
      | route_name            | edgeroute            |
      | route_hostname        | edgetest.example.com |
      | route_path            | /test                |
      | service_name          | service-unsecure     |
      | target_port           | http                 |
      | secure_route          | true                 |
      | tls_termination_type  | edge                 |
      | insecure_traffic_type | Allow                |
      | certificate_path      | <%= localhost.absolutize("route_edge-www.edge.com.crt") %> |
      | private_key_path      | <%= localhost.absolutize("route_edge-www.edge.com.key") %> |
      | ca_certificate_path   | <%= localhost.absolutize("ca.pem") %>                      |
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
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    Given I obtain test data file "routing/reencrypt/service_secure.json"
    When I run the :create client command with:
      | f | service_secure.json |
    Then the step should succeed

    Given I open admin console in a browser

    When I perform the :goto_routes_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Create Route |
    Then the step should succeed

    Given I obtain test data file "routing/reencrypt/route_reencrypt-reen.example.com.crt"
    Given I obtain test data file "routing/reencrypt/route_reencrypt-reen.example.com.key"
    Given I obtain test data file "routing/reencrypt/route_reencrypt.ca"
    Given I obtain test data file "routing/reencrypt/route_reencrypt_dest.ca"
    When I perform the :create_route web action with:
      | route_name                 | reenroute            |
      | route_hostname             | reentest.example.com |
      | route_path                 | /test                |
      | service_name               | service-secure       |
      | target_port                | https                |
      | secure_route               | true                 |
      | tls_termination_type       | reencrypt            |
      | insecure_traffic_type      | Redirect             |
      | certificate_path           | <%= localhost.absolutize("route_reencrypt-reen.example.com.crt") %> |
      | private_key_path           | <%= localhost.absolutize("route_reencrypt-reen.example.com.key") %> |
      | ca_certificate_path        | <%= localhost.absolutize("route_reencrypt.ca") %>                   |
      | destination_ca_certificate | <%= localhost.absolutize("route_reencrypt_dest.ca") %>              |
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
    Given the first user is cluster-admin
    And I use the "openshift-monitoring" project
    Given I open admin console in a browser
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
    Given I wait for the "python-sample" service to be created
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
    Given I obtain test data file "routing/abrouting/unseucre/service_unsecure.json"
    Given I obtain test data file "routing/abrouting/unseucre/service_unsecure-2.json"
    When I run the :create client command with:
      | f | service_unsecure.json   |
      | f | service_unsecure-2.json |
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

  # @author xiaocwan@redhat.com
  # @case_id OCP-25802
  @admin
  Scenario: Download oc for multiple OS
    Given the master version >= "4.3"
    Given default admin-console downloads route is stored in the clipboard
    Given I open admin console in a browser
    When I run the :goto_cli_tools_page web action
    Then the step should succeed
    When I perform the :check_default_oc_download_links web action with:
      | downloads_route | <%= cb.downloads_route %> |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-19608
  Scenario: Check route list and detail page
    Given the master version >= "4.1"
    Given I have a project
    Given I obtain test data file "routing/edge/service_unsecure.json"
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
      | f | caddy-docker.json          |
    Then the step should succeed

    # create two routes, one is created from default YAML, the other is created by form
    Given I open admin console in a browser
    When I perform the :goto_routes_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :create_resource_by_default_yaml web action
    Then the step should succeed
    Given I wait for the "service-unsecure" service to become ready
    When I perform the :goto_route_creation_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    Given I obtain test data file "routing/tc/OCP-19608/example.crt"
    Given I obtain test data file "routing/tc/OCP-19608/example.key"
    Given I obtain test data file "routing/tc/OCP-19608/example.csr"
    When I perform the :create_route web action with:
      | route_name            | mytestroute      |
      | service_name          | service-unsecure |
      | target_port           | http             |
      | secure_route          | true             |
      | tls_termination_type  | edge             |
      | insecure_traffic_type | Redirect         |
      | certificate_path      | <%= localhost.absolutize("example.crt") %> |
      | private_key_path      | <%= localhost.absolutize("example.key") %> |
      | ca_certificate_path   | <%= localhost.absolutize("example.csr") %> |
    Then the step should succeed
    # create one more route by form to make 3 routes in total
    When I perform the :goto_route_creation_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :create_route web action with:
      | route_name   | mybasicroute     |
      | service_name | service-unsecure |
      | target_port  | http             |
    Then the step should succeed
    # to make sure all required routes are created
    Given I wait up to 10 seconds for the steps to pass:
    """
    When I get project routes
    Then the output should contain:
      | example     |
      | mytestroute |
      | mybasicroute|
    """

    # check basic route is reachable.
    Given I store default router subdomain in the :subdomain clipboard
    When I open web server via the "http://mybasicroute-<%= project.name %>.<%= cb.subdomain %>" url
    Then the output should contain "Hello-OpenShift-1 http-8080"

    # check Status, status icon and condition table on route details
    When I perform the :goto_one_route_page web action with:
      | project_name | <%= project.name %> |
      | route_name   | mytestroute         |
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Status   |
      | value | Rejected |
    Then the step should succeed
    When I run the :check_rejected_icon_and_text web action
    Then the step should succeed
    When I perform the :check_extendedValidationFailed_in_conditions_table web action with:
      | type | Admitted |
    Then the step should succeed

    # filtering with route status
    When I perform the :goto_routes_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :filter_and_show_accepted_routes web action
    Then the step should succeed
    When I perform the :check_route_name_and_icon web action with:
      | route_name | example |
    Then the step should succeed
    When I perform the :check_route_name_and_icon web action with:
      | route_name | mytestroute |
    Then the step should fail
    When I run the :select_all_filters web action
    Then the step should succeed
    When I run the :filter_and_show_rejected_routes web action
    Then the step should succeed
    When I perform the :check_route_name_and_icon web action with:
      | route_name | mytestroute |
    Then the step should succeed
    When I perform the :check_route_name_and_icon web action with:
      | route_name | example |
    Then the step should fail
    When I run the :select_all_filters web action
    Then the step should succeed

    # filtering with route name
    When I perform the :set_filter_strings web action with:
      | filter_text | example |
    Then the step should succeed
    When I perform the :check_route_name_and_icon web action with:
      | route_name | example |
    Then the step should succeed
    When I perform the :check_route_name_and_icon web action with:
      | route_name | mytestroute |
    Then the step should fail

  # @author xiaocwan@redhat.com
  # @case_id OCP-33744
  @admin
  Scenario: Web Security checks
    Given the master version >= "4.6"
    # check the oauthaccesstoken by web console
    Given I open admin console in a browser
    When I run the :get admin command with:
      | resource | oauthaccesstoken                                                    |
      | o        | custom-columns=user:.userName,client:.clientName,name:metadata.name |
    Then the step should succeed
    And the output should match "<%= user.name %>.*console"
    Given evaluation of `user.cached_tokens.first` is stored in the :user_token clipboard

    # check the download route page
    Given default admin-console downloads route is stored in the clipboard
    When I access the "https://<%= cb.downloads_route %>" url in the web browser
    When I run the :check_items_on_downloads_route_page web action
    Then the step should succeed
    When I get the html of the web page
    And the output should not match "Directory listing"

    When I perform the :goto_routes_page web action with:
      | project_name | openshift-console |
    Then the step should succeed
    When I run the :click_logout web action
    Then the step should succeed
    When I run the :get admin command with:
      | resource | oauthaccesstoken                                                    |
      | o        | custom-columns=user:.userName,client:.clientName,name:metadata.name |
    Then the step should succeed
    And the output should not match "<%= user.name %>.*console.*<%= cb.user_token %>"
