Feature: Testing haproxy router

  # @author bmeng@redhat.com
  # @case_id OCP-12557
  @admin
  Scenario: Only the certs file of the certain route will be updated when the route is updated
    Given I have a project
    And evaluation of `project.name` is stored in the :project clipboard

    # create two routes which will contain cert files
    Given I obtain test data file "routing/web-server-1.yaml"
    When I run the :create client command with:
      | f | web-server-1.yaml |
    Then the step should succeed
    And the pod named "web-server-1" becomes ready
    Given I obtain test data file "routing/service_secure.yaml"
    When I run the :create client command with:
      | f | service_secure.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/service_unsecure.yaml"
    When I run the :create client command with:
      | f | service_unsecure.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/reencrypt/route_reencrypt-reen.example.com.crt"
    Given I obtain test data file "routing/reencrypt/route_reencrypt-reen.example.com.key"
    Given I obtain test data file "routing/reencrypt/route_reencrypt.ca"
    Given I obtain test data file "routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | route-reen                           |
      | hostname   | <%= rand_str(5, :dns) %>.reen.com    |
      | service    | service-secure                       |
      | cert       | route_reencrypt-reen.example.com.crt |
      | key        | route_reencrypt-reen.example.com.key |
      | cacert     | route_reencrypt.ca                   |
      | destcacert | route_reencrypt_dest.ca              |
    Then the step should succeed
    Given I obtain test data file "routing/edge/route_edge-www.edge.com.crt"
    Given I obtain test data file "routing/edge/route_edge-www.edge.com.key"
    Given I obtain test data file "routing/ca.pem"
    When I run the :create_route_edge client command with:
      | name     | route-edge                        |
      | hostname | <%= rand_str(5, :dns) %>.edge.com |
      | service  | service-unsecure                  |
      | cert     | route_edge-www.edge.com.crt       |
      | key      | route_edge-www.edge.com.key       |
      | cacert   | ca.pem                            |
    Then the step should succeed

    # get the cert files creation time on router pod
    When I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    And I wait up to 30 seconds for the steps to pass:
    """"
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash                                                                    |
      | -lc                                                                     |
      | ls --full-time /var/lib/*/router/certs/<%= cb.project %>?route-edge.pem |
    Then the step should succeed
    """
    And evaluation of `@result[:response]` is stored in the :edge_cert clipboard

    And I wait up to 30 seconds for the steps to pass:
    """"
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash                                                                    |
      | -lc                                                                     |
      | ls --full-time /var/lib/*/router/certs/<%= cb.project %>?route-reen.pem |
    Then the step should succeed
    """
    And evaluation of `@result[:response]` is stored in the :reen_cert clipboard

    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash                                                                      |
      | -lc                                                                       |
      | ls --full-time /var/lib/*/router/cacerts/<%= cb.project %>?route-reen.pem |
    Then the step should succeed
    """
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
    And I use the router project

    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash                                                                    |
      | -lc                                                                     |
      | ls --full-time /var/lib/*/router/certs/<%= cb.project %>?route-reen.pem |
    Then the step should succeed
    And the expression should be true> cb.reen_cert != @result[:response]
    """

    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash                                                                      |
      | -lc                                                                       |
      | ls --full-time /var/lib/*/router/cacerts/<%= cb.project %>?route-reen.pem |
    Then the step should succeed
    And the expression should be true> cb.reen_cacert != @result[:response]
    """

    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash                                                                    |
      | -lc                                                                     |
      | ls --full-time /var/lib/*/router/certs/<%= cb.project %>?route-edge.pem |
    Then the step should succeed
    And the expression should be true> cb.edge_cert == @result[:response]
    """

  # @author hongli@redhat.com
  # @case_id OCP-10207
  Scenario: Should use the same cookies for secure and insecure access when insecureEdgeTerminationPolicy set to allow for edge route
    Given I have a project
    Given I obtain test data file "routing/web-server-1.yaml"
    When I run the :create client command with:
      | f | web-server-1.yaml |
    Then the step should succeed
    When I run oc create over "web-server-1.yaml" replacing paths:
      | ["metadata"]["name"] | web-server-2 |
    Then the step should succeed
    Given I obtain test data file "routing/service_unsecure.yaml"
    When I run the :create client command with:
      | f | service_unsecure.yaml |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name            | route-edge              |
      | service         | service-unsecure        |
      | insecure_policy | Allow                   |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    Given I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
      | -c |
      | /tmp/cookie |
    Then the step should succeed
    And the output should contain "Hello-OpenShift web-server-2"
    """

    Given I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift web-server-1"
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
    And the output should contain "Hello-OpenShift web-server-2"
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
    And the output should contain "Hello-OpenShift web-server-2"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-10903
  @admin
  Scenario: The router pod should have default resource limits
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then the expression should be true> pod.container_specs.first.cpu_request_raw
    Then the expression should be true> pod.container_specs.first.memory_request_raw

  # @author hongli@redhat.com
  # @case_id OCP-15050
  @admin
  Scenario: The backend health check interval of passthrough route can be set by annotation
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run oc create over "web-server-rc.yaml" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=web-server-rc |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard

    When I run the :create_route_passthrough client command with:
      | name    | pass-route     |
      | service | service-secure |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                   |
      | resourcename | pass-route                                              |
      | overwrite    | true                                                    |
      | keyval       | router.openshift.io/haproxy.health.check.interval=400ms |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain:
      | check inter 400ms |
    """

  # @author hongli@redhat.com
  # @case_id OCP-15051
  @admin
  Scenario: The backend health check interval of reencrypt route can be set by annotation
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run oc create over "web-server-rc.yaml" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=web-server-rc |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard

    Given I obtain test data file "routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | reen-route     |
      | service    | service-secure |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                   |
      | resourcename | reen-route                                              |
      | overwrite    | true                                                    |
      | keyval       | router.openshift.io/haproxy.health.check.interval=500ms |
    Then the step should succeed

    # check the backend of route after annotation
    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain:
      | check inter 500ms |
    """

  # @author bmeng@redhat.com
  # @case_id OCP-11728
  Scenario: haproxy hash based sticky session for tcp mode passthrough routes
    Given I have a project
    Given I obtain test data file "routing/web-server-1.yaml"
    When I run the :create client command with:
      | f | web-server-1.yaml |
    Then the step should succeed
    When I run oc create over "web-server-1.yaml" replacing paths:
      | ["metadata"]["name"] | web-server-2 |
    Then the step should succeed
    And all pods in the project are ready
    Given I obtain test data file "routing/service_secure.yaml"
    When I run the :create client command with:
      | f | service_secure.yaml |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name    | route-pass     |
      | service | service-secure |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | -ksS |
      | https://<%= route("route-pass", service("service-secure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And evaluation of `@result[:response].lines.first.chomp` is stored in the :first_access clipboard
    Given I run the steps 6 times:
    """
    When I execute on the pod:
      | curl |
      | -ksS |
      | https://<%= route("route-pass", service("service-secure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the expression should be true> cb.first_access == @result[:response].lines.first.chomp
    """

  # @author yadu@redhat.com
  # @case_id OCP-11042
  Scenario: Disable haproxy hash based sticky session for edge termination routes
    Given I have a project
    Given I obtain test data file "routing/web-server-1.yaml"
    When I run the :create client command with:
      | f | web-server-1.yaml |
    Then the step should succeed
    When I run oc create over "web-server-1.yaml" replacing paths:
      | ["metadata"]["name"] | web-server-2 |
    Then the step should succeed
    And all pods in the project are ready
    Given I obtain test data file "routing/service_unsecure.yaml"
    When I run the :create client command with:
      | f | service_unsecure.yaml |
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
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
      | -c |
      | /tmp/cookies |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    When I execute on the pod:
      | bash | -c | for i in {1..10} ; do curl -ksS  https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ -b /tmp/cookies ; done |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift web-server-1 |
      | Hello-OpenShift web-server-2 |

  # @author yadu@redhat.com
  # @case_id OCP-10914
  Scenario: Protect from ddos by limiting TCP concurrent connection for route
    Given I have a project
    Given I obtain test data file "routing/web-server-1.yaml"
    When I run the :create client command with:
      | f | web-server-1.yaml |
    Then the step should succeed
    And the pod named "web-server-1" becomes ready
    Given I obtain test data file "routing/service_unsecure.yaml"
    When I run the :create client command with:
      | f | service_unsecure.yaml |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | bash | -c | for i in {1..15} ; do curl -sS  http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ & done |
    Then the output should contain 15 times:
      | Hello-OpenShift |
    And the output should not contain "Empty reply from server"

    When I run the :annotate client command with:
      | resource     | route                                                               |
      | resourcename | service-unsecure                                                    |
      | keyval       | haproxy.router.openshift.io/rate-limit-connections=true             |
      | keyval       | haproxy.router.openshift.io/rate-limit-connections.concurrent-tcp=2 |
    Then the step should succeed

    Given 10 seconds have passed
    When I execute on the pod:
      | bash | -c | for i in {1..15} ; do curl -sS  http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ & done |
    Then the output should contain:
      | Hello-OpenShift         |
      | Empty reply from server |

  # @author hongli@redhat.com
  # @case_id OCP-15874
  Scenario: can set cookie name for reencrypt routes by annotation
    #create route and service which has two endpoints
    Given the master version >= "3.7"
    Given I have a project
    Given I obtain test data file "routing/reencrypt/two-caddy-with-serving-cert.yaml"
    When I run the :create client command with:
      | f | two-caddy-with-serving-cert.yaml |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create_route_reencrypt client command with:
      | name    | reen-route     |
      | service | service-secure |
    Then the step should succeed

    When I run the :annotate client command with:
      | resource     | route                                         |
      | resourcename | reen-route                                    |
      | overwrite    | true                                          |
      | keyval       | router.openshift.io/cookie_name=_reen-cookie3 |
    Then the step should succeed

    When I use the "service-unsecure" service
    And I wait up to 30 seconds for the steps to pass:
    """
    When I open secure web server via the "reen-route" route
    Then the output should contain "Hello-OpenShift"
    And the expression should be true> @result[:cookies].any? {|c| c.name == "_reen-cookie3"}
    """
    And evaluation of `@result[:response]` is stored in the :first_access clipboard

    #access the route with cookies
    Given HTTP cookies from result are used in further request
    Given I run the steps 6 times:
    """
    When I wait for a secure web server to become available via the "reen-route" route
    Then the expression should be true> cb.first_access == @result[:response]
    """

  # @author zzhao@redhat.com
  # @case_id OCP-16870
  @admin
  Scenario: No health check when there is only one endpoint for a route
    Given I have a project
    Then evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run the :create client command with:
      | f | web-server-rc.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=web-server-rc |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    Given evaluation of `"web-server-rc"` is stored in the :rc_name clipboard
    # create route
    When I expose the "service-unsecure" service
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%=cb.router_pod %>" pod:
      | grep | <%=cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain "<%=cb.pod_ip %>"
    And the output should not contain "check inter"
    """

    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
      | replicas | 2                      |
    And I wait until number of replicas match "2" for replicationController "<%= cb.rc_name %>"
    And all existing pods are ready with labels:
      | name=web-server-rc |
    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%=cb.router_pod %>" pod:
      | grep | -C | 1 | <%=cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain "<%=cb.pod_ip %>"
    And the output should contain 2 times:
      | check inter |
    """

  # @author zzhao@redhat.com
  # @case_id OCP-16872
  @admin
  Scenario: Health check when there are multi service and each service has one backend
    Given I have a project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=abtest-websrv1 |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
    Then the step should succeed
    And all pods in the project are ready

    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | service-unsecure      |
      | service   | service-unsecure=20   |
      | service   | service-unsecure-2=80 |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%=cb.router_pod %>" pod:
      | grep | -C | 1 | <%=cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain "<%=cb.pod_ip %>"
    And the output should contain 2 times:
      | check inter |
    """

  # @author hongli@redhat.com
  # @case_id OCP-12091
  # @bug_id 1374772
  Scenario: haproxy config information should be clean when changing the service to another route
    Given I have a project
    #Create PodA & serviceA
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed

    #Create PodB & serviceB
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml|
    Then the step should succeed
    And all pods in the project are ready

    When I expose the "service-unsecure" service
    Then the step should succeed
    #Enable roundrobin mode for haproxy to more reliably trigger the bug
    When I run the :patch client command with:
      | resource      | routes                                                                            |
      | resource_name | service-unsecure                                                                  |
      | p             | {"metadata":{"annotations":{"haproxy.router.openshift.io/balance":"roundrobin"}}} |
    Then the step should succeed
    When I wait up to 15 seconds for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift abtest-websrv1"
    When I run the :patch client command with:
      | resource      | routes                                         |
      | resource_name | service-unsecure                               |
      | p             | {"spec":{"to":{"name": "service-unsecure-2"}}} |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift abtest-websrv2"
    """
    And I run the steps 10 times:
    """
    When I open web server via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift abtest-websrv2"
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-39853
  # @bug_id 1906471
  @admin
  Scenario: Router accepts services with duplicate TargetPorts and continues to function normally
    Given the master version >= "4.4"
    And I have a project
    Then evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard

    # create custom ingresscontroller
    Given I switch to cluster admin pseudo user
    And admin ensures "test-39853" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctl-nodeport.yaml"
    When I run oc create over "ingressctl-nodeport.yaml" replacing paths:
      | ["metadata"]["name"] | test-39853                                    |
      | ["spec"]["domain"]   | <%= cb.subdomain.gsub("apps","test-39853") %> |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-39853 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard

    # Deploy backend pod and one multiport service with targetPort 8080
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/web-server-1.yaml"
    When I run the :create client command with:
      | f | web-server-1.yaml |
    Then the step should succeed
    And the pod named "web-server-1" becomes ready
    Given I obtain test data file "routing/multiport/multiport-service.yaml"
    When I run the :create client command with:
      | f | multiport-service.yaml |
    Then the step should succeed

    # Deploy a route with a duplicate port pointing to 8080
    Given I obtain test data file "routing/multiport/targetport-route.yaml"
    And I run oc create over "targetport-route.yaml" replacing paths:
      | ["spec"]["host"] | <%= cb.proj_name %>.39853.example.com |
    And the step should succeed

    # Delete the router pod to verify it is re-spawned without any errors
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-ingress" project
    Given I ensure "<%= cb.router_pod %>" pod is deleted
    And I wait for the resource "pod" named "<%= cb.router_pod %>" to disappear

    # Check the proxy config to verify the backend route info
    Given status becomes :running of 1 pods labeled:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-39853 |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | pod/<%= cb.router_pod %> |
      | tail          | 50                       |
    Then the step should succeed
    And the output should contain "router reloaded"
    And the output should not match:
      | Fatal errors found in configuration |
    """

