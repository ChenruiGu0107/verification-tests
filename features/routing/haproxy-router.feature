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

    Given I have a pod-for-ping in the project
    #access the route without cookies
    When I execute on the pod:
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
    When I execute on the pod:
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
    When I execute on the pod:
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
      | -s |
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
      | -s |
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
      | -s |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
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

    Given I have a pod-for-ping in the project
    #access the route without cookies
    When I execute on the pod:
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
    When I execute on the pod:
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
    When I execute on the pod:
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
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-recrypt", service("route-recrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"

  # @author bmeng@redhat.com
  # @case_id 526539
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
    When I run the :create_route_edge client command with:
      | name | route-edge |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I open web server via the "http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/" url
    Then the output should not contain "Hello-OpenShift"
    When I execute on the "hello-pod" pod:
      | curl |
      | -s |
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
    When I open web server via the "http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/" url
    Then the output should contain "Hello-OpenShift"
    When I run the :label client command with:
      | resource | route |
      | name | route-edge |
      | key_val | router=router1 |
    Then the step should succeed
    When I execute on the "hello-pod" pod:
      | curl |
      | -s |
      | --resolve |
      | <%= route("route-edge", service("route-edge")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"


  # @author zzhao@redhat.com
  # @case_id 516834
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
  # @case_id 519390
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
  # @case_id 516836
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
  # @case_id 483532
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
  # @case_id 483529
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
  # @case_id 526537
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
  # @case_id 483533
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
  # @case_id 526538
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
  # @case_id 518936
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
  # @case_id 531375
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
      | e        | ROUTER_SERVICE_HTTP_PORT=<%= cb.http_port %>,ROUTER_SERVICE_HTTPS_PORT=<%= cb.https_port %>  |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=tc-531375-2 |

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

    When I open web server via the "http://<%= route.dns(by: user) %>" url
    Then the output should contain "Hello-OpenShift"
    When I open web server via the "http://<%= route.dns(by: user) %>:<%= cb.http_port %>" url
    Then the output should contain "Hello-OpenShift"
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | service-unsecure |
    Then the step should succeed
    When I open secure web server via the "edge-route" route
    Then the output should contain "Hello-OpenShift"

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | https://<%= route("edge-route", service("service-unsecure")).dns(by: user) %>:<%= cb.https_port %> |
      | -k |
    Then the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id 500001
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
  # @case_id 498716
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

    Given I run commands on the nodes in the :router_node clipboard:
      | docker ps \| grep tc-498716 |
    Then the output should contain "0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:1936->1936/tcp"

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
    When I open web server via the "http://<%= route.dns(by: user) %>" url
    Then the output should contain "Hello-OpenShift"

    #edge route
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | service-unsecure |
    Then the step should succeed
    Given I have a pod-for-ping in the project
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
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("passthrough-route", service("passthrough-route")).dns(by: user) %>:443:<%= cb.router_ip %> |
      | https://<%= route("passthrough-route", service("passthrough-route")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"

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
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>:443:<%= cb.router_ip %> |
      | https://<%= route("route-reencrypt", service("route-reencrypt")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the output should contain "Hello-OpenShift"

  # @author bmeng@redhat.com
  # @case_id 520312
  @admin
  Scenario: Unable to create router with host networking mode when mapping ports are different
    When I run the :oadm_router admin command with:
      | name | router-test |
      | host_network | true |
      | ports | 1080:1081,10443:10444 |
    Then the step should fail
    And the output should contain "must be equal"

  # @author bmeng@redhat.com
  # @case_id 532646
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
  # @case_id 520314
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
      | e        | ROUTER_SERVICE_HTTP_PORT=<%= cb.http_port %>,ROUTER_SERVICE_HTTPS_PORT=<%= cb.https_port %>  |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=tc-520314-2 |

    Given I run commands on the nodes in the :router_node clipboard:
      | docker ps \| grep tc-520314 |
    Then the output should contain "0.0.0.0:<%= cb.http_port %>-><%= cb.http_port %>/tcp, 0.0.0.0:<%= cb.https_port %>-><%= cb.https_port %>/tcp, 0.0.0.0:<%= cb.stats_port %>-><%= cb.stats_port %>/tcp"

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

    When I open web server via the "http://<%= route.dns(by: user) %>" url
    Then the output should contain "Hello-OpenShift"
    When I open web server via the "http://<%= route.dns(by: user) %>:<%= cb.http_port %>" url
    Then the output should contain "Hello-OpenShift"
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | service-unsecure |
    Then the step should succeed
    When I open secure web server via the "edge-route" route
    Then the output should contain "Hello-OpenShift"

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | https://<%= route("edge-route", service("service-unsecure")).dns(by: user) %>:<%= cb.https_port %> |
      | -k |
    Then the output should contain "Hello-OpenShift"
