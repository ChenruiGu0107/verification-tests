Feature: Testing haproxy router

  # @author zzhao@redhat.com
  # @case_id 512275
  @admin
  Scenario: HTTP response header should return for default haproxy 503
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And I execute on the pod:
      | /usr/bin/curl | -v  | 127.0.0.1:80 |
    Then the output should contain "HTTP/1.0 503 Service Unavailable"

  # @author zzhao@redhat.com
  # @case_id 510357
  @admin
  Scenario: Should expose the status monitoring endpoint for haproxy router
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And I execute on the pod:
      | /usr/bin/curl |  127.0.0.1:1936/healthz |
    Then the output should contain "Service ready"

  # @author bmeng@redhat.com
  # @case_id 505814
  @admin
  Scenario: The routekey should use underline instead of dash as connector
    Given I have a project
    And evaluation of `project.name` is stored in the :pj_name clipboard
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc505814/route_unsecure.json|
    Then the step should succeed
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc505814/route_edge.json|
    Then the step should succeed
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc505814/route_reencrypt.json|
    Then the step should succeed
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc505814/route_pass.json|
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | cat |
      | os_http_be.map |
    Then the output should contain "<%= cb.pj_name %>_route"
    When I execute on the "<%= cb.router_pod %>" pod:
      | cat |
      | os_edge_http_be.map |
    Then the output should contain "<%= cb.pj_name %>_secured-edge-route"
    When I execute on the "<%= cb.router_pod %>" pod:
      | cat |
      | os_reencrypt.map |
    Then the output should contain "<%= cb.pj_name %>_route-reencrypt"
    When I execute on the "<%= cb.router_pod %>" pod:
      | cat |
      | os_tcp_be.map |
    Then the output should contain "<%= cb.pj_name %>_route-passthrough"

  # @author bmeng@redhat.com
  # @case_id 483197
  @admin
  Scenario: Only the certs file of the certain route will be updated when the route is updated
    Given I have a project
    And evaluation of `project.name` is stored in the :project clipboard

    # create two routes which will contain cert files
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.key"
    When I run the :create_route_reencrypt client command with:
      | name | route-reen |
      | hostname | <%= rand_str(5, :dns) %>.reen.com |
      | service | service-secure |
      | cert | route_reencrypt-reen.example.com.crt |
      | key | route_reencrypt-reen.example.com.key |
      | cacert | route_reencrypt.ca |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name | route-edge |
      | hostname | <%= rand_str(5, :dns) %>.edge.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
    Then the step should succeed

    # get the cert files creation time on router pod
    When I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | ls |
      | --full-time |
      | /var/lib/containers/router/certs/<%= cb.project %>_route-edge.pem |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :edge_cert clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | ls |
      | --full-time |
      | /var/lib/containers/router/certs/<%= cb.project %>_route-reen.pem |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :reen_cert clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | ls |
      | --full-time |
      | /var/lib/containers/router/cacerts/<%= cb.project %>_route-reen.pem |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :reen_cacert clipboard

    # update one of the routes
    Given I switch to the first user
    And I use the "<%= cb.project %>" project
    When I run the :patch client command with:
      | resource | route |
      | resource_name | route-reen |
      | p | {"spec": {"host": "<%= rand_str(5, :dns) %>.reen2.com"}} |
    Then the step should succeed

    # check only the cert files for the updated route are changed
    When I switch to cluster admin pseudo user
    And I use the "default" project
    When I execute on the "<%= cb.router_pod %>" pod:
      | ls |
      | --full-time |
      | /var/lib/containers/router/certs/<%= cb.project %>_route-reen.pem |
    Then the step should succeed
    And the expression should be true> cb.reen_cert != @result[:response]
    When I execute on the "<%= cb.router_pod %>" pod:
      | ls |
      | --full-time |
      | /var/lib/containers/router/cacerts/<%= cb.project %>_route-reen.pem |
    Then the step should succeed
    And the expression should be true> cb.reen_cacert != @result[:response]
    When I execute on the "<%= cb.router_pod %>" pod:
      | ls |
      | --full-time |
      | /var/lib/containers/router/certs/<%= cb.project %>_route-edge.pem |
    Then the step should succeed
    And the expression should be true> cb.edge_cert == @result[:response]

  # @author bmeng@redhat.com
  # @case_id 489261
  Scenario: haproxy cookies based sticky session for unsecure routes
    #create route and service which has two endpoints
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker-2.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed

    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json |
    And the pod named "hello-pod" becomes ready
    #access the route without cookies
    When I execute on the "<%= pod.name %>" pod:
      | curl |
      | -s |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
      | -c |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response]` is stored in the :first_access clipboard
    Given I wait for the steps to pass:
    """
    When I execute on the "<%= pod.name %>" pod:
      | curl |
      | -s |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access != @result[:response]
    """
    #access the route with cookies
    Given I run the steps 6 times:
    """
    When I execute on the "<%= pod.name %>" pod:
      | curl |
      | -s |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
      | -b |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access == @result[:response]
    """

  # @author bmeng@redhat.com
  # @case_id 489258
  Scenario: haproxy cookies based sticky session for edge termination routes
    #create route and service which has two endpoints
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker-2.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/example_wildcard.pem"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/example_wildcard.key"
    When I run the :create_route_edge client command with:
      | name | route-edge |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | example_wildcard.pem |
      | key | example_wildcard.key |
    Then the step should succeed

    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json |
    And the pod named "hello-pod" becomes ready
    When I execute on the "<%= pod.name %>" pod:
      | wget |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem |
      | -O |
      | /tmp/ca.pem |
    Then the step should succeed
    #access the route without cookies
    When I execute on the "<%= pod.name %>" pod:
      | curl |
      | -s |
      | --resolve |
      | <%= route("route-edge", service("route-edge")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
      | -c |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response]` is stored in the :first_access clipboard
    Given I wait for the steps to pass:
    """
    When I execute on the "<%= pod.name %>" pod:
      | curl |
      | -s |
      | --resolve |
      | <%= route("route-edge", service("route-edge")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access != @result[:response]
    """
    #access the route with cookies
    Given I run the steps 6 times:
    """
    When I execute on the "<%= pod.name %>" pod:
      | curl |
      | -s |
      | --resolve |
      | <%= route("route-edge", service("route-edge")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
      | -b |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access == @result[:response]
    """

  # @author bmeng@redhat.com
  # @case_id 489259
  Scenario: haproxy cookies based sticky session for reencrypt termination routes
    #create route and service which has two endpoints
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker-2.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/service_secure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/example_wildcard.pem"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/example_wildcard.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt.ca"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name | route-reencrypt |
      | hostname | <%= rand_str(5, :dns) %>-reen.example.com |
      | service | service-secure |
      | cert | example_wildcard.pem |
      | key | example_wildcard.key |
      | cacert | route_reencrypt.ca |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed

    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json |
    And the pod named "hello-pod" becomes ready
    When I execute on the "<%= pod.name %>" pod:
      | wget |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem |
      | -O |
      | /tmp/ca.pem |
    Then the step should succeed
    #access the route without cookies
    When I execute on the "<%= pod.name %>" pod:
      | curl |
      | -s |
      | --resolve |
      | <%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
      | -c |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response]` is stored in the :first_access clipboard
    Given I wait for the steps to pass:
    """
    When I execute on the "<%= pod.name %>" pod:
      | curl |
      | -s |
      | --resolve |
      | <%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access != @result[:response]
    """
    #access the route with cookies
    Given I run the steps 6 times:
    """
    When I execute on the "<%= pod.name %>" pod:
      | curl |
      | -s |
      | --resolve |
      | <%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
      | -b |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access == @result[:response]
    """

  # @author zzhao@redhat.com
  # @case_id 483530
  @admin
  @destructive
  Scenario: Router stats can be accessed if just provide password
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    And an 10 characters random string of type :dns is stored into the :password clipboard
    When I run the :env client command with:
      | resource | dc/router |
      | e        | STATS_PASSWORD=<%= cb.password %>  |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    When a pod becomes ready with labels:
      | deploymentconfig=router |
    And I execute on the pod:
      | curl |
      |  -s  |
      |  -w  |
      |  %{http_code} |
      |  -u  |
      |  admin:<%= cb.password %> |
      |  127.0.0.1:1936  |
      |  -o  |
      |  /dev/null| 
    Then the output should match "200"

  # @author zzhao@redhat.com
  # @case_id 528266
  @admin
  @destructive
  Scenario: router should be able to skip invalid cert route
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | EXTENDED_VALIDATION=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
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

    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json |
    And the pod named "hello-pod" becomes ready
    Given I execute on the "<%= pod.name %>" pod:
      | wget |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem |
      | -O |
      | /tmp/ca.pem |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
      | cacert | ca.pem |
    Then the step should succeed
    When I execute on the "<%= pod.name %>" pod:
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
    Then the output should contain 10 times:
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
    When I execute on the "<%= pod.name %>" pod:
      | curl |
      | --resolve |
      | <%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"
