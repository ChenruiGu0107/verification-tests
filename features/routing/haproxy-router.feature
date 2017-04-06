Feature: Testing haproxy router

  # @author zzhao@redhat.com
  # @case_id OCP-9736
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
  # @case_id OCP-9684
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
  # @case_id OCP-9633
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
  # @case_id OCP-12557
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
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem"
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
      | cacert | ca.pem |
    Then the step should succeed

    # get the cert files creation time on router pod
    When I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash |
      | -lc |
      | ls --full-time /var/lib/*/router/certs/<%= cb.project %>_route-edge.pem |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :edge_cert clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash |
      | -lc |
      | ls --full-time /var/lib/*/router/certs/<%= cb.project %>_route-reen.pem |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :reen_cert clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash |
      | -lc |
      | ls --full-time /var/lib/*/router/cacerts/<%= cb.project %>_route-reen.pem |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :reen_cacert clipboard

    # update one of the routes
    Given I switch to the first user
    And I use the "<%= cb.project %>" project
    When I run the :patch client command with:
      | resource | route |
      | resource_name | route-reen |
      | p | {"spec": {"path": "/test"}} |
    Then the step should succeed

    # check only the cert files for the updated route are changed
    When I switch to cluster admin pseudo user
    And I use the "default" project
    And I wait up to 10 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash |
      | -lc |
      | ls --full-time /var/lib/*/router/certs/<%= cb.project %>_route-reen.pem |
    Then the step should succeed
    And the expression should be true> cb.reen_cert != @result[:response]
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash |
      | -lc |
      | ls --full-time /var/lib/*/router/cacerts/<%= cb.project %>_route-reen.pem |
    Then the step should succeed
    And the expression should be true> cb.reen_cacert != @result[:response]
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash |
      | -lc |
      | ls --full-time /var/lib/*/router/certs/<%= cb.project %>_route-edge.pem |
    Then the step should succeed
    And the expression should be true> cb.edge_cert == @result[:response]

  # @author bmeng@redhat.com
  # @case_id OCP-11903
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

    Given I have a pod-for-ping in the project
    #access the route without cookies
    When I execute on the pod:
      | curl |
      | -sS |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
      | -c |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response]` is stored in the :first_access clipboard
    Given I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access != @result[:response]
    """
    #access the route with cookies
    Given I run the steps 6 times:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
      | -b |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access == @result[:response]
    """

  # @author bmeng@redhat.com
  # @case_id OCP-11130
  Scenario: haproxy cookies based sticky session for edge termination routes
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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name | route-edge |
      | service | service-unsecure |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    #access the route without cookies
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
      | -c |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response]` is stored in the :first_access clipboard
    Given I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access != @result[:response]
    """
    #access the route with cookies
    Given I run the steps 6 times:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
      | -b |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access == @result[:response]
    """

  # @author hongli@redhat.com 
  # @case_id OCP-10207
  Scenario: Should use the same cookies for secure and insecure access when insecureEdgeTerminationPolicy set to allow for edge route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker-2.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name            | route-edge              |
      | service         | service-unsecure        |
      | insecure_policy | Allow                   |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
      | -c |
      | /tmp/cookie |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response]` is stored in the :first_access clipboard

    Given I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access != @result[:response]
    """

    #access the insecure edge route with cookies
    Given I run the steps 6 times:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | http://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -b |
      | /tmp/cookie |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access == @result[:response]
    """

    # set to Redirect policy
    When I run the :patch client command with:
      | resource      | route                                                           |
      | resource_name | route-edge                                                      |
      | p             | {"spec":{"tls": { "insecureEdgeTerminationPolicy":"Redirect"}}} |
    Then the step should succeed

    #access the insecure edge route with cookies
    Given I run the steps 6 times:
    """
    When I execute on the pod:
      | curl |
      | -ksSL |
      | http://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -b |
      | /tmp/cookie |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access == @result[:response]
    """

  # @author bmeng@redhat.com
  # @case_id OCP-11492
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

    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    #access the route without cookies
    When I execute on the pod:
      | curl |
      | -sS |
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
    When I execute on the pod:
      | curl |
      | -sS |
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
    When I execute on the pod:
      | curl |
      | -sS |
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
  # @case_id OCP-12553
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
      |  -sS  |
      |  -w  |
      |  %{http_code} |
      |  -u  |
      |  admin:<%= cb.password %> |
      |  127.0.0.1:1936  |
      |  -o  |
      |  /dev/null|
    Then the output should match "200"

  # @author zzhao@redhat.com
  # @case_id OCP-12569
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

  # @author bmeng@redhat.com
  # @case_id OCP-11583
  @admin
  @destructive
  Scenario: Router with specific ROUTE_LABELS will only work for specific routes
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTE_LABELS=router=router1 |
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
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem"
    When I run the :create_route_edge client command with:
      | name | route-edge |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
      | cacert | ca.pem |      
    Then the step should succeed

    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    When I open web server via the "http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/" url
    Then the output should not contain "Hello-OpenShift"
    When I execute on the "hello-pod" pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-edge", service("route-edge")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"

    When I run the :label client command with:
      | resource | route |
      | name | service-unsecure |
      | key_val | router=router1 |
    Then the step should succeed
    And I wait up to 15 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/" url
    Then the output should contain "Hello-OpenShift"
    """
    When I run the :label client command with:
      | resource | route |
      | name | route-edge |
      | key_val | router=router1 |
    Then the step should succeed
    And I wait up to 15 seconds for the steps to pass:
    """
    When I execute on the "hello-pod" pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-edge", service("route-edge")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-10763
  @admin
  @destructive
  Scenario: Haproxy router health check via stats port specified by user
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And evaluation of `rand(32000..64000)` is stored in the :stats_port clipboard
    Given default router replica count is restored after scenario
    And admin ensures "tc-516834" dc is deleted after scenario
    And admin ensures "tc-516834" service is deleted after scenario
    When I run the :scale client command with:
      | resource | dc |
      | name | router |
      | replicas | 0 |
    Then the step should succeed
    When I run the :oadm_router admin command with:
      | name | tc-516834 |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | stats_port | <%= cb.stats_port %> |
      | service_account | router |
    And a pod becomes ready with labels:
      | deploymentconfig=tc-516834 |
    When I execute on the pod:
      | /usr/bin/curl |  127.0.0.1:<%= cb.stats_port %>/healthz |
    Then the output should contain "Service ready"

  # @author bmeng@redhat.com
  # @case_id OCP-11559
  @admin
  @destructive
  Scenario: The correct route info should be reported back to user when there are multiple routers
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    Given environment has at least 2 schedulable nodes
    And default router replica count is restored after scenario
    When I run the :scale client command with:
      | resource | dc |
      | name | router |
      | replicas | 0 |
    Then the step should succeed
    Given an 8 characters random string of type :dns952 is stored into the :router1_name clipboard
    And an 8 characters random string of type :dns952 is stored into the :router2_name clipboard
    And admin ensures "<%= cb.router1_name %>" dc is deleted after scenario
    And admin ensures "<%= cb.router1_name %>" service is deleted after scenario
    And admin ensures "<%= cb.router2_name %>" dc is deleted after scenario
    And admin ensures "<%= cb.router2_name %>" service is deleted after scenario
    When I run the :oadm_router admin command with:
      | name | <%= cb.router1_name %> |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | force_subdomain | ${name}-${namespace}.apps.aaa.com |
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.router1_name %> |
    And evaluation of `pod.ip` is stored in the :router1_ip clipboard
    When I run the :oadm_router admin command with:
      | name | <%= cb.router2_name %> |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | force_subdomain | ${name}-${namespace}.apps.zzz.com |
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.router2_name %> |
    And evaluation of `pod.ip` is stored in the :router2_ip clipboard

    Given I switch to the first user
    And I have a project
    And evaluation of `project.name` is stored in the :project clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | route |
      | name | service-unsecure |
    Then the output should contain "service-unsecure-<%= cb.project %>.apps.aaa.com exposed on router <%= cb.router1_name %>"
    And the output should contain "service-unsecure-<%= cb.project %>.apps.zzz.com exposed on router <%= cb.router2_name %>"
    And the output should match "Endpoints:.*\d+.\d+.\d+.\d+:\d"
    """
    When I run the :get client command with:
      | resource | route |
      | resource_name | service-unsecure |
    Then the step should succeed
    And the output should match "apps.[az][az][az].com.*more"
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | --resolve |
      | service-unsecure-<%= cb.project %>.apps.aaa.com:80:<%= cb.router1_ip %> |
      | http://service-unsecure-<%= cb.project %>.apps.aaa.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    When I execute on the pod:
      | curl |
      | --resolve |
      | service-unsecure-<%= cb.project %>.apps.zzz.com:80:<%= cb.router1_ip %> |
      | http://service-unsecure-<%= cb.project %>.apps.zzz.com/ |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"
    When I execute on the pod:
      | curl |
      | --resolve |
      | service-unsecure-<%= cb.project %>.apps.aaa.com:80:<%= cb.router2_ip %> |
      | http://service-unsecure-<%= cb.project %>.apps.aaa.com:80/ |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"
    When I execute on the pod:
      | curl |
      | --resolve |
      | service-unsecure-<%= cb.project %>.apps.zzz.com:80:<%= cb.router2_ip %> |
      | http://service-unsecure-<%= cb.project %>.apps.zzz.com:80/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-11549
  @admin
  @destructive
  Scenario: Haproxy router health check will use 1936 port if user disable the stats port
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Given default router replica count is restored after scenario
    And admin ensures "tc-516836" dc is deleted after scenario
    And admin ensures "tc-516836" service is deleted after scenario
    When I run the :scale client command with:
      | resource | dc |
      | name | router |
      | replicas | 0 |
    Then the step should succeed
    When I run the :oadm_router admin command with:
      | name | tc-516836 |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | stats_port | 0 |
      | service_account | router |
    And a pod becomes ready with labels:
      | deploymentconfig=tc-516836 |
    When I execute on the pod:
      | /usr/bin/curl |  127.0.0.1:1936/healthz |
    Then the output should contain "Service ready"

  # @author zzhao@redhat.com
  # @case_id OCP-12554
  @admin
  @destructive
  Scenario: User can access router stats using the specified port and username/pass
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And evaluation of `rand(32000..64000)` is stored in the :stats_port clipboard
    Given default router replica count is restored after scenario
    And admin ensures "tc-483532" dc is deleted after scenario
    And admin ensures "tc-483532" service is deleted after scenario
    When I run the :scale client command with:
      | resource | dc |
      | name | router |
      | replicas | 0 |
    Then the step should succeed
    When I run the :oadm_router admin command with:
      | name | tc-483532 |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | stats_port | <%= cb.stats_port %> |
      | stats_user | tc483532 |
      | stats_passwd | 483532tc |
      | service_account | router |
    And a pod becomes ready with labels:
      | deploymentconfig=tc-483532 |
    When I execute on the pod:
      | /usr/bin/curl |
      |  -sS  |
      |  -w  |
      |  %{http_code} |
      |  -u  |
      |  tc483532:483532tc |
      |  127.0.0.1:<%= cb.stats_port %> |
      |  -o  |
      |  /dev/null|
    Then the output should match "200"
    When I execute on the pod:
      | /usr/bin/curl |
      |  -sS  |
      |  -w  |
      |  %{http_code} |
      |  -u  |
      |  tc483532:wrong |
      |  127.0.0.1:<%= cb.stats_port %> |
      |  -o  |
      |  /dev/null|
    Then the output should match "401"


  # @author zzhao@redhat.com
  # @case_id OCP-12552
  @admin
  @destructive
  Scenario: router stats's password will be shown if creating router without providing stats password
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And evaluation of `rand(32000..64000)` is stored in the :stats_port clipboard
    Given default router replica count is restored after scenario
    And admin ensures "tc-483529" dc is deleted after scenario
    And admin ensures "tc-483529" service is deleted after scenario
    When I run the :scale client command with:
      | resource | dc |
      | name | router |
      | replicas | 0 |
    Then the step should succeed
    When I run the :oadm_router admin command with:
      | name | tc-483529 |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | stats_port | <%= cb.stats_port %> |
      | stats_user | tc483529|
      | service_account | router |
    And evaluation of `@result[:response]` is stored in the :router_output clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=tc-483529|
    When I execute on the pod:
      | bash |
      | -c |
      | echo -n "$STATS_PASSWORD" |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :stats_password clipboard
    Then the expression should be true> cb.router_output.include?(cb.stats_password)
    When I execute on the pod:
      | /usr/bin/curl |
      |  -sS  |
      |  -w  |
      |  %{http_code} |
      |  -u  |
      |  tc483529:<%= cb.stats_password %> |
      |  127.0.0.1:<%= cb.stats_port %> |
      |  -o  |
      |  /dev/null|
    Then the output should match "200"

  # @author bmeng@redhat.com
  # @case_id OCP-10841
  @admin
  @destructive
  Scenario: Route should be moved to the correct router once the label changed
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    Given environment has at least 2 schedulable nodes
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Given default router replica count is restored after scenario
    And admin ensures "router-label-red" dc is deleted after scenario
    And admin ensures "router-label-red" service is deleted after scenario
    And admin ensures "router-label-blue" dc is deleted after scenario
    And admin ensures "router-label-blue" service is deleted after scenario
    When I run the :scale client command with:
      | resource | dc |
      | name | router |
      | replicas | 0 |
    Then the step should succeed
    When I run the :oadm_router admin command with:
      | name | router-label-red |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
    Then a pod becomes ready with labels:
      | deploymentconfig=router-label-red |
    When I run the :env client command with:
      | resource | dc/router-label-red |
      | e | ROUTE_LABELS=router=red |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=router-label-red-2 |
    And evaluation of `pod.ip` is stored in the :router_red_ip clipboard
    When I run the :oadm_router admin command with:
      | name | router-label-blue |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
    Then a pod becomes ready with labels:
      | deploymentconfig=router-label-blue |
    When I run the :env client command with:
      | resource | dc/router-label-blue |
      | e | ROUTE_LABELS=router=blue |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=router-label-blue-2 |
    And evaluation of `pod.ip` is stored in the :router_blue_ip clipboard

    Given I switch to the first user
    And I have a project
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
    When I run the :create_route_reencrypt client command with:
      | name | route-reen |
      | hostname | <%= rand_str(5, :dns) %>-reen.example.com |
      | service | service-secure |
      | cert | route_reencrypt-reen.example.com.crt |
      | key | route_reencrypt-reen.example.com.key |
      | cacert | route_reencrypt.ca |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    When I run the :label client command with:
      | resource | route |
      | name | route-reen |
      | key_val | router=red |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    When I execute on the "hello-pod" pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-reen", service("route-reen")).dns(by: user) %>:443:<%= cb.router_red_ip %> |
      | https://<%= route("route-reen", service("route-reen")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"
    When I execute on the "hello-pod" pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-reen", service("route-reen")).dns(by: user) %>:443:<%= cb.router_blue_ip %> |
      | https://<%= route("route-reen", service("route-reen")).dns(by: user) %>:443/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should not contain "Hello-OpenShift"

    When I run the :label client command with:
      | resource | route |
      | name | route-reen |
      | key_val | router=blue |
      | overwrite | true |
    Then the step should succeed
    When I execute on the "hello-pod" pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-reen", service("route-reen")).dns(by: user) %>:443:<%= cb.router_red_ip %> |
      | https://<%= route("route-reen", service("route-reen")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should not contain "Hello-OpenShift"
    When I execute on the "hello-pod" pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-reen", service("route-reen")).dns(by: user) %>:443:<%= cb.router_blue_ip %> |
      | https://<%= route("route-reen", service("route-reen")).dns(by: user) %>:443/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-12555
  @admin
  @destructive
  Scenario: router cannot be running if the stats port was occupied
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Given default router replica count is restored after scenario
    And admin ensures "tc-483533" dc is deleted after scenario
    And admin ensures "tc-483533" service is deleted after scenario
    When I run the :scale client command with:
      | resource | dc     |
      | name     | router |
      | replicas | 0      |
    Then the step should succeed

    When I run the :oadm_router admin command with:
      | name | tc-483533 |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | stats_port | 22 |
      | service_account | router |
    Then I wait up to 50 seconds for the steps to pass:
    """
    When I get project events
    And the output should match:
      | Readiness probe failed: .*:22/healthz: malformed HTTP response "SSH |
    """

  # @author bmeng@redhat.com
  # @case_id OCP-11275
  @admin
  @destructive
  Scenario: Router with specific NAMESPACE_LABELS will only work for specific namespaces
    Given I have a project
    And evaluation of `project.name` is stored in the :project_red clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :project_blue clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :project_nolabel clipboard

    Given I switch to cluster admin pseudo user
    When I run the :label client command with:
      | resource | namespaces |
      | name | <%= cb.project_red %> |
      | key_val | team=red |
    Then the step should succeed
    When I run the :label client command with:
      | resource | namespaces |
      | name | <%= cb.project_blue %> |
      | key_val | team=blue |
    Then the step should succeed

    Given I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And cluster role "cluster-reader" is added to the "system:serviceaccount:default:router" service account
    And default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | NAMESPACE_LABELS=team=red |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And evaluation of `pod.ip` is stored in the :router_ip clipboard

    Given I switch to the first user
    And I use the "<%= cb.project_red %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name | route-pass |
      | hostname | <%= rand_str(5, :dns) %>-pass.example.com |
      | service | service-secure |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    When I execute on the "hello-pod" pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-pass", service("route-pass")).dns(by: user) %>:443:<%= cb.router_ip %> |
      | https://<%= route("route-pass", service("route-pass")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

    And I use the "<%= cb.project_blue %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name | route-pass |
      | hostname | <%= rand_str(5, :dns) %>-pass.example.com |
      | service | service-secure |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    When I execute on the "hello-pod" pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-pass", service("route-pass")).dns(by: user) %>:443:<%= cb.router_ip %> |
      | https://<%= route("route-pass", service("route-pass")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the step should fail
    And the output should not contain "Hello-OpenShift"

    And I use the "<%= cb.project_nolabel %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name | route-pass |
      | hostname | <%= rand_str(5, :dns) %>-pass.example.com |
      | service | service-secure |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    When I execute on the "hello-pod" pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-pass", service("route-pass")).dns(by: user) %>:443:<%= cb.router_ip %> |
      | https://<%= route("route-pass", service("route-pass")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the step should fail
    And the output should not contain "Hello-OpenShift"


  # @author yadu@redhat.com
  # @case_id OCP-10779
  @admin
  @destructive
  Scenario: Set invalid reload time for haproxy router script
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Given default router replica count is restored after scenario
    And admin ensures "tc-518936" dc is deleted after scenario
    And admin ensures "tc-518936" service is deleted after scenario
    When I run the :scale client command with:
      | resource | dc     |
      | name     | router |
      | replicas | 0      |
    Then the step should succeed
    When I run the :oadm_router admin command with:
      | name   | tc-518936                                               |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
    Then a pod becomes ready with labels:
      | deploymentconfig=tc-518936 |
    When I run the :env client command with:
      | resource | dc/tc-518936   |
      | e | RELOAD_INTERVAL=-100s |
    Then the step should succeed
    And I wait until number of replicas match "1" for replicationController "tc-518936-2"
    Given I store in the clipboard the pods labeled:
      | deployment=tc-518936-2 |
    When I run the :logs client command with:
      | resource_name| pods/<%= cb.pods[0].name%> |
    Then the output should contain:
      | must be a positive duration |
    When I run the :env client command with:
      | resource | dc/tc-518936 |
      | e | RELOAD_INTERVAL=abc |
    Then the step should succeed
    And I wait until number of replicas match "1" for replicationController "tc-518936-3"
    Given I store in the clipboard the pods labeled:
      | deployment=tc-518936-3 |
    When I run the :logs client command with:
      | resource_name| pods/<%= cb.pods[0].name%> |
    Then the output should contain:
      | Invalid RELOAD_INTERVAL |

  # @author zzhao@redhat.com
  # @case_id OCP-12572 OCP-12935
  @admin
  @destructive
  Scenario: Be able to create multi router in same node via setting port with hostnetwork network mode
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    Given default router replica count is stored in the :router_num clipboard
    Given admin stores in the :router_node clipboard the nodes backing pods in project "default" labeled:
      | deploymentconfig=router |

    And evaluation of `rand(32000..64000)` is stored in the :stats_port clipboard
    And evaluation of `rand(32000..64000)` is stored in the :http_port clipboard
    And evaluation of `rand(32000..64000)` is stored in the :https_port clipboard
    And I register clean-up steps:
    """
    Given I run commands on the nodes in the :router_node clipboard:
      | iptables -D INPUT -p tcp --dport <%= cb.http_port %> -j ACCEPT      |
      | iptables -D INPUT -p tcp --dport <%= cb.https_port %> -j ACCEPT     |
      | iptables -D INPUT -p tcp --dport <%= cb.stats_port %> -j ACCEPT     |
    Then the step should succeed
    """
    Given I run commands on the nodes in the :router_node clipboard:
      | iptables -I INPUT -p tcp --dport <%= cb.http_port %> -j ACCEPT      |
      | iptables -I INPUT -p tcp --dport <%= cb.https_port %> -j ACCEPT     |
      | iptables -I INPUT -p tcp --dport <%= cb.stats_port %> -j ACCEPT     |
    Then the step should succeed

    Given admin ensures "tc-531375" dc is deleted after scenario
    And admin ensures "tc-531375" service is deleted after scenario
    When I run the :oadm_router admin command with:
      | name | tc-531375 |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | stats_port | <%= cb.stats_port %> |
      | replicas | <%= cb.router_num %> |
      | ports | <%= cb.http_port %>:<%= cb.http_port %>,<%= cb.https_port %>:<%= cb.https_port %> |
    When I run the :env client command with:
      | resource | dc/tc-531375 |
      | e        | ROUTER_SERVICE_HTTP_PORT=<%= cb.http_port %>    |
      | e        | ROUTER_SERVICE_HTTPS_PORT=<%= cb.https_port %>  |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=tc-531375-2 |
    Given I use the "tc-531375" service
    And evaluation of `service.ip(user: user)` is stored in the :router_service_ip clipboard

    Given I switch to the first user
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/dc.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/header-test/insecure-service.json |
    Then the step should succeed
    When I expose the "header-test-insecure" service
    Then the step should succeed
    When I wait for a web server to become available via the route
    Then the output should contain "<%= route.dns(by: user) %>"
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route.dns(by: user) %>:<%= cb.http_port %>:<%= cb.router_service_ip %> |
      | http://<%= route.dns(by: user) %>:<%= cb.http_port %>/ |
    Then the step should succeed 
    And the output should contain "<%= route.dns(by: user) %>:<%= cb.http_port %>"

    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | header-test-insecure |
    Then the step should succeed
    When I wait up to 20 seconds for a secure web server to become available via the "edge-route" route
    Then the output should contain "<%= route("edge-route", service("header-test-insecure")).dns(by: user) %>"

    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("edge-route", service("service-unsecure")).dns(by: user) %>:<%= cb.https_port %>:<%= cb.router_service_ip %> |
      | https://<%= route("edge-route", service("service-unsecure")).dns(by: user) %>:<%= cb.https_port %> |
      | -k |
    Then the output should contain "<%= route("edge-route", service("header-test-insecure")).dns(by: user) %>:<%= cb.https_port %>"

  # @author zzhao@redhat.com
  # @case_id OCP-12651
  @admin
  @destructive
  Scenario: The route auto generated can be accessed using the default cert
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Given default router replica count is restored after scenario
    And admin ensures "tc-500001" dc is deleted after scenario
    And admin ensures "tc-500001" service is deleted after scenario
    When I run the :scale client command with:
      | resource | dc |
      | name | router |
      | replicas | 0 |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/default-router.pem"
    When I run the :oadm_router admin command with:
      | name | tc-500001|
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | default_cert | default-router.pem |
    And a pod becomes ready with labels:
      | deploymentconfig=tc-500001|
    And evaluation of `pod.ip` is stored in the :router_default_cert clipboard

    Given I switch to the first user
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name | route-edge |
      | service | service-unsecure |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | wget |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/default-router.pem |
      | -O |
      | /tmp/default-router.pem |
    Then the step should succeed
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-edge", service("service-unsecure")).dns(by: user) %>:443:<%= cb.router_default_cert %> |
      | https://<%= route("route-edge", service("service-unsecure")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/default-router.pem |
    Then the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-12565
  @admin
  @destructive
  Scenario: Router can work well with container network stack
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    Given default router replica count is stored in the :router_num clipboard
    Given admin stores in the :router_node clipboard the nodes backing pods in project "default" labeled:
      | deploymentconfig=router |
    And default router replica count is restored after scenario
    When I run the :scale client command with:
      | resource | dc |
      | name | router |
      | replicas | 0 |
    Then the step should succeed
    Given admin ensures "tc-498716" dc is deleted after scenario
    And admin ensures "tc-498716" service is deleted after scenario
    When I run the :oadm_router admin command with:
      | name | tc-498716 |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | host_network | false |
      | replicas | <%= cb.router_num %> |
    And a pod becomes ready with labels:
      | deploymentconfig=tc-498716 |
    And evaluation of `pod.ip` is stored in the :router_ip clipboard

    Given I switch to the first user
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
    When I wait up to 15 seconds for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"

    #edge route
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | service-unsecure |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    When I execute on the pod:
      | curl |
      | https:// <%= route("edge-route", service("service-unsecure")).dns(by: user) %> |
      | -k |
    Then the output should contain "Hello-OpenShift"

    #passthrough route
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
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
      | <%= route("passthrough-route", service("passthrough-route")).dns(by: user) %>:443:<%= cb.router_ip %> |
      | https://<%= route("passthrough-route", service("passthrough-route")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"
    """
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
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>:443:<%= cb.router_ip %> |
      | https://<%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-12567
  @admin
  Scenario: Unable to create router with host networking mode when mapping ports are different
    When I run the :oadm_router admin command with:
      | name | router-test |
      | host_network | true |
      | ports | 1080:1081,10443:10444 |
    Then the step should fail
    And the output should contain "must be equal"

  # @author bmeng@redhat.com
  # @case_id OCP-10903
  @admin
  Scenario: The router pod should have default resource limits
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    When I run the :get client command with:
      | resource | pod |
      | l | deploymentconfig=router |
      | o | yaml |
    Then the expression should be true> @result[:parsed]['items'][0]['spec']['containers'][0]['resources']['requests'].include?("cpu")
    Then the expression should be true> @result[:parsed]['items'][0]['spec']['containers'][0]['resources']['requests'].include?("memory")

  # @author zzhao@redhat.com
  # @case_id OCP-12568
  @admin
  @destructive
  Scenario: Be able to create multi router via setting port with container network mode
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    Given default router replica count is stored in the :router_num clipboard
    Given admin stores in the :router_node clipboard the nodes backing pods in project "default" labeled:
      | deploymentconfig=router |

    And evaluation of `rand(52001..64000)` is stored in the :stats_port clipboard
    And evaluation of `rand(32000..42000)` is stored in the :http_port clipboard
    And evaluation of `rand(42001..52000)` is stored in the :https_port clipboard
    And I register clean-up steps:
    """
    Given I run commands on the nodes in the :router_node clipboard:
      | iptables -D INPUT -p tcp --dport <%= cb.http_port %> -j ACCEPT      |
      | iptables -D INPUT -p tcp --dport <%= cb.https_port %> -j ACCEPT     |
      | iptables -D INPUT -p tcp --dport <%= cb.stats_port %> -j ACCEPT     |
    Then the step should succeed
    """
    Given I run commands on the nodes in the :router_node clipboard:
      | iptables -I INPUT -p tcp --dport <%= cb.http_port %> -j ACCEPT      |
      | iptables -I INPUT -p tcp --dport <%= cb.https_port %> -j ACCEPT     |
      | iptables -I INPUT -p tcp --dport <%= cb.stats_port %> -j ACCEPT     |
    Then the step should succeed

    Given admin ensures "tc-520314" dc is deleted after scenario
    And admin ensures "tc-520314" service is deleted after scenario
    When I run the :oadm_router admin command with:
      | name | tc-520314 |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | stats_port | <%= cb.stats_port %> |
      | replicas | <%= cb.router_num %> |
      | ports | <%= cb.http_port %>:<%= cb.http_port %>,<%= cb.https_port %>:<%= cb.https_port %> |
      | host_network | false |
    When I run the :env client command with:
      | resource | dc/tc-520314 |
      | e        | ROUTER_SERVICE_HTTP_PORT=<%= cb.http_port %>    |
      | e        | ROUTER_SERVICE_HTTPS_PORT=<%= cb.https_port %>  |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=tc-520314-2 |
    Given I use the "tc-520314" service
    And evaluation of `service.ip(user: user)` is stored in the :router_service_ip clipboard    

    Given I switch to the first user
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

    When I wait up to 15 seconds for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route.dns(by: user) %>:<%= cb.http_port %>:<%= cb.router_service_ip %> |
      | http://<%= route.dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | service-unsecure |
    Then the step should succeed
    When I open secure web server via the "edge-route" route
    Then the output should contain "Hello-OpenShift"
    
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("edge-route", service("service-unsecure")).dns(by: user) %>:<%= cb.https_port %>:<%= cb.router_service_ip %> |
      | https://<%= route("edge-route", service("service-unsecure")).dns(by: user) %>:<%= cb.https_port %> |
      | -k |
    Then the step should succeed    
    Then the output should contain "Hello-OpenShift"
    """

  # @author yadu@redhat.com
  # @case_id OCP-11236
  @admin
  @destructive
  Scenario: Set reload time for haproxy router script - Create routes
    # prepare router
    Given default router is disabled and replaced by a duplicate
    And I switch to cluster admin pseudo user
    And I use the "default" project
    When I run the :env admin command with:
      | resource | dc/<%= cb.new_router_dc.name %>         |
      | e        | RELOAD_INTERVAL=90s                     |
    Then the step should succeed
    And I wait until replicationController "<%= cb.new_router_dc.name %>-2" is ready

    # prepare services
    Given I switch to the default user
    And I have a project
    And I have a pod-for-ping in the project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed

    # create some route and wait for it to be sure we hit a reload point
    When I expose the "service-unsecure" service
    Then the step should succeed
    And I wait up to 95 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl                                                   |
      | -ksS                                                   |
      | --resolve                                              |
      | <%= route("service-unsecure").dns(by: user) %>:80:<%= cb.router_ip[0] %> |
      | http://<%= route("service-unsecure").dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """
    # it is important to use one and the same router
    # And I wait for a web server to become available via the "service-unsecure" route

    # create route and check changes not applied before RELOAD_INTERVAL reached
    When I run the :create_route_edge client command with:
      | name    | edge-route       |
      | service | service-unsecure |
    Then the step should succeed

    And I repeat the steps up to 70 seconds:
    """
    When I execute on the "<%= cb.ping_pod.name %>" pod:
      | curl      |
      | -ksS      |
      | --resolve |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"
    """
    And I wait up to 50 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl      |
      | -ksS      |
      | --resolve |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """
    When I run the :delete client command with:
      | object_type       | route      |
      | object_name_or_id | edge-route |
    Then the step should succeed
    And I repeat the steps up to 70 seconds:
    """
    When I execute on the pod:
      | curl      |
      | -ksS      |
      | --resolve |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """
    And I wait up to 50 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl      |
      | -ksS      |
      | --resolve |
      | <%= route("edge-route", service("edge-route")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route", service("edge-route")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should not contain "Hello-OpenShift"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-11619
  Scenario: Limit the number of TCP connection per IP in specified time period
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name | route-pass |
      | service | service-secure |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | -c | for i in {1..10} ; do curl -ksS --resolve <%= route("route-pass", service("route-pass")).dns(by: user) %>:443:<%= cb.router_ip[0] %> https://<%= route("route-pass", service("route-pass")).dns(by: user) %>/ ; done |
    Then the output should contain 10 times:
      | Hello-OpenShift |
    And the output should not contain "(35)"

    When I run the :annotate client command with:
      | resource | route |
      | resourcename | route-pass |
      | keyval | haproxy.router.openshift.io/rate-limit-connections=true |
      | keyval | haproxy.router.openshift.io/rate-limit-connections.rate-tcp=5 |
    Then the step should succeed

    When I execute on the pod:
      | bash | -c | for i in {1..10} ; do curl -ksS --resolve <%= route("route-pass", service("route-pass")).dns(by: user) %>:443:<%= cb.router_ip[0] %> https://<%= route("route-pass", service("route-pass")).dns(by: user) %>/ ; done |
    Then the output should contain 4 times:
      | Hello-OpenShift |
    And the output should contain 6 times:
      | (35) |

    Given 6 seconds have passed
    When I execute on the pod:
      | bash | -c | for i in {1..10} ; do curl -ksS --resolve <%= route("route-pass", service("route-pass")).dns(by: user) %>:443:<%= cb.router_ip[0] %> https://<%= route("route-pass", service("route-pass")).dns(by: user) %>/ ; done |
    Then the output should contain 4 times:
      | Hello-OpenShift |
    And the output should contain 6 times:
      | (35) |


  # @author yadu@redhat.com
  # @case_id OCP-9695
  @admin
  @destructive
  Scenario: Router(in host networking) in a specific namespace should load balance to pods in any namespace
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    And I store default router IPs in the :router_ip clipboard
    Given a "svcaccount.yaml" file is created with the following lines:
    """
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: dyrouter
    """
    When I run the :create client command with:
      | f | svcaccount.yaml |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Given SCC "privileged" is added to the "dyrouter" service account
    And cluster role "cluster-reader" is added to the "system:serviceaccount:<%= cb.proj1 %>:dyrouter" service account
    And I use the "default" project
    And I store master image version in the clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Given default router replica count is restored after scenario
    When I run the :scale client command with:
      | resource | dc     |
      | name     | router |
      | replicas | 0      |
    Then the step should succeed
    When I run the :oadm_router admin command with:
      | name            | tc-testrouter                                                                    |
      | images          | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | service_account | dyrouter                                                                         |
      | n               | <%= cb.proj1 %>                                                                  |
    Given I switch to the first user
    And I use the "<%= cb.proj1 %>" project
    And admin ensures "tc-testrouter" dc is deleted after scenario
    And admin ensures "tc-testrouter" service is deleted after scenario
    Given I wait for the pod named "tc-testrouter-1-deploy" to die
    And a pod becomes ready with labels:
      | deploymentconfig=tc-testrouter |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :expose client command with:
      | resource      | service      |
      | resource_name | test-service |
      | name          | route1       |
    Then the step should succeed
    When I use the "test-service" service    
    Then I wait up to 15 seconds for a web server to become available via the "route1" route
    And the output should contain "Hello OpenShift"

    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :expose client command with:
      | resource      | service      |
      | resource_name | test-service |
      | name          | route2       |
    Then the step should succeed
    When I use the "test-service" service
    Then I wait up to 15 seconds for a web server to become available via the "route2" route
    And the output should contain "Hello OpenShift"

  # @author yadu@redhat.com
  # @case_id OCP-9655
  @admin
  @destructive
  Scenario: Router(in container networking) in a specific namespace should only load balance to pods in that namespace
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given a "svcaccount.yaml" file is created with the following lines:
    """
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: dyrouter
    """
    When I run the :create client command with:
      | f | svcaccount.yaml |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Given SCC "privileged" is added to the "dyrouter" service account
    And cluster role "cluster-reader" is added to the "system:serviceaccount:<%= cb.proj1 %>:dyrouter" service account
    And I use the "default" project
    And I store master image version in the clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Given default router replica count is restored after scenario
    When I run the :scale client command with:
      | resource | dc     |
      | name     | router |
      | replicas | 0      |
    Then the step should succeed
    When I run the :oadm_router admin command with:
      | name            | tc-testrouter                                                                    |
      | images          | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | service_account | dyrouter                                                                         |
      | n               | <%= cb.proj1 %>                                                                  |
      | host_network    | false                                                                            |
    Given I switch to the first user
    And I use the "<%= cb.proj1 %>" project
    And admin ensures "tc-testrouter" dc is deleted after scenario
    And admin ensures "tc-testrouter" service is deleted after scenario
    Given I wait for the pod named "tc-testrouter-1-deploy" to die
    And a pod becomes ready with labels:
      | deploymentconfig=tc-testrouter |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :expose client command with:
      | resource      | service      |
      | resource_name | test-service |
      | name          | route1       |
    Then the step should succeed
    When I use the "test-service" service    
    Then I wait up to 15 seconds for a web server to become available via the "route1" route
    And the output should contain "Hello OpenShift"

    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :expose client command with:
      | resource      | service      |
      | resource_name | test-service |
      | name          | route2       |    
    Then the step should succeed
    When I open web server via the "http://<%= route("route2", service("test-service")).dns(by: user) %>/" url
    Then the step should fail
    Then the output should not contain "Hello OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-12677
  @admin
  @destructive
  Scenario: router will not expose host port on node if set turn off that option
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    Given default router replica count is stored in the :router_num clipboard
    Given admin stores in the :router_node clipboard the nodes backing pods in project "default" labeled:
      | deploymentconfig=router |
    Given default router replica count is restored after scenario
    When I run the :scale client command with:
      | resource | dc     |
      | name     | router |
      | replicas | 0      |
    Given admin ensures "tc-521765" dc is deleted after scenario
    And admin ensures "tc-521765" service is deleted after scenario
    When I run the :oadm_router admin command with:
      | name | tc-521765 |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | host_network | false |
      | host_ports | false |
      | replicas | <%= cb.router_num %> |
    Then a pod becomes ready with labels:
      | deploymentconfig=tc-521765 |
    Given I run commands on the nodes in the :router_node clipboard:
      | iptables -S -t nat |
    Then the output should not contain:
      | hostport 80   |
      | hostport 443  |
      | hostport 1936 |


  # @author zzhao@redhat.com
  # @case_id OCP-12574
  @admin
  @destructive
  Scenario: haproxy router can support comression by setting the env
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ENABLE_COMPRESSION=true  |
      | e        | ROUTER_COMPRESSION_MIME=text/html text/plain text/css |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    When a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | 
      |  -c  | 
      |  curl -o /dev/null -D - http://<%= route.dns(by: user) %> -H "Accept-Encoding: gzip" | 
    Then the step should succeed
    And the output should contain "Content-Encoding: gzip"
  

  # @author hongli@redhat.com
  # @case_id OCP-12683
  @admin
  @destructive
  Scenario: The health check interval of backend can be set by env variable or annotations
    # set router env (from default 5000ms to 1234ms)  
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And default router deployment config is restored after scenario
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_BACKEND_CHECK_INTERVAL=1234ms |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard

    # create all types of route
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name    | edge-route       |
      | service | service-unsecure |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name    | pass-route     |
      | service | service-secure |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | reen-route              |
      | service    | service-secure          |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    Given 10 seconds have passed
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | -A               |
      | 32               |
      | service-unsecure |
      | haproxy.config   |
    Then the output should match:
      | server.*<%=cb.pod_ip %>:8080 check inter 1234ms cookie .* |
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | -A               |
      | 32               |
      | edge-route       |
      | haproxy.config   |
    Then the output should match:
      | server.*<%=cb.pod_ip %>:8080 check inter 1234ms cookie .* |
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | -A               |
      | 32               |
      | pass-route       |
      | haproxy.config   |
    Then the output should match:
      | server.*<%=cb.pod_ip %>:8443 check inter 1234ms weight 100 |
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | -A               |
      | 32               |
      | reen-route       |
      | haproxy.config   |
    Then the output should match:
      | server.*<%=cb.pod_ip %>:8443 ssl check inter 1234ms verify required ca-file .* |

    # annotate all types of route
    Given I switch to the first user
    When I run the :annotate client command with:
      | resource     | route                                                   |
      | resourcename | service-unsecure                                        |
      | overwrite    | true                                                    |
      | keyval       | router.openshift.io/haproxy.health.check.interval=200ms |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                   |
      | resourcename | edge-route                                              |
      | overwrite    | true                                                    |
      | keyval       | router.openshift.io/haproxy.health.check.interval=300ms |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                   |
      | resourcename | pass-route                                              |
      | overwrite    | true                                                    |
      | keyval       | router.openshift.io/haproxy.health.check.interval=400ms |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                   |
      | resourcename | reen-route                                              |
      | overwrite    | true                                                    |
      | keyval       | router.openshift.io/haproxy.health.check.interval=500ms |
    Then the step should succeed

    # check the backend of route after annotation
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    Given 10 seconds have passed
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | -A               |
      | 32               |
      | service-unsecure |
      | haproxy.config   |
    Then the output should match:
      | server.*<%=cb.pod_ip %>:8080 check inter 200ms cookie .* |
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | -A               |
      | 32               |
      | edge-route       |
      | haproxy.config   |
    Then the output should match:
      | server.*<%=cb.pod_ip %>:8080 check inter 300ms cookie .* |
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | -A               |
      | 32               |
      | pass-route       |
      | haproxy.config   |
    Then the output should match:
      | server.*<%=cb.pod_ip %>:8443 check inter 400ms weight 100 |
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | -A               |
      | 32               |
      | reen-route       |
      | haproxy.config   |
    Then the output should match:
      | server.*<%=cb.pod_ip %>:8443 ssl check inter 500ms verify required ca-file .* |

  # @author zzhao@redhat.com
  # @case_id OCP-10883
  @admin
  @destructive
  Scenario: Set timeout http-request for haproxy
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | i                |                 |
      | oc_opts_end      |                 |
      | exec_command     | nc              |
      | exec_command_arg | -i16            |
      | exec_command_arg | 127.0.0.1       |
      | exec_command_arg | 80              |
      | _stdin           | :empty          |
    Then the output should contain "408 Request Time-out"
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | i                |                 |
      | oc_opts_end      |                 |
      | exec_command     | nc              |
      | exec_command_arg | -i11            |
      | exec_command_arg | 127.0.0.1       |
      | exec_command_arg | 80              |
      | _stdin           | :empty          |
    Then the output should not contain "408 Request Time-out"
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_SLOWLORIS_TIMEOUT=5s |
    Then the step should succeed
    And I wait for the pod named "<%= pod.name %>" to die
    When a pod becomes ready with labels:
      | deploymentconfig=router |
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | i                |                 |
      | oc_opts_end      |                 |
      | exec_command     | nc              |
      | exec_command_arg | -i11            |
      | exec_command_arg | 127.0.0.1       |
      | exec_command_arg | 80              |
      | _stdin           | :empty          |
    Then the output should contain "408 Request Time-out"

  # @author zzhao@redhat.com
  # @case_id OCP-11302
  @admin
  @destructive
  Scenario: haproxy logs can be sent to syslog for hostnetwork mode
    Given admin stores in the :router_node clipboard the nodes backing pods in project "default" labeled:
      | deploymentconfig=router |
    And system verification steps are used:
    """
    Given I run commands on the nodes in the :router_node clipboard:
      | systemctl is-active rsyslog.service |
    Then the step should succeed
    And I run commands on the nodes in the :router_node clipboard:
      | ls /etc/rsyslog.d/haproxy.conf      |
    Then the step should fail
    """

    And I register clean-up steps:
    """
    Given I run commands on the nodes in the :router_node clipboard:
      | rm -f /etc/rsyslog.d/haproxy.conf /var/log/haproxy.log |
      | systemctl restart rsyslog                              |
    Then the step should succeed
    """
    When I run commands on the nodes in the :router_node clipboard:
      | echo -e  "\$ModLoad imudp\n\$UDPServerRun 514\nlocal1.* /var/log/haproxy.log\nhaproxy.* /var/log/haproxy.log" >/etc/rsyslog.d/haproxy.conf |
      | systemctl restart rsyslog |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_SYSLOG_ADDRESS=127.0.0.1 |
      | e        | ROUTER_LOG_LEVEL=debug          |
    Then the step should succeed
    And I wait for the pod named "<%= pod.name %>" to die
    When a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/route_pass.json |
    Then the step should succeed

    Given I run commands on the nodes in the :router_node clipboard:
      | cat /var/log/haproxy.log  |
    Then the output should contain "route-passthrough started"

  # @author bmeng@redhat.com
  # @case_id OCP-11728
  Scenario: haproxy hash based sticky session for tcp mode passthrough routes
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker-2.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name | route-pass |
      | service | service-secure |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | -ksS |
      | https://<%= route("route-pass", service("service-secure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response]` is stored in the :first_access clipboard
    Given I run the steps 6 times:
    """
    When I execute on the pod:
      | curl |
      | -ksS |
      | https://<%= route("route-pass", service("service-secure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access == @result[:response]
    """

  # @author bmeng@redhat.com
  # @case_id OCP-10043
  Scenario: Set balance leastconn for passthrough routes
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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name | route-pass |
      | service | service-secure |
    Then the step should succeed

    When I run the :annotate client command with:
      | resource | route |
      | resourcename | route-pass |
      | keyval | haproxy.router.openshift.io/balance=leastconn |
      | overwrite | true |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    And I use the "service-secure" service
    When I execute on the pod:
      | curl                                                   |
      | -ksS                                                   |
      | --resolve                                              |
      | <%= route("route-pass").dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-pass").dns(by: user) %> |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response]` is stored in the :first_access clipboard
    When I execute on the pod:
      | curl                                                   |
      | -ksS                                                   |
      | --resolve                                              |
      | <%= route("route-pass").dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-pass").dns(by: user) %> |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access != @result[:response]

  # @author yadu@redhat.com
  # @case_id OCP-11679
  Scenario: Disable haproxy hash based sticky session for unsecure routes
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
    When I run the :annotate client command with:
      | resource     | route                                            |
      | resourcename | service-unsecure                                 |
      | overwrite    | true                                             |
      | keyval       | haproxy.router.openshift.io/disable_cookies=true |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    Given I run the steps 5 times:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
      | -c |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response]` is stored in the :first_access clipboard
    When I execute on the pod:
      | curl |
      | -sS |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
      | -b |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access != @result[:response]
    """

  # @author yadu@redhat.com
  # @case_id OCP-11042
  Scenario: Disable haproxy hash based sticky session for edge termination routes
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
    When I run the :create_route_edge client command with:
      | name    | route-edge       |
      | service | service-unsecure |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                            |
      | resourcename | route-edge                                       |
      | overwrite    | true                                             |
      | keyval       | haproxy.router.openshift.io/disable_cookies=true |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    Given I run the steps 5 times:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
      | -c |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response]` is stored in the :first_access clipboard
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
      | -b |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access != @result[:response]
    """

  # @author yadu@redhat.com
  # @case_id OCP-11418
  Scenario: Disable haproxy hash based sticky session for reencrypt termination routes
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

    When I run the :annotate client command with:
      | resource     | route                                            |
      | resourcename | route-reencrypt                                  |
      | overwrite    | true                                             |
      | keyval       | haproxy.router.openshift.io/disable_cookies=true |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    Given I run the steps 5 times:
    """
    When I execute on the pod:
      | curl |
      | -sS |
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

    When I execute on the pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
      | -b |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access != @result[:response]
    """

  # @author hongli@redhat.com
  # @case_id OCP-11068
  @admin
  @destructive
  Scenario: the router should always reload on initial sync even if the route is rejected
    Given I have a project
    And evaluation of `project.name` is stored in the :project_a clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :project_b clipboard

    Given I use the "<%= cb.project_a %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge.json |
    Then the step should succeed
    Given I have a pod-for-ping in the project

    # create same route hostname in second project to make it as "HostAlreadyClaimed" (rejected)
    Given I use the "<%= cb.project_b %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge.json |
    Then the step should succeed

    # label the two namespaces
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    When I run the :label client command with:
      | resource | namespaces          |
      | name     | <%= cb.project_a %> |
      | key_val  | team=red            |
    Then the step should succeed
    When I run the :label client command with:
      | resource | namespaces          |
      | name     | <%= cb.project_b %> |
      | key_val  | team=red            |
    Then the step should succeed

    # redeploy router pod
    Given a pod becomes ready with labels:
      | deploymentconfig=router |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And cluster role "cluster-reader" is added to the "system:serviceaccount:default:router" service account
    And default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | NAMESPACE_LABELS=team=red |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And evaluation of `pod.ip` is stored in the :router_ip clipboard

    # the route should be accessed after router pod redeployed
    Given I switch to the first user
    And I use the "<%= cb.project_a %>" project
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | test-edge.example.com:443:<%= cb.router_ip %> |
      | https://test-edge.example.com/ |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

  # @author hongli@redhat.com
  # @case_id OCP-11437
  @admin
  @destructive
  Scenario: the routes should be loaded on initial sync
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    Given I have a pod-for-ping in the project

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | RELOAD_INTERVAL=122s |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And evaluation of `pod.ip` is stored in the :router_ip clipboard

    # the route should be accessed in less than RELOAD_INTERVAL(122s) after router pod redeployed
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the "hello-pod" pod:
      | curl |
      | -ksS |
      | --resolve |
      | <%= route("service-unsecure").dns(by: user) %>:80:<%= cb.router_ip[0] %> |
      | http://<%= route("service-unsecure").dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-12923
  @admin
  @destructive
  Scenario: same host with different path can be admitted
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_DISABLE_NAMESPACE_OWNERSHIP_CHECK=true  |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    When a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
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

    #change another namespace and create one same hostname stored in ':unsecure' with different path '/path/second'
    Given I switch to the second user
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | service             |
      | resource_name | service-unsecure    |
      | hostname      | <%= cb.unsecure %>  |
      | path          | /path/second        |
    Then the step should succeed

    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= cb.unsecure %>/test/" url
    Then the output should contain "Hello-OpenShift-Path-Test"
    """
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= cb.unsecure %>/path/second/" url
    Then the output should contain "second-test http-8080"
    """
    #create one overlap path '/path' with above to verify it also can work
    When I run the :expose client command with:
      | resource      | service            |
      | resource_name | service-unsecure   |
      | hostname      | <%= cb.unsecure %> |
      | path          | /path              |
      | name          | path               |
    Then the step should succeed

    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= cb.unsecure %>/path/" url
    Then the output should contain "ocp-test http-8080"
    """

    #Create one same hostname without path,the route can be cliamed.
    When I run the :expose client command with:
      | resource      | service            |
      | resource_name | service-unsecure   |
      | hostname      | <%= cb.unsecure %> |
      | name          | withoutpath        |
    Then the step should succeed

    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= cb.unsecure %>" url
    Then the output should contain "Hello-OpenShift-1 http-8080"
    """
    # All routes in this namespaces should be cliamed till now.
    When I run the :get client command with:
      | resource | route |
    Then the step should succeed
    And the output should not contain "HostAlreadyClaimed"

    #Create one same hostname and same path with first user. the route will be marked as 'HostAlreadyCliamed'
    When I run the :expose client command with:
      | resource      | service            |
      | resource_name | service-unsecure   |
      | hostname      | <%= cb.unsecure %> |
      | path          | /test              |
      | name          | same               |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | route |
      | resource_name | same  |
    Then the step should succeed
    And the output should contain "HostAlreadyClaimed"


  # @author zzhao@redhat.com
  # @case_id OCP-12924
  @admin
  @destructive
  Scenario: same wildcard host with different path can be admitted
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_DISABLE_NAMESPACE_OWNERSHIP_CHECK=true  |
      | e        | ROUTER_ALLOW_WILDCARD_ROUTES=true              |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    When a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name1 clipboard
    And I store default router subdomain in the :subdomain clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    #Create one route with stored 'subdomain' to make the default DNS can resolved this route.
    When I run the :expose client command with:
      | resource      | service                                   |
      | resource_name | service-unsecure                          |
      | hostname      | <%= cb.proj_name1 %>.<%= cb.subdomain %>  |
      | path          | /test                                     |
      | wildcardpolicy| Subdomain                                 |
    Then the step should succeed

    Given I switch to the second user
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name2 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    #Create one same hostname with different path wildcard route. the route can be cliamed.
    When I run the :expose client command with:
      | resource      | service                                   |
      | resource_name | service-unsecure                          |
      | hostname      | <%= cb.proj_name1 %>.<%= cb.subdomain %>  |
      | path          | /path/second                              |
      | wildcardpolicy| Subdomain                                 |
    Then the step should succeed

    # check the route can work well using 'random' prefix
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://random.<%= cb.subdomain %>/test/" url
    Then the output should contain "Hello-OpenShift-Path-Test"
    """
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://random.<%= cb.subdomain %>/path/second/" url
    Then the output should contain "second-test http-8080"
    """

    # create one same hostname with overlap path and it also can work well
    When I run the :expose client command with:
      | resource      | service                                   |
      | resource_name | service-unsecure                          |
      | hostname      | <%= cb.proj_name1 %>.<%= cb.subdomain %>  |
      | path          | /path                                     |
      | wildcardpolicy| Subdomain                                 |
      | name          | path                                      |
    Then the step should succeed

    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://random.<%= cb.subdomain %>/path/" url
    Then the output should contain "ocp-test http-8080"
    """

    #Create one same hostname without path wildcard route and it can work well.
    When I run the :expose client command with:
      | resource      | service                                   |
      | resource_name | service-unsecure                          |
      | hostname      | <%= cb.proj_name1 %>.<%= cb.subdomain %>  |
      | wildcardpolicy| Subdomain                                 |
      | name          | withoutpath                               |
    Then the step should succeed

    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://random.<%= cb.subdomain %>" url
    Then the output should contain "Hello-OpenShift-1 http-8080"
    """
    #All routes should be work well and NO 'HostAlreadyCliamed'
    When I run the :get client command with:
      | resource | route |
    Then the step should succeed
    And the output should not contain "HostAlreadyClaimed"

    #Create one same hostname and same path with first user, it will be marked as 'HostAlreadyCliamed'
    When I run the :expose client command with:
      | resource      | service                                   |
      | resource_name | service-unsecure                          |
      | hostname      | <%= cb.proj_name2 %>.<%= cb.subdomain %>  |
      | path          | /test                                     |
      | wildcardpolicy| Subdomain                                 |
      | name          | same                                      |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | route |
      | resource_name | same  |
    Then the step should succeed
    And the output should contain "HostAlreadyClaimed"

  # @author zzhao@redhat.com
  # @case_id OCP-12925
  @admin
  @destructive
  Scenario: The overlapping hosts with a wildcard can be claimed across namespaces
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_DISABLE_NAMESPACE_OWNERSHIP_CHECK=true  |
      | e        | ROUTER_ALLOW_WILDCARD_ROUTES=true              |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    When a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name1 clipboard
    And I store default router subdomain in the :subdomain clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    #Create one wildcard route 'proj1.subdomain'
    When I run the :expose client command with:
      | resource      | service                                   |
      | resource_name | service-unsecure                          |
      | hostname      | <%= cb.proj_name1 %>.<%= cb.subdomain %>  |
      | wildcardpolicy| Subdomain                                 |
    Then the step should succeed

    #Change another user in case one user only can create one namespace for online.
    Given I switch to the second user
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name2 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed

    #Create one normal route with different prefix but same suffix 'subdomain', it can be cliamed. e.g when user1 have a wildcard route '*.example.com',user2 can create a normal route 'second.example.com'.when user access the 'second.example.com', it will be forwarded to user2.  if accessing 'random.example.com' it will be forwarded to user1.
    When I run the :create_route_passthrough client command with:
      | name    | route-pass     |
      | service | service-secure |
      | hostname| <%= cb.proj_name2 %>.<%= cb.subdomain %> |
    Then the step should succeed

    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= cb.proj_name2 %>.<%= cb.subdomain %>" url
    Then the output should contain "Hello-OpenShift-1 http-8080"
    """
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= cb.proj_name2 %>.<%= cb.subdomain %>" url
    Then the output should contain "Hello-OpenShift-1 https-8443"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-11030
  @admin
  @destructive
  Scenario: Default ports will be bound only after the routes are loaded for host network router
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name1 clipboard
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | service                  |
      | resource_name | service-unsecure         |
      | name          | ocp-11030                |
      | hostname      | ocp-11030.example.com    |
    Then the step should succeed
    And I have a pod-for-ping in the project

    #Enable the ROUTER_BIND_PORTS_AFTER_SYNC=true for router
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_BIND_PORTS_AFTER_SYNC=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    When a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod_new clipboard
    When I run the :delete client command with:
      | object_type       | pod        |
      | object_name_or_id | <%= cb.router_pod_new %> |
    Then the step should succeed
    
    Given I switch to the first user
    And I use the "<%= cb.proj_name1 %>" project

    #monitor the route should not return 503 error during the router pod is restarting
    When I execute on the "hello-pod" pod:
      | bash | -c | starttime=`date +%s`; while [ $((`date +%s` - starttime)) -lt 50 ]; do result=`curl -sS -w %{http_code} --resolve ocp-11030.example.com:80:<%= cb.router_ip[0] %> http://ocp-11030.example.com -o /dev/null`; if [ $result = 503 ]; then echo "fail" && exit 0; elif [ $result = 200 ] ; then echo "succ" && exit 0; fi; done |
    Then the step should succeed
    And the output should contain "succ"

  # @author zzhao@redhat.com
  # @case_id OCP-11409
  @admin
  @destructive  
  Scenario: Default ports will be bound only after the routes are loaded for container network router
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name1 clipboard
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name      | route-edge |
      | service   | service-unsecure |
      | hostname  | ocp-11409-edge.example.com |
    Then the step should succeed
    And I have a pod-for-ping in the project

    #Enable the ROUTER_BIND_PORTS_AFTER_SYNC=true for router
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    Given default router replica count is stored in the :router_num clipboard
    And default router replica count is restored after scenario
    When I run the :scale client command with:
      | resource    | dc     |
      | name        | router |
      | replicas    | 0      |
    Then the step should succeed
    Given admin ensures "ocp-11409" dc is deleted after scenario
    And admin ensures "ocp-11409" service is deleted after scenario
    When I run the :oadm_router admin command with:
      | name   | ocp-11409 |
      | images | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | host_network | false |
      | replicas | 0 |
    Then the step should succeed
    When I run the :env client command with:
      | resource | dc/ocp-11409 |
      | e        | ROUTER_BIND_PORTS_AFTER_SYNC=true |
    Then the step should succeed
    When I run the :scale client command with:
      | resource    | dc                           |
      | name        | ocp-11409                    |
      | replicas    | <%= cb.router_num %>         |
    Then the step should succeed
    When a pod becomes ready with labels:
      | deploymentconfig=ocp-11409 |
    Then evaluation of `pod.name` is stored in the :router_pod_new clipboard
    When I run the :delete client command with:
      | object_type       | pod        |
      | object_name_or_id | <%= cb.router_pod_new %> |
    Then the step should succeed

    Given I switch to the first user
    And I use the "<%= cb.proj_name1 %>" project

    #monitor the route should not return 503 error during the router pod is restarting
    When I execute on the "hello-pod" pod:
      | bash | -c | starttime=`date +%s`; while [ $((`date +%s` - starttime)) -lt 50 ]; do result=`curl -sS -w %{http_code} --resolve ocp-11409-edge.example.com:443:<%= cb.router_ip[0] %> https://ocp-11409-edge.example.com -k -o /dev/null`; if [ $result = 503 ]; then echo "fail" && exit 0; elif [ $result = 200 ] ; then echo "succ" && exit 0; fi; done |
    Then the step should succeed
    And the output should contain "succ"


  # @author yadu@redhat.com
  # @case_id OCP-12967 OCP-12968
  @admin
  @destructive     
  Scenario Outline: Router dns name info exist in route when creating router with --router-canonical-hostname option
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    Given default router replica count is stored in the :router_num clipboard
    And default router replica count is restored after scenario
    When I run the :scale client command with:
      | resource | dc     |
      | name     | router |
      | replicas | 0      |
    Then the step should succeed

    Given admin ensures "tc-12967" dc is deleted after scenario
    And admin ensures "tc-12967" service is deleted after scenario

    When I run the :oadm_router admin command with: 
      | name               | tc-12967 |
      | images             | <%= product_docker_repo %>openshift3/ose-haproxy-router:<%= cb.master_version %> |
      | canonical_hostname | external1.router.com |
      | host_network       | <hostnetwork> |
      | replicas           | <%= cb.router_num %> |
    And a pod becomes ready with labels:
      | deploymentconfig=tc-12967 |

    Given I switch to the first user
    And I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :expose client command with:
      | resource      | service      |
      | resource_name | test-service |
      | name          | route1       |
    Then the step should succeed
    When I use the "test-service" service
    Then I wait up to 15 seconds for a web server to become available via the "route1" route
    And the output should contain "Hello OpenShift"
    When I run the :describe client command with:
      | resource | route  |
      | name     | route1 |
    Then the output should contain "external1.router.com"

    Examples:
      | hostnetwork |
      | true        |
      | false       |

  # @author zzhao@redhat.com
  # @case_id OCP-10548
  # @bug_id 1371826
  @admin
  @destructive
  Scenario: panic error should not be found in haproxy router log    
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    When I run the :patch client command with:
      | resource      | dc     |
      | resource_name | router |
      | p             | {"spec":{"template":{"spec":{"containers":[{"command": ["/usr/bin/openshift-router","--loglevel=4"],"name":"router"}]}}}} |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    When a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod_new clipboard

    Given I switch to the first user
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
    When I run the :patch client command with:
      | resource      | route |
      | resource_name | service-unsecure |
      | p             | {"spec": {"path": "/test"}} |
    Then the step should succeed
    
    #Delete the route and re-create it
    When I run the :delete client command with:
      | object_type       | route      |
      | object_name_or_id | service-unsecure |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    And I wait for a web server to become available via the route
    Then the output should contain "Hello-OpenShift"

    #Check the router logs
    When I run the :logs admin command with:
      | resource_name | <%= cb.router_pod_new %>  |
    Then the step should succeed
    And the output should not contain "Recovered from panic"
