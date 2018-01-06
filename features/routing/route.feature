Feature: Testing route

  # @author zzhao@redhat.com
  # @case_id OCP-11883
  @smoke
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
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | service          |
      | resource_name | header-test-insecure |
      | name          | header-test-insecure-dup |
    Then the step should succeed    
    Then I wait for a web server to become available via the "header-test-insecure-dup" route

  # @author zzhao@redhat.com
  # @case_id OCP-12122
  @smoke
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
    And the output should match:
      | <%= cb.proj_name %>[_:]<%= cb.edge_route %>.pem |
      | <%= cb.proj_name %>[_:]<%= cb.reencrypt_route %>.pem |
    """
    When I execute on the pod:
      | bash |
      | -lc |
      | ls /var/lib/*/router/cacerts |
    Then the step should succeed
    And the output should match:
      | <%= cb.proj_name %>[_:]<%= cb.reencrypt_route %>.pem |

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
    And the output should not match:
      | <%= cb.proj_name %>[_:]<%= cb.edge_route %>.pem |
    And the output should match:
      | <%= cb.proj_name %>[_:]<%= cb.reencrypt_route %>.pem |

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
    And the output should not match:
      | <%= cb.proj_name %>[_:]<%= cb.reencrypt_route %>.pem |

  # @author yadu@redhat.com
  # @case_id OCP-10660
  @smoke
  Scenario: Service endpoint can be work well if the mapping pod ip is updated
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :get client command with:
      | resource | endpoints |
    Then the output should contain:
      | test-service |
      | :8080        |
    Given I get project replicationcontroller as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :rc_name clipboard
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
      | replicas | 0                      |
    Then the step should succeed
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | endpoints |
    Then the output should contain:
      | test-service |
      | none         |
    """
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
      | replicas | 1                      |
    And I wait until number of replicas match "1" for replicationController "<%= cb.rc_name %>"
    And all pods in the project are ready
    When I run the :get client command with:
      | resource | endpoints |
    Then the output should contain:
      | test-service |
      | :8080        |

  # @author zzhao@redhat.com
  # @case_id OCP-10762
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

  # @author yadu@redhat.com
  # @case_id OCP-9717
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


  # @author zzhao@redhat.com
  # @case_id OCP-12652
  @smoke
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
  @smoke
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
    And CA trust is added to the pod-for-ping
    When I run the :create_route_edge client command with:
      | name | route-edge |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
      | cacert | ca.pem |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
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
    """
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
    And CA trust is added to the pod-for-ping
    When I run the :create_route_passthrough client command with:
      | name | passthrough-route |
      | hostname | <%= rand_str(5, :dns) %>-pass.example.com |
      | service | service-secure |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("passthrough-route", service("passthrough-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("passthrough-route", service("passthrough-route")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"
    """

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
    And CA trust is added to the pod-for-ping
    When I run the :create_route_reencrypt client command with:
      | name | route-reencrypt |
      | hostname | <%= rand_str(5, :dns) %>-reen.example.com |
      | service | service-secure |
      | cert | route_reencrypt-reen.example.com.crt |
      | key | route_reencrypt-reen.example.com.key |
      | cacert | route_reencrypt.ca |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
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
    """
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
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/test/ |
      | -c |
      | /tmp/cookie.txt |
      | -k |
    Then the output should contain "Hello-OpenShift-Path-Test"
    """
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
  @smoke
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
    And CA trust is added to the pod-for-ping
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
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>/test/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift-Path-Test"
    """
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
      | -c                                                                                           |
      | /tmp/cookie                                                                                  |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |
      | HTTP/1.1 200    |
    And the output should not contain:
      | HTTP/1.1 302 Found |
    And I execute on the pod:
      | cat |
      | /tmp/cookie |
    Then the step should succeed
    And the output should match:
      | FALSE.*FALSE |

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
  @smoke
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
    And CA trust is added to the pod-for-ping
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
      | cacert | ca.pem |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"
    """
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
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-12682
  @admin
  Scenario: Don't health check for idle service
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/list_for_pods.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    Given I use the "service-unsecure" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard
    Given I use the "service-secure" service
    And evaluation of `service.ip(user: user)` is stored in the :service_secure_ip clipboard

    #idle the service-unsecure service
    When I run the :idle client command with:
      | svc_name | service-unsecure |
    Then the step should succeed

    #Create unsecure and edge route
    When I expose the "service-unsecure" service
    When I run the :create_route_edge client command with:
      | name    | edge-route       |
      | service | service-unsecure |
    Then the step should succeed

    #Check the service still idle after create the route
    Given 6 seconds have passed
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
       | service-secure.*none   |
       | service-unsecure.*none |

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    Given a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.service_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should not contain "check inter"

    Given I switch to the first user
    #unidle the service to make the pod in running
    And I wait up to 600 seconds for a web server to become available via the "service-unsecure" route
    When I run the :idle client command with:
      | svc_name | service-secure |
    Then the step should succeed

    #Create passthrough route
    When I run the :create_route_passthrough client command with:
      | name    | route-pass     |
      | service | service-secure |
    Then the step should succeed

    #Create reencrypt route
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

    #Store the new pod ip after unidle the service since maybe the pod ip will be changed.
    Given I switch to the first user
    And I use the "<%=cb.proj_name %>" project
    When I wait up to 600 seconds for a secure web server to become available via the "route-pass" route
    And a pod becomes ready with labels:
      | name=test-pods |
    Then evaluation of `pod.ip` is stored in the :pod_new_ip clipboard

    #Check the 'check inter 5000ms' already recover after unidle
    Given I switch to cluster admin pseudo user
    And I use the "default" project

    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.pod_new_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain 4 times:
      | check inter 5000ms |
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

  # @author yadu@redhat.com
  # @case_id OCP-9576
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
  Scenario: Set insecureEdgeTerminationPolicy to Redirect for passthrough route
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
    And I wait up to 20 seconds for the steps to pass:
    """
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
    """
    When I run the :patch client command with:
      | resource      | route              |
      | resource_name | myroute            |
      | p             | {"spec":{"tls":{"insecureEdgeTerminationPolicy":"Allow"}}} |
    Then the step should fail
    And the output should contain "acceptable values are None, Redirect, or empty"

  # @author zzhao@redhat.com
  # @case_id OCP-11839
  Scenario: Set insecureEdgeTerminationPolicy to Redirect and Allow for reencrypt route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed

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

  # @author zzhao@redhat.com
  # @case_id OCP-13248
  Scenario: The hostname should be converted to available route when met special character
    Given I have a project
    When I run the :create client command with:
      | f  |   https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    # test those 4 kind of route. When creating route which name have '.', it will be decoded to '-'.
    When I run the :expose client command with:
      | resource      | service              |
      | resource_name | service-unsecure     |
      | name          | unsecure.test        |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name     | edge.test        |
      | service  | service-unsecure |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name     | pass.test        |
      | service  | service-unsecure |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    And I run the :create_route_reencrypt client command with:
      | name       | reen.test               |
      | service    | service-unsecure        |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
    Then the step should succeed
    And the output should contain:
      | unsecure-test- |
      | edge-test-     |
      | pass-test-     |
      | reen-test-     |

  # @author zzhao@redhat.com
  # @case_id OCP-13753
  Scenario: Check the cookie if using secure mode when insecureEdgeTerminationPolicy to Redirect for edge/reencrypt route
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
      | name     | myroute           |
      | service  | service-unsecure  |
      | insecure_policy | Redirect   |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | -v |
      | -L |
      | http://<%= route("myroute", service("service-unsecure")).dns(by: user) %>/ |
      | -k |
      | -c |
      | /tmp/cookie |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |
      | HTTP/1.1 302 Found |
      | Location: https:// |
    And I execute on the pod:
      | cat |
      | /tmp/cookie |
    Then the step should succeed
    And the output should match:
      | FALSE.*TRUE |

    #create reencrypt termination route
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | reen                    |
      | service    | service-secure          |
      | destcacert | route_reencrypt_dest.ca |
      | insecure_policy | Redirect           |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -v |
      | -L |
      | http://<%= route("reen", service("service-secure")).dns(by: user) %>/ |
      | -k |
      | -c |
      | /tmp/cookie-reen |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |
      | HTTP/1.1 302 Found |
      | Location: https:// |
    """
    And I execute on the pod:
      | cat |
      | /tmp/cookie-reen |
    Then the step should succeed
    And the output should match:
      | FALSE.*TRUE |

  # @author zzhao@redhat.com
  # @case_id OCP-13254
  Scenario: The HTTP_X_FORWARDED_FOR should be the client IP for ELB env
    Given I have a project
    When I run the :create client command with:
      | f  |   https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/dc.json  |
    Then the step should succeed
    When I run the :create client command with:
      | f  |   https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/insecure-service.json |
    Then the step should succeed
    Given I have a pod-for-ping in the project

    #Get the client ip by access the website http://ipecho.net/plain
    When I execute on the pod:
      | bash | -c | curl -s http://ipecho.net/plain |
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
  # @case_id OCP-14059
  Scenario: Use the default destination CA of router if the route does not specify one for reencrypt route
    Given I have a project
    When I run the :create client command with:
      | f |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/reencrypt-without-all-cert.yaml |
    Then the step should succeed
    And all pods in the project are ready
    Given I use the "service-secure" service
    When I wait up to 20 seconds for a secure web server to become available via the "route-reencrypt" route
    And the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-14089
  Scenario: route cannot be accessed if the backend cannot be matched the the default destination CA of router
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/service_secure.json |
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
    And the output should contain "503 Service Unavailable"

  # @author zzhao@redhat.com
  # @case_id OCP-15028
  Scenario: The router can do a case-insensitive match of a hostname for unsecure route
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready

    #Create the unsecure service
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    #Create the unsecure route
    When I run the :expose client command with:
      | resource      | service                                   |
      | resource_name | service-unsecure                          |
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
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready

    #Create the unsecure service
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    #Create the edge route
    When I run the :create_route_edge client command with:
      | name           | route-edge                                |
      | service        | service-unsecure                          |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= route("route-edge", service("service-unsecure")).dns(by: user).upcase %>" url
    And the output should contain "Hello-OpenShift-1 http-8080"
    """
    # for no-sni
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -s   |
      | -H   |
      | Host:<%= route("route-edge", service("service-unsecure")).dns(by: user).upcase %> |
      | https://<%= cb.router_ip[0] %> |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1 http-8080"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-15072
  Scenario: The router can do a case-insensitive match of a hostname for passthrough route
    Given the master version >= "3.6"
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/wildcard_route/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready

    #Create the secure service
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    #Create passthrough route
    When I run the :create_route_passthrough client command with:
      | name           | route-pass                                |
      | service        | service-secure                            |
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
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/reencrypt-without-all-cert.yaml |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    Given I have a pod-for-ping in the project

    And I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= route("route-reencrypt", service("service-secure")).dns(by: user).upcase %>" url
    And the output should contain "Hello-OpenShift"
    """
    #for no-sni
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -s   |
      | -H   |
      | Host:<%= route("route-reencrypt", service("service-secure")).dns(by: user).upcase %> |
      | https://<%= cb.router_ip[0] %> |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

  # @author yadu@redhat.com
  # @case_id OCP-14678
  Scenario: Only the host in whitelist could access the route - unsecure route
    Given I have a project
    And I have a header test service in the project
    And evaluation of `"haproxy.router.openshift.io/ip_whitelist=#{cb.req_headers["x-forwarded-for"]}"` is stored in the :my_whitelist clipboard

    # Add another IP whitelist for route
    When I run the :annotate client command with:
      | resource     | route                                            |
      | resourcename | <%= cb.header_test_svc.name %>                   |
      | keyval       | haproxy.router.openshift.io/ip_whitelist=8.8.8.8 |
      | overwrite    | true                                             |
    Then the step should succeed

    # Access the route again waiting for the whitelist to apply
    Then I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the route
    Then the step should fail
    And expression should be true> @result[:exitstatus] == -1
    """

    # Add IP whitelist for route
    When I run the :annotate client command with:
      | resource     | route                          |
      | resourcename | <%= cb.header_test_svc.name %> |
      | keyval       | <%= cb.my_whitelist %>         |
      | overwrite    | true                           |
    Then the step should succeed

    # Access the route
    When I wait for a web server to become available via the route
    Then the output should contain "x-forwarded-for"

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
    And expression should be true> @result[:exitstatus] == -1
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
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
    And expression should be true> @result[:exitstatus] == -1
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/secure-service.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/head-test.pem"
    When I run the :create_route_reencrypt client command with:
      | name       | reen-route |
      | service    | header-test-secure |
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
    And expression should be true> @result[:exitstatus] == -1
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
    And expression should be true> @result[:exitstatus] == -1
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
    And I store default router IPs in the :router_ip clipboard
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
    And I store default router IPs in the :router_ip clipboard
    #Create the pod/svc/route 
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/header-reecrypt-without-CA.json |
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
  # @case_id OCP-15976
  Scenario: The edge route should support HSTS
    Given the master version >= "3.7"
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name     | myroute          |
      | service  | service-unsecure |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                    |
      | resourcename | myroute                                                  |
      | keyval       | haproxy.router.openshift.io/hsts_header=max-age=31536000 |
    Then the step should succeed
    Given I use the "service-unsecure" service
    And I wait up to 20 seconds for the steps to pass:
    """
    When I wait for a secure web server to become available via the "myroute" route
    And the output should contain "Hello-OpenShift"
    And the expression should be true> @result[:headers]["strict-transport-security"] == ["max-age=31536000"]
    """
    When I run the :annotate client command with:
      | resource     | route                                                                      |
      | resourcename | myroute                                                                    |
      | keyval       | haproxy.router.openshift.io/hsts_header=max-age=31536000;includeSubDomains |
      | overwrite    | true                                                                       |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    And I wait for a secure web server to become available via the "myroute" route
    And the output should contain "Hello-OpenShift"
    And the expression should be true> @result[:headers]["strict-transport-security"] == ["max-age=31536000;includeSubDomains"]
    """

    When I run the :annotate client command with:
      | resource     | route                                                                         |
      | resourcename | myroute                                                                       |
      | keyval       | haproxy.router.openshift.io/hsts_header=max-age=100;includeSubDomains;preload |
      | overwrite    | true                                                                          |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    And I wait for a secure web server to become available via the "myroute" route
    And the output should contain "Hello-OpenShift"
    And the expression should be true> @result[:headers]["strict-transport-security"] == ["max-age=100;includeSubDomains;preload"]
    """

  # @author zzhao@redhat.com
  # @case_id OCP-16368
  Scenario: The reencrypt route should support HSTS
    Given the master version >= "3.7"
    And I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/reencrypt-without-all-cert.yaml" replacing paths:
      | ["items"][0]["metadata"]["annotations"] | { haproxy.router.openshift.io/hsts_header: "max-age=100;includeSubDomains;preload" } |
    Then the step should succeed
    And all pods in the project are ready
    
    Given I use the "service-secure" service
    And I wait up to 20 seconds for a secure web server to become available via the "route-reencrypt" route
    Then the output should contain "Hello-OpenShift"
    And the expression should be true> @result[:headers]["strict-transport-security"] == ["max-age=100;includeSubDomains;preload"]


  # @author zzhao@redhat.com
  # @case_id OCP-16369
  Scenario: The unsecure/passthrough route should NOT support HSTS
    Given the master version >= "3.7"
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    # here also added 'router.openshift.io/cookie_name' and check the result in the following curl.  if found the related info that's mean the router had been reload.
    When I run the :annotate client command with:
      | resource     | route                                                    |
      | resourcename | service-unsecure                                         |
      | keyval       | haproxy.router.openshift.io/hsts_header=max-age=31536000;includeSubDomains;preload |
      | keyval       | router.openshift.io/cookie_name=unsecure-cookie_1 |
    Then the step should succeed
    When I wait up to 20 seconds for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"
    And the expression should be true> @result[:cookies].any? {|c| c.name == "unsecure-cookie_1"}
    And the expression should be true> !@result[:headers].include?("strict-transport-security")

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
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
    When I wait up to 20 seconds for a secure web server to become available via the "myroute" route
    Then the output should contain "Hello-OpenShift"
    And the expression should be true> !@result[:headers].include?("strict-transport-security")

  # @author zzhao@redhat.com
  # @case_id OCP-15977
  Scenario: Negative testing for route HSTS policy
    Given the master version >= "3.7"
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
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

  # @author yadu@redhat.com
  # @case_id OCP-16732
  @admin
  Scenario: Check haproxy.config when overwriting 'timeout server' which was already specified
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    And all pods in the project are ready
    When I expose the "test-service" service
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                     |
      | resourcename | test-service                              |
      | keyval       | haproxy.router.openshift.io/timeout=5s    |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    Given a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I execute on the "<%=cb.router_pod %>" pod:
      | grep | -A | 12 | <%= cb.proj_name %>:test-service | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain 1 times:
      | timeout server  5s |
