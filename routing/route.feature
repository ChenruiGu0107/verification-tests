Feature: Testing route

  # @author zzhao@redhat.com
  # @case_id OCP-11883
  @smoke
  Scenario: Be able to add more alias for service
    Given I have a project
    Given I obtain test data file "routing/header-test/dc.json"
    When I run the :create client command with:
      | f  |  dc.json |
    Then the step should succeed
    Given I obtain test data file "routing/header-test/insecure-service.json"
    When I run the :create client command with:
      | f  | insecure-service.json |
    Then the step should succeed
    When I expose the "header-test-insecure" service
    Then the step should succeed
    And I wait for a web server to become available via the route
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | service          |
      | resource_name | header-test-insecure |
      | name          | header-test-insecure-dup |
    Then the step should succeed
    Then I wait for a web server to become available via the "header-test-insecure-dup" route

  # @author xxia@redhat.com
  # @case_id OCP-12563
  @admin
  Scenario: The certs for the edge/reencrypt termination routes should be removed when the routes removed
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    Given I obtain test data file "routing/reencrypt/route_reencrypt.json"
    When I run oc create over "route_reencrypt.json" replacing paths:
      | ["spec"]["host"]  | www.<%= rand_str(5, :dns) %>.example.com |
    Then the step should succeed
    Given I obtain test data file "routing/edge/route_edge.json"
    When I run oc create over "route_edge.json" replacing paths:
      | ["spec"]["host"]  | www.<%= rand_str(5, :dns) %>.example.com |
    Then the step should succeed

    Then evaluation of `project.name` is stored in the :proj_name clipboard
    And evaluation of `"secured-edge-route"` is stored in the :edge_route clipboard
    And evaluation of `"route-reencrypt"` is stored in the :reencrypt_route clipboard

    When I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash |
      | -lc |
      | ls /var/lib/*/router/certs |
    Then the step should succeed
    And the output should match:
      | <%= cb.proj_name %>[_:]<%= cb.edge_route %>.pem |
      | <%= cb.proj_name %>[_:]<%= cb.reencrypt_route %>.pem |
    """
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -lc |
      | ls /var/lib/*/router/cacerts |
    Then the step should succeed
    And the output should match:
      | <%= cb.proj_name %>[_:]<%= cb.reencrypt_route %>.pem |
    """

    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    When I run the :delete client command with:
      | object_type       | route                |
      | object_name_or_id | <%= cb.edge_route %> |
    Then the step should succeed
    When I wait for the resource "route" named "<%= cb.edge_route %>" to disappear
    And I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -lc |
      | ls /var/lib/*/router/certs |
    Then the step should succeed
    And the output should not match:
      | <%= cb.proj_name %>[_:]<%= cb.edge_route %>.pem |
    And the output should match:
      | <%= cb.proj_name %>[_:]<%= cb.reencrypt_route %>.pem |
    """

    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    When I run the :delete client command with:
      | object_type       | route                     |
      | object_name_or_id | <%= cb.reencrypt_route %> |
    Then the step should succeed
    When I wait for the resource "route" named "<%= cb.reencrypt_route %>" to disappear
    And I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -lc |
      | ls /var/lib/*/router/certs /var/lib/*/router/cacerts |
    Then the step should succeed
    And the output should not match:
      | <%= cb.proj_name %>[_:]<%= cb.reencrypt_route %>.pem |
    """

  # @author zzhao@redhat.com
  # @case_id OCP-10762
  Scenario: Check the header forward format
    Given I have a project
    Given I obtain test data file "routing/header-test/dc.json"
    When I run the :create client command with:
      | f  |  dc.json |
    Then the step should succeed
    Given I obtain test data file "routing/header-test/insecure-service.json"
    When I run the :create client command with:
      | f  | insecure-service.json |
    Then the step should succeed
    When I expose the "header-test-insecure" service
    Then the step should succeed
    When I wait for a web server to become available via the route
    Then the output should contain ";host=<%= route.dns(by: user) %>;proto=http"

  # @author yadu@redhat.com
  # @case_id OCP-9717
  Scenario: Config insecureEdgeTerminationPolicy to an invalid value for route
    Given I have a project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name    | myroute          |
      | service | service-unsecure |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | route                                                    |
      | resource_name | myroute                                                  |
      | p             | {"spec":{"tls":{"insecureEdgeTerminationPolicy":"Abc"}}} |
    And the output should contain:
      | invalid value for InsecureEdgeTerminationPolicy option, acceptable values are None, Allow, Redirect, or empty |

  # @author zzhao@redhat.com
  # @case_id OCP-12575
  Scenario: The path specified in route can work well for unsecure
    Given I have a project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | service          |
      | resource_name | service-unsecure |
      | path          | /test            |
    Then the step should succeed
    Given evaluation of `route("service-unsecure", service("service-unsecure")).dns(by: user)` is stored in the :unsecure clipboard
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= cb.unsecure %>/test/" url
    Then the output should contain "Hello-OpenShift-Path-Test"
    """
    When I open web server via the "http://<%= cb.unsecure %>/" url
    Then the step should fail
    When I run the :delete client command with:
      | object_type       | route            |
      | object_name_or_id | service-unsecure |
    Then the step should succeed
    # make sure the route is deleted and not accessible
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= cb.unsecure %>/test/" url
    Then the output should not contain "Hello-OpenShift-Path-Test"
    """
    When I run the :expose client command with:
      | resource      | service          |
      | resource_name | service-unsecure |
    Then the step should succeed
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route.dns(by: user) %>/test/" url
    Then the output should contain "Hello-OpenShift-Path-Test"
    """
    And I wait up to 20 seconds for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"

    #Create one path with slash at the end
    When I run the :expose client command with:
      | resource      | service          |
      | resource_name | service-unsecure |
      | path          | /                |
      | name          | slash-test       |
    Then the step should succeed
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route("slash-test", service("service-unsecure")).dns(by: user) %>/test/" url
    Then the output should contain "Hello-OpenShift-Path-Test"
    """
    And I wait up to 20 seconds for a web server to become available via the "slash-test" route
    Then the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-12506
  Scenario: Re-encrypting route with no cert if a router is configured with a default wildcard cert
    Given I have a project
    And I store an available router IP in the :router_ip clipboard
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    Given I obtain test data file "routing/reencrypt/service_secure.json"
    When I run the :create client command with:
      | f | service_secure.json |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    Given I obtain test data file "routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | no-cert                                                                                         |
      | hostname   | <%= rand_str(5, :dns) %>-reen.example.com                                                       |
      | service    | service-secure                                                                                  |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("no-cert", service("no-cert")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("no-cert", service("no-cert")).dns(by: user) %>/ |
      | -k |
    Then the output should contain "Hello-OpenShift"
    """

  # @author yadu@redhat.com
  # @case_id OCP-12556
  Scenario: Create a route without host named
    Given I have a project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    Given I obtain test data file "routing/tc/tc470732/route_withouthost1.json"
    When I run the :create client command with:
      | f | route_withouthost1.json |
    Then the step should succeed
    When I use the "service-unsecure" service
    Then I wait for a web server to become available via the "service-unsecure1" route
    Then the output should contain "Hello-OpenShift"
    Given I obtain test data file "routing/tc/tc470732/route_withouthost2.json"
    When I run the :create client command with:
      | f | route_withouthost2.json |
    Then the step should succeed
    When I use the "service-unsecure" service
    Then I wait for a web server to become available via the "service-unsecure2" route
    Then the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-12566
  Scenario: Cookie name should not use openshift prefix
    Given I have a project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    Given I have a pod-for-ping in the project
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | <%= route.dns(by: user) %> |
      | -c |
      | /tmp/cookie |
    Then the output should contain "Hello-OpenShift"
    """
    And I execute on the pod:
      | cat |
      | /tmp/cookie |
    Then the step should succeed
    And the output should not contain "OPENSHIFT"
    And the output should not match "\d+\.\d+\.\d+\.\d+"

  # @author zzhao@redhat.com
  # @case_id OCP-11325
  Scenario: Limit the number of http request per ip
    Given I have a project
    And I store an available router IP in the :router_ip clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=test-pods |
    When I expose the "test-service" service
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | -c | for i in {1..5} ; do curl --resolve <%= route.dns(by: user) %>:80:<%= cb.router_ip[0] %> http://<%= route.dns(by: user) %>/ ; done |
    Then the output should contain "Hello OpenShift"
    And the output should not contain "Empty reply from server"
    When I run the :annotate client command with:
      | resource     | route                                                           |
      | resourcename | test-service                                                    |
      | keyval       | haproxy.router.openshift.io/rate-limit-connections=true         |
      | keyval       | haproxy.router.openshift.io/rate-limit-connections.rate-http=2  |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | for i in {1..5} ; do curl --resolve <%= route.dns(by: user) %>:80:<%= cb.router_ip[0] %> http://<%= route.dns(by: user) %>/ ; done |
    Then the output should contain:
      | Hello OpenShift |
      | Empty reply from server |
    """

  # @author zzhao@redhat.com
  # @case_id OCP-12573
  # @note requires v3.4+
  Scenario: Default haproxy router should be able to skip invalid cert route
    Given I have a project
    And I store an available router IP in the :router_ip clipboard
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    Given I obtain test data file "routing/edge/route_edge-www.edge.com.crt"
    Given I obtain test data file "routing/edge/route_edge-www.edge.com.key"
    Given I obtain test data file "routing/ca.pem"
    When I run the :create_route_edge client command with:
      | name     | edge-route                                                                                     |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com                                                      |
      | service  | service-unsecure                                                                               |
      | cert     | route_edge-www.edge.com.crt |
      | key      | route_edge-www.edge.com.key |
      | cacert   | ca.pem                           |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca-test.pem |
    Then the output should contain "Hello-OpenShift"
    """
    #create some invalid route
    Given I obtain test data file "routing/invalid_route/edge/route_edge_expire.json"
    Given I obtain test data file "routing/invalid_route/edge/route_edge_invalid_ca.json"
    Given I obtain test data file "routing/invalid_route/edge/route_edge_invalid_key.json"
    Given I obtain test data file "routing/invalid_route/edge/route_edge_invalid_cert.json"
    Given I obtain test data file "routing/invalid_route/edge/route_edge_noca.json"
    Given I obtain test data file "routing/invalid_route/reen/route_reencrypt_invalid_ca.json"
    Given I obtain test data file "routing/invalid_route/reen/route_reencrypt_invalid_cert.json"
    Given I obtain test data file "routing/invalid_route/reen/route_reencrypt_invalid_key.json"
    Given I obtain test data file "routing/invalid_route/reen/route_reencrypt_invalid_desca.json"
    Given I obtain test data file "routing/invalid_route/reen/route_reencry.json"
    When I run the :create client command with:
      | f | route_edge_expire.json |
      | f | route_edge_invalid_ca.json |
      | f | route_edge_invalid_key.json |
      | f | route_edge_invalid_cert.json |
      | f | route_edge_noca.json |
      | f | route_reencrypt_invalid_ca.json |
      | f | route_reencrypt_invalid_cert.json |
      | f | route_reencrypt_invalid_key.json |
      | f | route_reencrypt_invalid_desca.json |
      | f | route_reencry.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | route |
    Then the output should contain 7 times:
      | ExtendedValidationFailed |

    #create one normal reencyption route to check if it can work after those invalid route
    Given I obtain test data file "routing/reencrypt/service_secure.json"
    When I run the :create client command with:
      | f | service_secure.json |
    Then the step should succeed

    Given I obtain test data file "routing/reencrypt/route_reencrypt-reen.example.com.crt"
    Given I obtain test data file "routing/reencrypt/route_reencrypt-reen.example.com.key"
    Given I obtain test data file "routing/reencrypt/route_reencrypt.ca"
    Given I obtain test data file "routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | route-recrypt                                                                                                |
      | hostname   | <%= rand_str(5, :dns) %>-reen.example.com                                                                    |
      | service    | service-secure                                                                                               |
      | cert       | route_reencrypt-reen.example.com.crt |
      | key        | route_reencrypt-reen.example.com.key |
      | cacert     | route_reencrypt.ca                   |
      | destcacert | route_reencrypt_dest.ca              |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca-test.pem |
    Then the output should contain "Hello-OpenShift"
    """

  # @author yadu@redhat.com
  # @case_id OCP-10545
  Scenario: Generated route host DNS segment should not exceed 63 characters
    Given a 47 characters random string of type :dns is stored into the :proj_name1 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name1 %> |
    Then the step should succeed
    When I use the "<%= cb.proj_name1 %>" project
    Then the step should succeed
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | route |
    Then the step should succeed
    And the output should contain "InvalidHost"
    """
    When I delete the project
    Then the step should succeed

    Given a 46 characters random string of type :dns is stored into the :proj_name2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name2 %> |
    Then the step should succeed
    When I use the "<%= cb.proj_name2 %>" project
    Then the step should succeed
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    And I wait for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-13254
  Scenario: The HTTP_X_FORWARDED_FOR should be the client IP for ELB env
    Given I have a project
    Given I obtain test data file "routing/header-test/dc.json"
    When I run the :create client command with:
      | f | dc.json |
    Then the step should succeed
    Given I obtain test data file "routing/header-test/insecure-service.json"
    When I run the :create client command with:
      | f | insecure-service.json |
    Then the step should succeed
    Given I have a pod-for-ping in the project

    #Get the client ip by access the url icanhazip.com
    When I execute on the pod:
      | bash | -c | curl -sS icanhazip.com |
    Then the step should succeed
    And evaluation of `@result[:response].strip` is stored in the :client_ip clipboard

    When I expose the "header-test-insecure" service
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | curl http://<%= route("header-test-insecure", service("header-test-insecure")).dns(by: user) %> |
    Then the step should succeed
    And the output should contain "x-forwarded-for: <%= cb.client_ip %>"
    """
    #Create the edge route
    When I run the :create_route_edge client command with:
      | name     | myroute              |
      | service  | header-test-insecure |
    Then the step should succeed

    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | curl https://<%= route("myroute", service("header-test-insecure")).dns(by: user) %> -k |
    Then the step should succeed
    And the output should contain:
      | x-forwarded-for: <%= cb.client_ip %> |
    """

  # @author zzhao@redhat.com
  # @case_id OCP-14089
  Scenario: route cannot be accessed if the backend cannot be matched the the default destination CA of router
    Given I have a project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    Given I obtain test data file "routing/reencrypt/service_secure.json"
    When I run the :create client command with:
      | f | service_secure.json |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I run the :create_route_reencrypt client command with:
      | name | route-reencrypt |
      | service | service-secure |
    Then the step should succeed
    Given 10 seconds have passed
    #since the haproxy is using 'service.project.svc' to verify the hostname. but the pod caddy is using '*.example.com'. so it cannot match and will return 503 error.
    When I execute on the pod:
      | curl                                                                              |
      | -I                                                                                |
      | https://<%= route("route-reencrypt", service("service-secure")).dns(by: user) %>/ |
      | -k                                                                                |
    Then the step should succeed
    And the output should match "HTTP.* 503"

  # @author zzhao@redhat.com
  # @case_id OCP-15028
  Scenario: The router can do a case-insensitive match of a hostname for unsecure route
    Given the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "routing/wildcard_route/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready

    #Create the unsecure service
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed

    #Create the unsecure route
    When I run the :expose client command with:
      | resource      | service          |
      | resource_name | service-unsecure |
    Then the step should succeed
    #access the route using capitals words
    And I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user).upcase %>" url
    And the output should contain "Hello-OpenShift-1 http-8080"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-15071
  Scenario: The router can do a case-insensitive match of a hostname for edge route
    Given the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "routing/wildcard_route/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready

    #Create the unsecure service
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    #Create the edge route
    When I run the :create_route_edge client command with:
      | name    | route-edge       |
      | service | service-unsecure |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= route("route-edge", service("service-unsecure")).dns(by: user).upcase %>" url
    And the output should contain "Hello-OpenShift-1 http-8080"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-15072
  Scenario: The router can do a case-insensitive match of a hostname for passthrough route
    Given the master version >= "3.6"
    Given I have a project
    And I store an available router IP in the :router_ip clipboard
    Given I obtain test data file "routing/wildcard_route/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready

    #Create the secure service
    Given I obtain test data file "routing/passthrough/service_secure.json"
    When I run the :create client command with:
      | f | service_secure.json |
    Then the step should succeed
    #Create passthrough route
    When I run the :create_route_passthrough client command with:
      | name    | route-pass     |
      | service | service-secure |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= route("route-pass", service("service-secure")).dns(by: user).upcase %>" url
    And the output should contain "Hello-OpenShift-1 https-8443"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-15073
  Scenario: The router can do a case-insensitive match of a hostname for reencrypt route
    Given the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "routing/reencrypt/reencrypt-without-all-cert.yaml"
    When I run the :create client command with:
      | f | reencrypt-without-all-cert.yaml |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready

    And I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= route("route-reencrypt", service("service-secure")).dns(by: user).upcase %>" url
    And the output should contain "Hello-OpenShift"
    """

  # @author yadu@redhat.com
  # @case_id OCP-14679
  Scenario: Only the host in whitelist could access the route - edge routes
    Given I have a project
    And I have a header test service in the project
    And evaluation of `"haproxy.router.openshift.io/ip_whitelist=#{cb.req_headers["x-forwarded-for"]}"` is stored in the :my_whitelist clipboard
    When I run the :create_route_edge client command with:
      | name    | edge-route           |
      | service | header-test-insecure |
    Then the step should succeed

    # Add another IP whitelist for route
    When I run the :annotate client command with:
      | resource     | route                                            |
      | resourcename | edge-route                                       |
      | keyval       | haproxy.router.openshift.io/ip_whitelist=8.8.8.8 |
      | overwrite    | true                                             |
    Then the step should succeed
    Then I wait up to 20 seconds for the steps to pass:
    """
    When I open secure web server via the "edge-route" route
    Then the step should fail
    """

    # Add IP whitelist for route
    When I run the :annotate client command with:
      | resource     | route                   |
      | resourcename | edge-route              |
      | keyval       | <%= cb.my_whitelist %>  |
      | overwrite    | true                    |
    Then the step should succeed
    When I wait for a secure web server to become available via the "edge-route" route
    Then the step should succeed
    And the output should contain "x-forwarded-for"


  # @author yadu@redhat.com
  # @case_id OCP-14685
  Scenario: Only the host in whitelist could access the route - passthrough routes
    Given I have a project
    And I have a header test service in the project
    And evaluation of `"haproxy.router.openshift.io/ip_whitelist=#{cb.req_headers["x-forwarded-for"]}"` is stored in the :my_whitelist clipboard
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    Given I obtain test data file "routing/passthrough/service_secure.json"
    When I run the :create client command with:
      | f | service_secure.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name    | pass-route       |
      | service | service-secure |
    Then the step should succeed

    # Add another IP whitelist for route
    When I run the :annotate client command with:
      | resource     | route                                            |
      | resourcename | pass-route                                       |
      | keyval       | haproxy.router.openshift.io/ip_whitelist=8.8.8.8 |
      | overwrite    | true                                             |
    Then the step should succeed
    Then I wait up to 20 seconds for the steps to pass:
    """
    When I open secure web server via the "pass-route" route
    Then the step should fail
    """

    # Add IP whitelist for route
    When I run the :annotate client command with:
      | resource     | route                   |
      | resourcename | pass-route              |
      | keyval       | <%= cb.my_whitelist %>  |
      | overwrite    | true                    |
    Then the step should succeed
    When I wait for a secure web server to become available via the "pass-route" route
    And the output should contain "Hello-OpenShift"


  # @author yadu@redhat.com
  # @case_id OCP-14684
  Scenario: Only the host in whitelist could access the route - reencrypt routes
    Given I have a project
    And I have a header test service in the project
    And evaluation of `"haproxy.router.openshift.io/ip_whitelist=#{cb.req_headers["x-forwarded-for"]}"` is stored in the :my_whitelist clipboard
    Given I obtain test data file "routing/header-test/secure-service.json"
    When I run the :create client command with:
      | f | secure-service.json |
    Then the step should succeed
    Given I obtain test data file "routing/header-test/head-test.pem"
    When I run the :create_route_reencrypt client command with:
      | name       | reen-route                                                                              |
      | service    | header-test-secure                                                                      |
      | destcacert | head-test.pem |
    Then the step should succeed
    # Add another IP whitelist for route
    When I run the :annotate client command with:
      | resource     | route                                            |
      | resourcename | reen-route                                       |
      | keyval       | haproxy.router.openshift.io/ip_whitelist=8.8.8.8 |
      | overwrite    | true                                             |
    Then the step should succeed
    Then I wait up to 20 seconds for the steps to pass:
    """
    When I open secure web server via the "reen-route" route
    Then the step should fail
    """

    # Add IP whitelist for route
    When I run the :annotate client command with:
      | resource     | route                   |
      | resourcename | reen-route              |
      | keyval       | <%= cb.my_whitelist %>  |
      | overwrite    | true                    |
    Then the step should succeed
    When I wait for a secure web server to become available via the "reen-route" route
    And the output should contain "x-forwarded-for"


  # @author yadu@redhat.com
  # @case_id OCP-14680
  Scenario: Add invalid value in annotation whitelist to routes
    Given I have a project
    And I have a header test service in the project
    And evaluation of `"haproxy.router.openshift.io/ip_whitelist=#{cb.req_headers["x-forwarded-for"]}"` is stored in the :my_whitelist clipboard

    # Add 0.0.0.0/32 in whitelist
    When I run the :annotate client command with:
      | resource     | route                                               |
      | resourcename | <%= cb.header_test_svc.name %>                      |
      | keyval       | haproxy.router.openshift.io/ip_whitelist=0.0.0.0/32 |
      | overwrite    | true                                                |
    Then the step should succeed
    # All host could not access the route
    Then I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the route
    Then the step should fail
    """

    # Add 0.0.0.0/0 in whitelist
    When I run the :annotate client command with:
      | resource     | route                                               |
      | resourcename | <%= cb.header_test_svc.name %>                      |
      | keyval       | haproxy.router.openshift.io/ip_whitelist=0.0.0.0/0  |
      | overwrite    | true                                                |
    Then the step should succeed
    # All host could access the route
    When I wait for a web server to become available via the route
    Then the output should contain "x-forwarded-for"

    # Add invalid IP in whitelist
    When I run the :annotate client command with:
      | resource     | route                                               |
      | resourcename | <%= cb.header_test_svc.name %>                      |
      | keyval       | haproxy.router.openshift.io/ip_whitelist=0.0.0.a/b  |
      | overwrite    | true                                                |
    Then the step should succeed
    # The whitelist will not take effect
    When I wait for a web server to become available via the route
    Then the output should contain "x-forwarded-for"


  # @author zzhao@redhat.com
  # @case_id OCP-15113
  Scenario: Harden haproxy to prevent the PROXY header from being passed for unsecure route
    Given the master version >= "3.6"
    And I have a project
    Given I have a header test service in the project
    And I have a pod-for-ping in the project
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -H   |
      | proxy:10.10.10.10 |
      | http://<%= route.dns(by: user) %> |
    Then the step should succeed
    And the output should contain "host: <%= route.dns(by: user) %>"
    And the output should not contain "proxy: 10.10.10.10"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-15114
  Scenario: Harden haproxy to prevent the PROXY header from being passed for edge route
    Given the master version >= "3.6"
    And I have a project
    And I store an available router IP in the :router_ip clipboard
    Given I have a header test service in the project
    #Create the edge route
    When I run the :create_route_edge client command with:
      | name           | route-edge                                |
      | service        | <%= cb.header_test_svc.name %>            |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -H   |
      | proxy:10.10.10.10 |
      | https://<%= route("route-edge", service("header-test-insecure")).dns(by: user) %> |
      | -k |
    Then the step should succeed
    And the output should contain "host: <%= route("route-edge", service("header-test-insecure")).dns(by: user) %>"
    And the output should not contain "proxy: 10.10.10.10"
    """
    #for no-sni
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -H   |
      | proxy:10.10.10.10 |
      | -H   |
      | Host:<%= route("route-edge", service("header-test-insecure")).dns(by: user) %>  |
      | https://<%= cb.router_ip[0] %> |
      | -k |
    Then the step should succeed
    And the output should contain "host: <%= route("route-edge", service("header-test-insecure")).dns(by: user) %>"
    And the output should not contain "proxy: 10.10.10.10"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-15115
  Scenario: Harden haproxy to prevent the PROXY header from being passed for reencrypt route
    Given the master version >= "3.6"
    And I have a project
    And I store an available router IP in the :router_ip clipboard
    #Create the pod/svc/route
    Given I obtain test data file "routing/header-test/header-reecrypt-without-CA.json"
    When I run the :create client command with:
      | f | header-reecrypt-without-CA.json |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    And all pods in the project are ready
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -H   |
      | proxy:10.10.10.10 |
      | https://<%= route("header-reencrypt", service("service-reen")).dns(by: user) %> |
      | -k |
    Then the step should succeed
    And the output should contain "host: <%= route("header-reencrypt", service("service-reen")).dns(by: user) %>"
    And the output should not contain "proxy: 10.10.10.10"
    """
    #for no-sni
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -H   |
      | proxy:10.10.10.10 |
      | -H   |
      | Host:<%= route("header-reencrypt", service("service-reen")).dns(by: user) %>  |
      | https://<%= cb.router_ip[0] %> |
      | -k |
    Then the step should succeed
    And the output should contain "host: <%= route("header-reencrypt", service("service-reen")).dns(by: user) %>"
    And the output should not contain "proxy: 10.10.10.10"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-16369
  Scenario: The unsecure/passthrough route should NOT support HSTS
    Given the master version >= "3.7"
    And I have a project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    # here also added 'router.openshift.io/cookie_name' and check the result in the following curl,
    # if found the related info that's mean the router had been reload.
    When I run the :annotate client command with:
      | resource     | route                                                    |
      | resourcename | service-unsecure                                         |
      | keyval       | haproxy.router.openshift.io/hsts_header=max-age=31536000;includeSubDomains;preload |
      | keyval       | router.openshift.io/cookie_name=unsecure-cookie_1 |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"
    And the expression should be true> @result[:cookies].any? {|c| c.name == "unsecure-cookie_1"}
    And the expression should be true> !@result[:headers].include?("strict-transport-security")
    """

    Given I obtain test data file "routing/passthrough/service_secure.json"
    When I run the :create client command with:
      | f | service_secure.json |
    Then the step should succeed
    # Create passthrough termination route
    When I run the :create_route_passthrough client command with:
      | name     | myroute |
      | service  | service-secure     |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                    |
      | resourcename | myroute                                                  |
      | keyval       | haproxy.router.openshift.io/hsts_header=max-age=31536000 |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I open secure web server via the "myroute" route
    Then the output should contain "Hello-OpenShift"
    And the expression should be true> !@result[:headers].include?("strict-transport-security")
    """

  # @author zzhao@redhat.com
  # @case_id OCP-15977
  Scenario: Negative testing for route HSTS policy
    Given the master version >= "3.7"
    And I have a project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name     | myroute          |
      | service  | service-unsecure |
    Then the step should succeed
    #using a invalid value for 'max-age'
    When I run the :annotate client command with:
      | resource     | route                                                    |
      | resourcename | myroute                                                  |
      | keyval       | haproxy.router.openshift.io/hsts_header=max-age=-20      |
      | keyval       | router.openshift.io/cookie_name=edge-with-invalid-hsts   |
    Then the step should succeed
    Given I use the "service-unsecure" service
    And I wait up to 20 seconds for the steps to pass:
    """
    When I wait for a secure web server to become available via the "myroute" route
    Then the output should contain "Hello-OpenShift"
    And the expression should be true> @result[:cookies].any? {|c| c.name == "edge-with-invalid-hsts"}
    And the expression should be true> !@result[:headers].include?("strict-transport-security")
    """
    #using a invalid NOT 'includeSubDomains'
    When I run the :annotate client command with:
      | resource     | route                                                                      |
      | resourcename | myroute                                                                    |
      | keyval       | haproxy.router.openshift.io/hsts_header=max-age=20;invalid                 |
      | keyval       | router.openshift.io/cookie_name=edge-with-invalid-hsts-subdomain           |
      | overwrite    | true                                                                       |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I wait for a secure web server to become available via the "myroute" route
    Then the output should contain "Hello-OpenShift"
    And the expression should be true> @result[:cookies].any? {|c| c.name == "edge-with-invalid-hsts-subdomain"}
    And the expression should be true> !@result[:headers].include?("strict-transport-security")
    """

    #using a invalid NOT 'preload'
    When I run the :annotate client command with:
      | resource     | route                                                                          |
      | resourcename | myroute                                                                        |
      | keyval       | haproxy.router.openshift.io/hsts_header=max-age=20;includeSubDomains;invalid   |
      | keyval       | router.openshift.io/cookie_name=edge-with-invalid-hsts-preload                 |
      | overwrite    | true                                                                           |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I wait for a secure web server to become available via the "myroute" route
    Then the output should contain "Hello-OpenShift"
    And the expression should be true> @result[:cookies].any? {|c| c.name == "edge-with-invalid-hsts-preload"}
    And the expression should be true> !@result[:headers].include?("strict-transport-security")
    """

  # @author aiyengar@redhat.com
  # @case_id OCP-16732
  @admin
  Scenario: Check haproxy.config when overwriting 'timeout server' which was already specified
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=test-pods |
    When I expose the "test-service" service
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                     |
      | resourcename | test-service                              |
      | keyval       | haproxy.router.openshift.io/timeout=5s    |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%=cb.router_pod %>" pod:
      | grep | -A | 12 | <%= cb.proj_name %>:test-service | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain 1 times:
      | timeout server  5s |
    """

  # @author zzhao@redhat.com
  # @case_id OCP-19804
  Scenario: Unsecure route with path and another tls route with same hostname can work at the same time
    Given the master version >= "3.10"
    And I have a project
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=test-pods |
    When I run the :create_route_edge client command with:
      | name           | route-edge                                |
      | service        | test-service                              |
      | insecure_policy | Allow                                    |
    Then the step should succeed

    #Create another same route with path and same hostname
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | service                        |
      | resource_name | service-unsecure               |
      | name          | route1                         |
      | hostname      | <%= route("route-edge").dns %> |
      | path          | /test                          |
    Then the step should succeed
    When I wait for a web server to become available via the "route-edge" route
    Then the output should contain "Hello OpenShift!"
    And I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route("route-edge").dns %>/test/" url
    Then the output should contain "Hello-OpenShift-Path-Test"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-19799
  Scenario: The tls section of route can be edit after created
    Given the master version >= "3.9"
    And I have a project
    Given I obtain test data file "routing/edge/route_edge.json"
    When I run the :create client command with:
      | f | route_edge.json |
    Then the step should succeed
    Given I successfully patch resource "route/secured-edge-route" with:
      | {"spec":{"tls":{"key":"qe","certificate":"ocp","caCertificate":"redhat"}}} |

  # @author zzhao@redhat.com
  # @case_id OCP-19800
  Scenario: Route validation should catch the cert which lack of dash
    Given I have a project
    Given I obtain test data file "routing/invalid_route/edge/route_edge_lack_dash_for_key.json"
    Given I obtain test data file "routing/invalid_route/edge/route_edge_lack_dash_for_cert.json"
    Given I obtain test data file "routing/invalid_route/edge/route_edge_lack_dash_for_cacert.json"
    When I run the :create client command with:
      | f | route_edge_lack_dash_for_key.json    |
      | f | route_edge_lack_dash_for_cert.json   |
      | f | route_edge_lack_dash_for_cacert.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route  |
    Then the step should succeed
    And the output should contain 3 times:
      | ExtendedValidationFailed |

  # @author zzhao@redhat.com
  # @case_id OCP-19808
  @admin
  Scenario: Haproxy router will not be crashed when there is route with hostname localhost
    # ensure no error in the router pod's log
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    When I run the :logs admin command with:
      | resource_name | <%= cb.router_pod %>  |
    Then the step should succeed
    And the output should not contain "error reloading router: exit status"
    Given I switch to the first user
    Given I have a project
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    #Create route with hostname 'localhost'
    When I run the :expose client command with:
      | resource      | service      |
      | resource_name | test-service |
      | name          | routelocal   |
      | hostname      | localhost    |
    Then the step should succeed
    #Create another normal route and access it to make sure the router has been reloaded
    When I expose the "test-service" service
    Then the step should succeed
    When I wait for a web server to become available via the "test-service" route
    Then the output should contain "Hello OpenShift!"

    # check the same router pod's log
    Given I switch to cluster admin pseudo user
    And I use the router project
    When I run the :logs admin command with:
      | resource_name | <%= cb.router_pod %>  |
    Then the step should succeed
    And the output should not contain "error reloading router: exit status"

  # @author aiyengar@redhat.com
  # @case_id OCP-33897
  Scenario: Route with "reencrypt" termination type can work with service signed certificate
    Given the master version >= "4.1"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard

    # Deploy secure service with signed secret annotation
    Given I obtain test data file "routing/ingress/signed-service.json"
    When I run the :create client command with:
      | f | signed-service.json |
    And the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    And I check that the "service-secret" secret exists
    """

    # Deploy a pod with secret volume and mountpaths
    Given I obtain test data file "routing/ingress/caddy-secure.yaml"
    When I run the :create client command with:
      | f | caddy-secure.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |
 
    # Create a a REEN terminated route
    Given I obtain test data file "routing/reencrypt/route_reencrypt-reen.example.com.crt"
    Given I obtain test data file "routing/reencrypt/route_reencrypt-reen.example.com.key"
    When I run the :create_route_reencrypt client command with:
      | name     | route-reencrypt                                         |
      | service  | service-secure                                          |
      | cert     | route_reencrypt-reen.example.com.crt                    |
      | key      | route_reencrypt-reen.example.com.key                    |
      | hostname | route-reencrypt-<%= project.name %>.<%= cb.subdomain %> |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "https://route-reencrypt-<%= project.name %>.<%= cb.subdomain %>" url
    And the output should contain "Hello-OpenShift-1 https-8443"
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34106
  Scenario: Routes annotated with  "haproxy.router.openshift.io/rewrite-target=/path" will replace and rewrite http request with specified "/path"
    Given the master version >= "4.6"
    And I have a project

    # Create  project resource and route followed by curl to generate access traffic
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |
    Then the expression should be true> service('service-unsecure').exists?

    # Deploy route with specific path annotation to test the rewrite
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                    |
      | resourcename | service-unsecure                                         |
      | keyval       | haproxy.router.openshift.io/rewrite-target=/path/second/ |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/" url
    And the output should contain "second-test http-8080"
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34168
  Scenario: Routes can be annotated with "haproxy.router.openshift.io/rewrite-target" to rewrite paths in HTTP request before forwarding
    Given the master version >= "4.6"
    And I have a project

    # Create  project resource and route followed by curl to generate access traffic
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |
    Then the expression should be true> service('service-unsecure').exists?

    # Deploy route with default rewrite annotation to check all paths are reachable
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                        |
      | resourcename | service-unsecure                             |
      | keyval       | haproxy.router.openshift.io/rewrite-target=/ |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/" url
    And the output should contain "Hello-OpenShift-1 http-8080"
    When I open web server via the "http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/test/" url
    And the output should contain "Hello-OpenShift-Path-Test http-8080"
    When I open web server via the "http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/path/second/" url
    And the output should contain "second-test http-8080"
    """
