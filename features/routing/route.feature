Feature: Testing route

  # @author: zzhao@redhat.com
  # @case_id: OCP-11883
  Scenario: Be able to add more alias for service
    Given I have a project
    When I run the :create client command with:
      | f  |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/dc.json |
    Then the step should succeed
    When I run the :create client command with:
      | f  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/insecure-service.json |
    Then the step should succeed
    When I expose the "header-test-insecure" service
    Then the step should succeed
    And I wait for a web server to become available via the route
    When I run the :get client command with:
      | resource      | route |
      | resource_name | header-test-insecure |
      | o             | yaml |
    And I save the output to file>header-test-insecure.yaml
    And I replace lines in "header-test-insecure.yaml":
      | name: header-test-insecure | name: header-test-insecure-dup |
      | host: header-test-insecure | host: header-test-insecure-dup |
    When I run the :create client command with:
      |f | header-test-insecure.yaml |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | route                                           |
      | resource_name | header-test-insecure-dup                        |
      | p             | {"spec":{"to":{"name":"header-test-insecure"}}} |
    Then I wait for a web server to become available via the "header-test-insecure-dup" route

  # @author: zzhao@redhat.com
  # @case_id: OCP-12122
  Scenario: Alias will be invalid after removing it
    Given I have a project
    When I run the :create client command with:
      | f  |   https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/dc.json  |
    Then the step should succeed
    When I run the :create client command with:
      | f  |   https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/insecure-service.json |
    Then the step should succeed
    When I expose the "header-test-insecure" service
    Then the step should succeed
    Then I wait for a web server to become available via the "header-test-insecure" route
    When I run the :delete client command with:
      | object_type | route |
      | object_name_or_id | header-test-insecure |
    Then I wait for the resource "route" named "header-test-insecure" to disappear
    Then I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "header-test-insecure" route
    Then the step should fail
    """

  # @author xxia@redhat.com
  # @case_id OCP-12563
  @admin
  Scenario: The certs for the edge/reencrypt termination routes should be removed when the routes removed
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt.json" replacing paths:
      | ["spec"]["host"]  | www.<%= rand_str(5, :dns) %>.example.com |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge.json" replacing paths:
      | ["spec"]["host"]  | www.<%= rand_str(5, :dns) %>.example.com |
    Then the step should succeed

    Then evaluation of `project.name` is stored in the :proj_name clipboard
    And evaluation of `"secured-edge-route"` is stored in the :edge_route clipboard
    And evaluation of `"route-reencrypt"` is stored in the :reencrypt_route clipboard

    When I switch to cluster admin pseudo user
    And I use the "default" project
    And I wait up to 10 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash |
      | -lc |
      | ls /var/lib/*/router/certs |
    Then the step should succeed
    And the output should contain:
      | <%= cb.proj_name %>_<%= cb.edge_route %>.pem |
      | <%= cb.proj_name %>_<%= cb.reencrypt_route %>.pem |
    """
    When I execute on the pod:
      | bash |
      | -lc |
      | ls /var/lib/*/router/cacerts |
    Then the step should succeed
    And the output should contain:
      | <%= cb.proj_name %>_<%= cb.reencrypt_route %>.pem |

    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    When I run the :delete client command with:
      | object_type       | route                |
      | object_name_or_id | <%= cb.edge_route %> |
    Then the step should succeed

    When I wait for the resource "route" named "<%= cb.edge_route %>" to disappear
    And I switch to cluster admin pseudo user
    And I use the "default" project
    And I execute on the pod:
      | bash |
      | -lc |
      | ls /var/lib/*/router/certs |
    Then the step should succeed
    And the output should not contain:
      | <%= cb.proj_name %>_<%= cb.edge_route %>.pem |
    And the output should contain:
      | <%= cb.proj_name %>_<%= cb.reencrypt_route %>.pem |

    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    When I run the :delete client command with:
      | object_type       | route                     |
      | object_name_or_id | <%= cb.reencrypt_route %> |
    Then the step should succeed

    When I wait for the resource "route" named "<%= cb.reencrypt_route %>" to disappear
    And I switch to cluster admin pseudo user
    And I use the "default" project
    And I execute on the pod:
      | bash |
      | -lc |
      | ls /var/lib/*/router/certs /var/lib/*/router/cacerts |
    Then the step should succeed
    And the output should not contain:
      | <%= cb.proj_name %>_<%= cb.reencrypt_route %>.pem |

  # @author yadu@redhat.com
  # @case_id OCP-10660
  Scenario: Service endpoint can be work well if the mapping pod ip is updated
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :get client command with:
      | resource | endpoints |
    And the output should contain:
      | test-service |
      | :8080        |
    When I get project replicationcontroller as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :rc_name clipboard
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
      | replicas | 0                      |
    When I run the :get client command with:
      | resource | endpoints |
    And the output should contain:
      | test-service |
      | none         |
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
      | replicas | 1                      |
    And I wait until number of replicas match "1" for replicationController "<%= cb.rc_name %>"
    And all pods in the project are ready
    When I run the :get client command with:
      | resource | endpoints |
    And the output should contain:
      | test-service |
      | :8080        |

  # @author: zzhao@redhat.com
  # @case_id: OCP-10762
  Scenario: Check the header forward format
    Given I have a project
    When I run the :create client command with:
      | f  |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/dc.json |
    Then the step should succeed
    When I run the :create client command with:
      | f  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/insecure-service.json |
    Then the step should succeed
    When I expose the "header-test-insecure" service
    Then the step should succeed
    When I wait for a web server to become available via the route
    Then the output should contain ";host=<%= route.dns(by: user) %>;proto=http"

  # @author: yadu@redhat.com
  # @case_id: OCP-9717
  Scenario: Config insecureEdgeTerminationPolicy to an invalid value for route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name     | myroute      |
      | service  | service-unsecure |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | route |
      | resource_name | myroute |
      | p             | {"spec":{"tls":{"insecureEdgeTerminationPolicy":"Abc"}}} |
    And the output should contain:
      | invalid value for InsecureEdgeTerminationPolicy option, acceptable values are None, Allow, Redirect, or empty |

 
  # @author: zzhao@redhat.com
  # @case_id: OCP-12652
  Scenario: The later route should be HostAlreadyClaimed when there is a same host exist
    Given I have a project
    When I run the :create client command with:
      | f |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/route_unsecure.json  |
    Then the step should succeed
    Given I create a new project
    When I run the :create client command with:
      | f |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/route_unsecure.json  |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | route  |
      | resource_name | route  |
    Then the output should contain "HostAlreadyClaimed"

    
  # @author bmeng@redhat.com
  # @case_id OCP-12472
  Scenario: Edge terminated route with custom cert
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem" 
 
    Given I have a pod-for-ping in the project
    When I run the :create_route_edge client command with:
      | name | route-edge |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
      | cacert | ca.pem |
    Then the step should succeed
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-edge", service("route-edge")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
      | -c | 
      | /tmp/cookie.txt|
    Then the output should contain "Hello-OpenShift"
    When I execute on the pod:
      | cat |
      | /tmp/cookie.txt |
    Then the step should succeed
    And the output should not contain "OPENSHIFT"
    And the output should not match "\d+\.\d+\.\d+\.\d+"

  # @author bmeng@redhat.com
  # @case_id OCP-12477
  Scenario: Passthrough terminated route with custom cert
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    
    Given I have a pod-for-ping in the project
    When I run the :create_route_passthrough client command with:
      | name | passthrough-route |
      | hostname | <%= rand_str(5, :dns) %>-pass.example.com |
      | service | service-secure |
    Then the step should succeed
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("passthrough-route", service("passthrough-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("passthrough-route", service("passthrough-route")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"


  # @author bmeng@redhat.com
  # @case_id OCP-12481
  Scenario: Reencrypt terminated route with custom cert
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/service_secure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt.ca"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"

    Given I have a pod-for-ping in the project
    When I run the :create_route_reencrypt client command with:
      | name | route-reencrypt |
      | hostname | <%= rand_str(5, :dns) %>-reen.example.com |
      | service | service-secure |
      | cert | route_reencrypt-reen.example.com.crt |
      | key | route_reencrypt-reen.example.com.key |
      | cacert | route_reencrypt.ca |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
      | -c |
      | /tmp/cookie.txt|
    Then the output should contain "Hello-OpenShift"
    When I execute on the pod:
      | cat |
      | /tmp/cookie.txt |
    Then the step should succeed
    And the output should not contain "OPENSHIFT"
    And the output should not match "\d+\.\d+\.\d+\.\d+"

  # @author zzhao@redhat.com cryan@redhat.com
  # @case_id OCP-12575
  Scenario: The path specified in route can work well for unsecure
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
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
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/route_unsecure.json"
    And I replace lines in "route_unsecure.json":
      | unsecure.example.com | <%= cb.unsecure %> |
    When I run the :create client command with:
      | f | route_unsecure.json |
    Then the step should succeed
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route("route", service("service-unsecure")).dns(by: user) %>/test/" url
    Then the output should contain "Hello-OpenShift-Path-Test"
    """
    When I open web server via the "http://<%= route("route", service("service-unsecure")).dns(by: user) %>/" url
    Then the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-12562
  Scenario: The path specified in route can work well for edge terminated
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | service-unsecure |
      | path| /test |
    Then the step should succeed
    When I execute on the pod:
      | curl |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/test/ |
      | -c |
      | /tmp/cookie.txt |
      | -k |
    Then the output should contain "Hello-OpenShift-Path-Test"
    When I execute on the pod:
      | curl |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/ |
      | -k |
    Then the output should contain "Application is not available"
    When I execute on the pod:
      | cat | 
      | /tmp/cookie.txt |
    Then the step should succeed
    And the output should not contain "OPENSHIFT"
    And the output should not match "\d+\.\d+\.\d+\.\d+"

  # @author zzhao@redhat.com
  # @case_id OCP-12564
  Scenario: The path specified in route can work well for reencrypt terminated
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/service_secure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt.ca"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"

    Given I have a pod-for-ping in the project
    When I run the :create_route_reencrypt client command with:
      | name | route-recrypt |
      | hostname | <%= rand_str(5, :dns) %>-reen.example.com |
      | service | service-secure |
      | cert | route_reencrypt-reen.example.com.crt |
      | key | route_reencrypt-reen.example.com.key |
      | cacert | route_reencrypt.ca |
      | destcacert | route_reencrypt_dest.ca |
      | path | /test |
    Then the step should succeed
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>/test/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift-Path-Test"
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Application is not available"

  # @author zzhao@redhat.com
  # @case_id OCP-12506
  Scenario: Re-encrypting route with no cert if a router is configured with a default wildcard cert
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/service_secure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    And the step should succeed
   
    Given I have a pod-for-ping in the project
    When I run the :create_route_reencrypt client command with:
      | name | no-cert |
      | hostname | <%= rand_str(5, :dns) %>-reen.example.com |
      | service | service-secure |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("no-cert", service("no-cert")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("no-cert", service("no-cert")).dns(by: user) %>/ |
      | -k |
    Then the output should contain "Hello-OpenShift"

  # @author yadu@redhat.com
  # @case_id OCP-12556
  Scenario: Create a route without host named
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc470732/route_withouthost1.json |
    Then the step should succeed
    When I use the "service-unsecure" service
    Then I wait for a web server to become available via the "service-unsecure1" route
    Then the output should contain "Hello-OpenShift"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc470732/route_withouthost2.json |
    Then the step should succeed
    When I use the "service-unsecure" service
    Then I wait for a web server to become available via the "service-unsecure2" route
    Then the output should contain "Hello-OpenShift"

  # @author yadu@redhat.com
  # @case_id OCP-9651
  Scenario: Config insecureEdgeTerminationPolicy to Redirect for route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    # Create edge termination route
    When I run the :create_route_edge client command with:
      | name     | myroute |
      | service  | service-unsecure     |
    Then the step should succeed
    # Set insecureEdgeTerminationPolicy to Redirect
    When I run the :patch client command with:
      | resource      | route              |
      | resource_name | myroute            |
      | p             | {"spec":{"tls":{"insecureEdgeTerminationPolicy":"Redirect"}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
    Then the step should succeed
    And the output should contain:
      | Redirect |
    # Acess the route
    Given I have a pod-for-ping in the project 
    When I execute on the pod:
      | curl |
      | -v |
      | -L |
      | http://<%= route("myroute", service("service-unsecure")).dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |
      | HTTP/1.1 302 Found |
      | Location: https:// |


  # @author zzhao@redhat.com
  # @case_id OCP-12566
  Scenario: Cookie name should not use openshift prefix
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | <%= route.dns(by: user) %> |
      | -c |
      | /tmp/cookie |
    Then the output should contain "Hello-OpenShift"
    And I execute on the pod:
      | cat | 
      | /tmp/cookie |
    Then the step should succeed
    And the output should not contain "OPENSHIFT"
    And the output should not match "\d+\.\d+\.\d+\.\d+"


  # @author yadu@redhat.com
  # @case_id OCP-9650
  Scenario: Config insecureEdgeTerminationPolicy to Allow for route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name     | myroute          |
      | service  | service-unsecure |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | route   |
      | resource_name | myroute |
      | p             | {"spec":{"tls":{"insecureEdgeTerminationPolicy":"Allow"}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
    Then the step should succeed
    And the output should contain:
      | Allow |
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl                                                                                          |
      | --resolve                                                                                     |
      | <%= route("myroute", service("service-unsecure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("myroute", service("service-unsecure")).dns(by: user) %>/                   |
      | -k                                                                                            |
      | -v                                                                                            |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |
      | HTTP/1.1 200    |
    And the output should not contain:
      | HTTP/1.1 302 Found |
    When I execute on the pod:
      | curl                                                                                         |
      | --resolve                                                                                    |
      | <%= route("myroute", service("service-unsecure")).dns(by: user) %>:80:<%= cb.router_ip[0] %> |
      | http://<%= route("myroute", service("service-unsecure")).dns(by: user) %>/                   |
      | -v                                                                                           |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |
      | HTTP/1.1 200    | 
    And the output should not contain:
      | HTTP/1.1 302 Found |


  # @author yadu@redhat.com
  # @case_id OCP-12635
  Scenario: Enabled Active/Active routers can do round-robin on multiple target IPs
    # The case need to run on multi-node env
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    Then the expression should be true> cb.router_ip.size > 1
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name     | edge-route       |
      | service  | service-unsecure |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl                                                                                       |
      | --resolve                                                                                  |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/                   |
      | -k                                                                                         |
    Then the step should succeed
    Then the output should contain "Hello-OpenShift"
    When I execute on the pod:
      | curl                                                                                       |
      | --resolve                                                                                  |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[1] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/                   |
      | -k                                                                                         |
    Then the step should succeed
    Then the output should contain "Hello-OpenShift"


  # @author yadu@redhat.com
  # @case_id OCP-10024
  Scenario: Route could NOT be updated after created
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc470732/route_withouthost1.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | route                                   |
      | resource_name | service-unsecure1                       |
      | p             | {"spec":{"host":"www.changeroute.com"}} |
    Then the output should contain:
      | spec.host: Invalid value: "www.changeroute.com": field is immutable |


  # @author zzhao@redhat.com
  # @case_id OCP-11325
  Scenario: Limit the number of http request per ip
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    And all pods in the project are ready
    When I expose the "test-service" service
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                           |
      | resourcename | test-service                                                    |
      | keyval       | haproxy.router.openshift.io/rate-limit-connections=true         |
      | keyval       | haproxy.router.openshift.io/rate-limit-connections.rate-http=3  |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | -c | for i in {1..5} ; do curl --resolve <%= route.dns(by: user) %>:80:<%= cb.router_ip[0] %> http://<%= route.dns(by: user) %>/ ; done |
    Then the output should contain 3 times:
      | Hello OpenShift |
    And the output should contain 2 times:
      | Empty reply from server |

    Given 15 seconds have passed
    When I execute on the pod:
      | bash | -c | for i in {1..5} ; do curl --resolve <%= route.dns(by: user) %>:80:<%= cb.router_ip[0] %> http://<%= route.dns(by: user) %>/ ; done |
    Then the output should contain 3 times:
      | Hello OpenShift |
    And the output should contain 2 times:
      | Empty reply from server |

  # @author zzhao@redhat.com
  # @case_id OCP-12573
  # @note requires v3.4+
  Scenario: Default haproxy router should be able to skip invalid cert route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem"

    Given I have a pod-for-ping in the project
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
      | cacert | ca.pem |
    Then the step should succeed
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"

    #create some invalid route
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/invalid_route/edge/route_edge_expire.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/invalid_route/edge/route_edge_invalid_ca.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/invalid_route/edge/route_edge_invalid_key.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/invalid_route/edge/route_edge_invalid_cert.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/invalid_route/edge/route_edge_noca.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/invalid_route/reen/route_reencrypt_invalid_ca.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/invalid_route/reen/route_reencrypt_invalid_cert.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/invalid_route/reen/route_reencrypt_invalid_key.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/invalid_route/reen/route_reencrypt_invalid_desca.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/invalid_route/reen/route_reencry.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | route |
    Then the output should contain 7 times:
      | ExtendedValidationFailed |

    #create one normal reencyption route to check if it can work after those invalid route
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/service_secure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt.ca"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"

    When I run the :create_route_reencrypt client command with:
      | name | route-recrypt |
      | hostname | <%= rand_str(5, :dns) %>-reen.example.com |
      | service | service-secure |
      | cert | route_reencrypt-reen.example.com.crt |
      | key | route_reencrypt-reen.example.com.key |
      | cacert | route_reencrypt.ca |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-12682
  @admin
  Scenario: Don't health check for idle service
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    Given I use the "service-unsecure" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard
    Given I use the "service-secure" service
    And evaluation of `service.ip(user: user)` is stored in the :service_secure_ip clipboard
    When I expose the "service-unsecure" service
    When I run the :create_route_edge client command with:
      | name    | edge-route       |
      | service | service-unsecure |
    Then the step should succeed
    #passthrough route
    When I run the :create_route_passthrough client command with:
      | name    | route-pass     |
      | service | service-secure |
    Then the step should succeed
    #reencrypt route
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt.ca"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    Then the step should succeed
    When I run the :create_route_reencrypt client command with:
      | name | route-reencrypt |
      | hostname | <%= rand_str(5, :dns) %>-reen.example.com |
      | service | service-secure |
      | cert | route_reencrypt-reen.example.com.crt |
      | key | route_reencrypt-reen.example.com.key |
      | cacert | route_reencrypt.ca |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I execute on the pod:
      | grep | <%=cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain 4 times:
      | check inter 5000ms |

    Given I switch to the first user
    When I run the :idle client command with:
      | svc_name | service-unsecure |
    Then the step should succeed
    Given 6 seconds have passed
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
       | service-secure.*none   |
       | service-unsecure.*none |

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.service_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should not contain "check inter"
    When I wait up to 600 seconds for a web server to become available via the "service-unsecure" route
    And I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain 4 times:
      | check inter 5000ms |

    Given I switch to the first user
    When I run the :idle client command with:
      | svc_name | service-secure |
    Then the step should succeed
    Given 6 seconds have passed
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
       | service-secure.*none   |
       | service-unsecure.*none |

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.service_secure_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should not contain "check inter"
    When I wait up to 600 seconds for a secure web server to become available via the "route-pass" route
    And I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain 4 times:
      | check inter 5000ms |

  # @author yadu@redhat.com
  # @case_id OCP-10545
  Scenario: Generated route host DNS segment should not exceed 63 characters
    Given a 47 characters random string of type :dns is stored into the :proj_name1 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name1 %> |
    Then the step should succeed
    When I use the "<%= cb.proj_name1 %>" project
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    And all pods in the project are ready
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
    Then the step should succeed
    And the output should contain "InvalidHost"
    
    When I delete the project
    Then the step should succeed

    Given a 46 characters random string of type :dns is stored into the :proj_name2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name2 %> |
    Then the step should succeed
    When I use the "<%= cb.proj_name2 %>" project
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed     
    When I expose the "service-unsecure" service
    Then the step should succeed
    And I wait for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"

  # @author: yadu@redhat.com
  # @case_id: OCP-9576
  Scenario: Customize the default routing subdomain
    Given I have a project
    Given I store default router subdomain in the :subdomain clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :get client command with: 
      | resource      | route |
    Then the output should contain:
      | <%= cb.subdomain %> |

  # @author zzhao@redhat.com
  # @case_id OCP-11036
  Scenario: Add http and https redirect support for passthrough and reencrypt termination	
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    # Create passthrough termination route
    When I run the :create_route_passthrough client command with:
      | name     | myroute |
      | service  | service-secure     |
    Then the step should succeed
    # Set insecureEdgeTerminationPolicy to Redirect
    When I run the :patch client command with:
      | resource      | route              |
      | resource_name | myroute            |
      | p             | {"spec":{"tls":{"insecureEdgeTerminationPolicy":"Redirect"}}} |
    Then the step should succeed
    # Acess the route
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | -v |
      | -L |
      | http://<%= route("myroute", service("service-secure")).dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |
      | HTTP/1.1 302 Found |
      | Location: https:// |
    
    When I run the :patch client command with:
      | resource      | route              |
      | resource_name | myroute            |
      | p             | {"spec":{"tls":{"insecureEdgeTerminationPolicy":"Allow"}}} |
    Then the step should fail
    And the output should contain "acceptable values are None, Redirect, or empty"
 
    #create reencrypt termination route
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | reen |
      | service    | service-secure     |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    # Set insecureEdgeTerminationPolicy to Redirect
    When I run the :patch client command with:
      | resource      | route           |
      | resource_name | reen            |
      | p             | {"spec":{"tls":{"insecureEdgeTerminationPolicy":"Redirect"}}} |
    Then the step should succeed
    # Acess the route
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -v |
      | -L |
      | http://<%= route("reen", service("service-secure")).dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |
      | HTTP/1.1 302 Found |
      | Location: https:// |
    """    
    When I run the :patch client command with:
      | resource      | route           |
      | resource_name | reen            |
      | p             | {"spec":{"tls":{"insecureEdgeTerminationPolicy":"Allow"}}} |
    Then the step should succeed
    # Acess the route
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | http://<%= route("reen", service("service-secure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """
