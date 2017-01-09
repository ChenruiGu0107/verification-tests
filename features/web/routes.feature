Feature: Routes related features on web console
  # @author yanpzhan@redhat.com
  # @case_id 509106
  Scenario: Check Routes page
    Given I login via web console
    Given I have a project

    When I perform the :check_empty_routes_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed
    Given the "nodejs-sample-1" build was created
    Given the "nodejs-sample-1" build completed
    Given I wait for the "nodejs-sample" service to become ready
    And I wait for a web server to become available via the "nodejs-sample" route
    When I run the :get client command with:
      | resource      | route                 |
      | resource_name | nodejs-sample         |
      | template      | {{.spec.host}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :patch_yaml clipboard

    When I perform the :check_routes_page web console action with:
      | project_name | <%= project.name %> |
      | route_name   | nodejs-sample       |
    Then the step should succeed

    When I perform the :check_a_route_detail_page web console action with:
      | project_name | <%= project.name %> |
      | route_name   | nodejs-sample       |
      | service_name | nodejs-sample       |
    Then the step should succeed

    When I perform the :access_route_hostname web console action with:
      | project_name | <%= project.name %> |
      | route_name   | nodejs-sample       |
      | service_url | <%= cb.patch_yaml %>|
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 511915
  Scenario: Create unsecured route on web console
    When I create a new project via web
    Then the step should succeed

    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_nothing.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-unsecure   |
    Then the step should succeed

    When I perform the :create_unsecured_route_from_service_or_overview_page web console action with:
      | route_name | service-unsecure-route |
    Then the step should succeed

    When I perform the :check_routes_page web console action with:
      | project_name | <%= project.name %> |
      | route_name   | service-unsecure    |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id 511913
  Scenario: Create route for multi-port services on web console
    When I create a new project
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/multi-portsvc.json |
    Then the step should succeed
    When I perform the :check_empty_routes_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :create_route_dont_specify_hostname_from_routes_page web console action with:
      | service_name | multi-portsvc       |
      | route_name   | myroute1            |
      | target_port  | 443                 |
    Then the step should succeed
    When I perform the :create_route_dont_specify_hostname_from_routes_page web console action with:
      | project_name | <%= project.name %> |
      | service_name | multi-portsvc       |
      | route_name   | myroute2            |
      | target_port  | 80                  |
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
  # @case_id 511914
  Scenario: Create route with invalid name and hostname on web console
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_nothing.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-unsecure   |
    Then the step should succeed
    # set route name to invalid
    When I perform the :set_route_name web console action with:
      | route_name | GF-s68q |
    Then the step should succeed
    When I get the "disabled" attribute of the "button" web element:
      | text | Create |
    Then the output should contain "true"
    # set route host to invalid
    When I perform the :set_route_name web console action with:
      | route_name | testroute |
    Then the step should succeed
    When I perform the :set_hostname web console action with:
      | hostname | ah#$G |
    Then the step should succeed
    When I get the "disabled" attribute of the "button" web element:
      | text | Create |
    Then the output should contain "true"

  # @author yapei@redhat.com
  # @case_id 511911
  Scenario: Create passthrough terminated route on web console
    Given I create a new project
    And I store default router IPs in the :router_ip clipboard
    # create pod, service and pod used for curl command
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I execute on the pod:
      | wget |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem |
      | -O |
      | /tmp/ca.pem |
    Then the step should succeed
    # create passthrough route on web console
    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-secure     |
    Then the step should succeed
    When I perform the :set_hostname web console action with:
      | hostname | passthrough-<%= rand_str(5, :dns) %>.example.com |
    Then the step should succeed
    When I perform the :select_tls_termination_type web console action with:
      | tls_termination_type | Passthrough |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    # check route is accessible
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("service-secure", service("service-secure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("service-secure", service("service-secure")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"

  # @author yapei@redhat.com
  # @case_id 511906
  Scenario: Add path when creating edge terminated route on web cosnole
    Given I create a new project

    # create pod, service and pod used for curl command
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    # create edge route with path on web console
    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-unsecure   |
    Then the step should succeed
    When I perform the :create_route_with_path_and_policy_for_insecure_traffic web console action with:
      | route_name              | edgepathroute   |
      | hostname                | :null           |
      | path                    | /test           |
      | target_port             | 8080            |
      | tls_termination_type    | Edge            |
      | insecure_traffic_policy | None            |
    Then the step should succeed

    # check route function
    When I access the "https://<%= route("edgepathroute", service("edgepathroute")).dns(by: user) %>/test/" url in the web browser
    Then the step should succeed
    When I perform the :check_response_string web console action with:
      | response_string | Hello-OpenShift-Path-Test |
    Then the step should succeed
    When I access the "https://<%= route("edgepathroute", service("edgepathroute")).dns(by: user) %>/" url in the web browser
    Then the step should succeed
    When I perform the :check_response_string web console action with:
      | response_string | Application is not available |
    Then the step should succeed
    When I access the "https://<%= route("edgepathroute", service("edgepathroute")).dns(by: user) %>/none" url in the web browser
    Then the step should succeed
    When I perform the :check_response_string web console action with:
      | response_string | Application is not available |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id 511907
  Scenario: Create edge termianted route with redirect insecure traffic policy on web console
    Given I create a new project

    # create pod, service and pod used for curl command
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    # create edge route with policy for insecure traffic set to redirect
    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-unsecure   |
    Then the step should succeed
    When I perform the :create_unsecure_route_without_path web console action with:
      | route_name              | edgerouteredirect   |
      | hostname                | :null               |
      | target_port             | 8080                |
      | tls_termination_type    | Edge                |
      | insecure_traffic_policy | Redirect            |
    Then the step should succeed

    # check route function
    When I access the "http://<%= route("edgerouteredirect", service("service-unsecure")).dns(by: user) %>/" url in the web browser
    Then the step should succeed
    Given the expression should be true> browser.url.start_with? "https"
    When I perform the :check_response_string web console action with:
      | response_string | Hello-OpenShift |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id 511909
  Scenario: Create edge terminated route with allow insecure traffic policies on web console
    Given I create a new project

    # create pod, service and pod used for curl command
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    # create edge route with policy for insecure traffic set to allow
    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-unsecure   |
    Then the step should succeed
    When I perform the :create_unsecure_route_without_path web console action with:
      | route_name              | edgerouteallow      |
      | hostname                | :null               |
      | target_port             | 8080                |
      | tls_termination_type    | Edge                |
      | insecure_traffic_policy | Allow               |
    Then the step should succeed

    # check route function
    When I access the "http://<%= route("edgerouteallow", service("service-unsecure")).dns(by: user) %>/" url in the web browser
    Then the step should succeed
    When I perform the :check_response_string web console action with:
      | response_string | Hello-OpenShift |
    Then the step should succeed
    When I access the "https://<%= route("edgerouteallow", service("service-unsecure")).dns(by: user) %>/" url in the web browser
    Then the step should succeed
    When I perform the :check_response_string web console action with:
      | response_string | Hello-OpenShift |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 526534
  Scenario: Edit route on web console
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

   When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-unsecure   |
    Then the step should succeed

    When I perform the :create_unsecured_route_from_service_or_overview_page web console action with:
      | route_name | service-unsecure-route |
    Then the step should succeed

    When I perform the :cancel_edit_route_with_path web console action with:
      | project_name | <%= project.name%>   |
      | route_name | service-unsecure-route |
      | path       | /testone               |
    Then the step should succeed

    When I perform the :check_edit_route_with_invalid_path web console action with:
      | project_name | <%= project.name%>   |
      | route_name | service-unsecure-route |
      | path       | test123                |
    Then the step should succeed

    When I perform the :edit_route_with_hostname web console action with:
      | project_name | <%= project.name%>   |
      | route_name | service-unsecure-route |
      | hostname    | test.example.com      |
    Then the step should fail

    When I perform the :edit_route_to_tls_termination web console action with:
      | project_name | <%= project.name%>   |
      | route_name | service-unsecure-route |
      | tls_termination_type | Passthrough  |
      | termination_type | passthrough  |
    Then the step should succeed

    When I perform the :edit_route_to_other_tls_termination web console action with:
      | project_name | <%= project.name%>   |
      | route_name | service-unsecure-route |
      | tls_termination_type | Edge         |
      | termination_type |     edge         |
    Then the step should succeed

    When I perform the :edit_route_with_path web console action with:
      | project_name | <%= project.name%>   |
      | route_name | service-unsecure-route |
      | path       | /testtwo               |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 532706
  Scenario: Update route to point to multiple services
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json" replacing paths:
      | ["metadata"]["name"]           | caddy-docker-2 |
      | ["metadata"]["labels"]["name"] | caddy-docker-2 |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json" replacing paths:
      | ["metadata"]["name"]     | service-unsecure-2 |
      | ["spec"]["selector"]["name"] | caddy-docker-2 |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json" replacing paths:
      | ["metadata"]["name"]           | caddy-docker-3 |
      | ["metadata"]["labels"]["name"] | caddy-docker-3 |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json" replacing paths:
      | ["metadata"]["name"]     | service-unsecure-3 |
      | ["spec"]["selector"]["name"] | caddy-docker-3 |
    Then the step should succeed

    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-unsecure   |
    Then the step should succeed

    When I perform the :create_unsecured_route_from_service_or_overview_page web console action with:
      | route_name | service-unsecure-route |
    Then the step should succeed

    When I perform the :update_route_point_to_three_services web console action with:
      | project_name | <%= project.name%>    |
      | route_name  | service-unsecure-route |
      | first_svc_name  | service-unsecure   |
      | second_svc_name | service-unsecure-2 |
      | third_svc_name  | service-unsecure-3 |
      | weight_one   | 2                     |
      | weight_two   | 3                     |
      | weight_three | 5                     |
    Then the step should succeed

    When I perform the :remove_service_from_route web console action with:
      | project_name | <%= project.name%>    |
      | route_name  | service-unsecure-route |
      | rest_svc_number  | 2                 |
    Then the step should succeed

    When I perform the :remove_and_keep_one_service_for_route web console action with:
      | project_name | <%= project.name%>    |
      | route_name  | service-unsecure-route |
    Then the step should succeed

  # @author: yanpzhan@redhat.com
  # @case_id: 532705
  Scenario: Create route pointing to multiple services
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json" replacing paths:
      | ["metadata"]["name"]           | caddy-docker-2 |
      | ["metadata"]["labels"]["name"] | caddy-docker-2 |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json" replacing paths:
      | ["metadata"]["name"]     | service-unsecure-2 |
      | ["spec"]["selector"]["name"] | caddy-docker-2 |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json" replacing paths:
      | ["metadata"]["name"]           | caddy-docker-3 |
      | ["metadata"]["labels"]["name"] | caddy-docker-3 |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json" replacing paths:
      | ["metadata"]["name"]     | service-unsecure-3 |
      | ["spec"]["selector"]["name"] | caddy-docker-3 |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json" replacing paths:
      | ["metadata"]["name"]           | caddy-docker-4 |
      | ["metadata"]["labels"]["name"] | caddy-docker-4 |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json" replacing paths:
      | ["metadata"]["name"]     | service-unsecure-4 |
      | ["spec"]["selector"]["name"] | caddy-docker-4 |
    Then the step should succeed

    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-unsecure   |
    Then the step should succeed

    When I perform the :create_unsecured_route_pointing_to_four_services web console action with:
      | project_name    | <%= project.name%> |
      | route_name | service-unsecure-route  |
      | first_svc_name  | service-unsecure   |
      | second_svc_name | service-unsecure-2 |
      | third_svc_name  | service-unsecure-3 |
      | forth_svc_name  | service-unsecure-4 |
      | weight_one      | 3                  |
      | weight_two      | 6                  |
      | weight_three    | 3                  |
      | weight_four     | 12                 |
    Then the step should succeed

    When I perform the :check_update_weight_with_valid_value web console action with:
      | project_name    | <%= project.name%> |
      | route_name | service-unsecure-route  |
      | first_svc_name  | service-unsecure   |
      | second_svc_name | service-unsecure-2 |
      | weight_one      | 0                  |
      | weight_two      | 256                |
    Then the step should succeed

    When I perform the :check_update_weight_with_non_integer web console action with:
      | project_name    | <%= project.name%> |
      | route_name | service-unsecure-route  |
      | first_svc_name  | service-unsecure   |
      | second_svc_name | service-unsecure-2 |
      | third_svc_name  | service-unsecure-3 |
      | weight_one      | 2.2                |
      | weight_two      | fadd               |
      | weight_three    | -23                |
    Then the step should succeed

    When I perform the :check_update_weight_with_integer_out_of_range web console action with:
      | project_name    | <%= project.name%> |
      | route_name | service-unsecure-route  |
      | second_svc_name | service-unsecure-2 |
      | weight_two      | 257                |
    Then the step should succeed

    When I perform the :check_update_weight_with_empty_weight web console action with:
      | project_name    | <%= project.name%> |
      | route_name | service-unsecure-route  |
    Then the step should succeed

    When I perform the :check_update_route_with_duplicated_service web console action with:
      | project_name    | <%= project.name%> |
      | route_name | service-unsecure-route  |
      | second_svc_name | service-unsecure-3 |
      | weight_two      | 27                 |
    Then the step should succeed
