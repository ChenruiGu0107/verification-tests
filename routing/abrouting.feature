Feature: Testing abrouting

  # @author yadu@redhat.com
  # @case_id OCP-10889
  Scenario: Sticky session could work normally after set weight for route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker-2.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-2.json |
    Then the step should succeed
    Given I wait for the "service-unsecure" service to become ready
    Given I wait for the "service-unsecure-2" service to become ready
    When I run the :create_route_edge client command with:
      | name    | route-edge       |
      | service | service-unsecure |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                          |
      | resourcename | route-edge                                     |
      | overwrite    | true                                           |
      | keyval       | haproxy.router.openshift.io/balance=roundrobin |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge            |
      | service   | service-unsecure=20   |
      | service   | service-unsecure-2=80 |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge            |
    Then the step should succeed
    Then the output should contain:
      | (20%) |
      | (80%) |
    Given I have a pod-for-ping in the project
    #access the route without cookies
    Given I wait up to 30 seconds for the steps to pass:
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
    """
    Given I wait up to 30 seconds for the steps to pass:
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

  # @author yadu@redhat.com
  # @case_id OCP-11351
  Scenario: Set backends weight to zero for ab routing
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker-2.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-2.json |
    Then the step should succeed
    Given I wait for the "service-unsecure" service to become ready
    Given I wait for the "service-unsecure-2" service to become ready
    When I run the :create_route_edge client command with:
      | name    | route-edge       |
      | service | service-unsecure |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                          |
      | resourcename | route-edge                                     |
      | overwrite    | true                                           |
      | keyval       | haproxy.router.openshift.io/balance=roundrobin |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge           |
      | service   | service-unsecure=1   |
      | service   | service-unsecure-2=0 |
    When I run the :set_backends client command with:
      | routename | route-edge |
    Then the step should succeed
    Then the output should contain 1 times:
      | (0%)   |
      | (100%) |
    When I wait up to 20 seconds for a secure web server to become available via the "route-edge" route
    Given I run the steps 10 times:
    """
    When I open secure web server via the "route-edge" route
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"
    """
    When I run the :set_backends client command with:
      | routename | route-edge |
      | zero      | true       |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge |
    Then the step should succeed
    Then the output should contain 2 times:
      | 0 |
    Given I run the steps 10 times:
    """
    When I execute on the pod:
      | curl                                                                     |
      | -I                                                                       |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k                                                                       |
    Then the output should contain "503 Service Unavailable"
    """

  # @author yadu@redhat.com
  # @case_id OCP-11608
  Scenario: Set backends weight for edge route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker-2.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-2.json |
    Then the step should succeed
    Given I wait for the "service-unsecure" service to become ready
    Given I wait for the "service-unsecure-2" service to become ready
    When I run the :create_route_edge client command with:
      | name    | route-edge       |
      | service | service-unsecure |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                          |
      | resourcename | route-edge                                     |
      | overwrite    | true                                           |
      | keyval       | haproxy.router.openshift.io/balance=roundrobin |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge            |
      | service   | service-unsecure=20   |
      | service   | service-unsecure-2=80 |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge  |
    Then the step should succeed
    Then the output should contain 1 times:
      | 20% |
      | 80% |
    Given the "access.log" file is deleted if it exists
    When I wait up to 20 seconds for a secure web server to become available via the "route-edge" route
    And I run the steps 40 times:
    """
    When I open secure web server via the "route-edge" route
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-2").size` is stored in the :accesslength2 clipboard
    Then the expression should be true> (28..36).include? cb.accesslength2
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-1").size` is stored in the :accesslength1 clipboard
    Then the expression should be true> (4..12).include? cb.accesslength1


  # @author yadu@redhat.com
  # @case_id OCP-11809
  Scenario: Set backends weight for passthough route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker-2.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/passthough/service_secure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/passthough/service_secure-2.json |
    Then the step should succeed
    Given I wait for the "service-secure" service to become ready
    Given I wait for the "service-secure-2" service to become ready
    When I run the :create_route_passthrough client command with:
      | name    | route-pass     |
      | service | service-secure |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                          |
      | resourcename | route-pass                                     |
      | overwrite    | true                                           |
      | keyval       | haproxy.router.openshift.io/balance=roundrobin |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-pass          |
      | service   | service-secure=30   |
      | service   | service-secure-2=70 |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-pass  |
    Then the step should succeed
    Then the output should contain 1 times:
      | (30%) |
      | (70%) |
    Given the "access.log" file is deleted if it exists
    When I wait up to 20 seconds for a secure web server to become available via the "route-pass" route
    And I run the steps 20 times:
    """
    When I open secure web server via the "route-pass" route
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-2").size` is stored in the :accesslength2 clipboard
    Then the expression should be true> (12..19).include? cb.accesslength2
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-1").size` is stored in the :accesslength1 clipboard
    Then the expression should be true> (1..8).include? cb.accesslength1

  # @author yadu@redhat.com
  # @case_id OCP-11306
  Scenario: Set negative backends weight for ab routing
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-2.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name    | route-edge       |
      | service | service-unsecure |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                          |
      | resourcename | route-edge                                     |
      | overwrite    | true                                           |
      | keyval       | haproxy.router.openshift.io/balance=roundrobin |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge             |
      | service   | service-unsecure=abc   |
      | service   | service-unsecure-2=*^% |
    Then the step should fail
    And the output should contain:
      | invalid argument        |
      | WEIGHT must be a number |
    When I run the :set_backends client command with:
      | routename | route-edge             |
      | service   | service-unsecure=-80   |
      | service   | service-unsecure-2=-20 |
    Then the step should fail
    And the output should contain:
      | negative percentages are not allowed |
    When I run the :set_backends client command with:
      | routename | route-edge             |
      | service   | service-unsecure=80    |
      | service   | service-unsecure-2=20  |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge          |
      | adjust    | true                |
      | service   | service-secure=-$   |
    Then the step should fail
    And the output should contain:
      | invalid argument        |
      | WEIGHT must be a number |

  # @author yadu@redhat.com
  # @case_id OCP-12088
  Scenario: Set multiple backends weight for route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker-2.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker-3.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-2.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-3.json |
    Then the step should succeed
    Given I wait for the "service-unsecure" service to become ready
    Given I wait for the "service-unsecure-2" service to become ready
    Given I wait for the "service-unsecure-3" service to become ready
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                          |
      | resourcename | service-unsecure                               |
      | overwrite    | true                                           |
      | keyval       | haproxy.router.openshift.io/balance=roundrobin |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | service-unsecure           |
      | service   | service-unsecure=2   |
      | service   | service-unsecure-2=3 |
      | service   | service-unsecure-3=5 |
    Then the step should succeed
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | service-unsecure  |
    Then the step should succeed
    Then the output should contain:
      | 20% |
      | 30% |
      | 50% |
    Given the "access.log" file is deleted if it exists
    When I wait up to 20 seconds for a web server to become available via the "service-unsecure" route
    And I run the steps 60 times:
    """
    When I open web server via the "service-unsecure" route
    And the output should contain "Hello-OpenShift"
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    ## for setup that has multiple routers, we should do fuzzy match.
    # instead of a hard limit and do exact match.  We will pass the test if the
    # count is between a range depending on number of routers
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-3").size` is stored in the :accesslength3 clipboard
    Then the expression should be true> (24..36).include? cb.accesslength3
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-2").size` is stored in the :accesslength2 clipboard
    Then the expression should be true> (12..24).include? cb.accesslength2
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-1").size` is stored in the :accesslength1 clipboard
    Then the expression should be true> (6..12).include? cb.accesslength1

  # @author yadu@redhat.com
  # @case_id OCP-13252
  @admin
  Scenario: The unsecure route with multiple service will set load balance policy to RoundRobin by default
    #Create pod/service/route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-2.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed

    #Check the default load blance policy
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | service-unsecure |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "leastconn"
    """
    #Add multiple services to route
    Given I switch to the first user
    When I run the :set_backends client command with:
      | routename | service-unsecure     |
      | service   | service-unsecure=1   |
      | service   | service-unsecure-2=9 |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | service-unsecure |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "roundrobin"
    """
    #Set one of the service weight to 0
    Given I switch to the first user
    When I run the :set_backends client command with:
      | routename | service-unsecure     |
      | service   | service-unsecure=0   |
      | service   | service-unsecure-2=1 |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | service-unsecure |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "leastconn"
    """
    #Set all the service weight to 0
    Given I switch to the first user
    When I run the :set_backends client command with:
      | routename | service-unsecure     |
      | service   | service-unsecure=0   |
      | service   | service-unsecure-2=0 |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | service-unsecure |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "leastconn"
    """

  # @author yadu@redhat.com
  # @case_id OCP-13522
  @admin
  Scenario: The reencrypt route with multiple service will set load balance policy to RoundRobin by default
    #Create pod/service/route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/reencrypt/service_secure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/reencrypt/service_secure-2.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/example_wildcard.pem"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/example_wildcard.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt.ca"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name | reen1 |
      | hostname | <%= rand_str(5, :dns) %>-reen.example.com |
      | service | service-secure |
      | cert | example_wildcard.pem |
      | key | example_wildcard.key |
      | cacert | route_reencrypt.ca |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    #Check the default load blance policy
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | reen1            |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "leastconn"
    """
    #Add multiple services to route
    Given I switch to the first user
    When I run the :set_backends client command with:
      | routename | reen1              |
      | service   | service-secure=1   |
      | service   | service-secure-2=9 |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | reen1            |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "roundrobin"
    """
    #Set one of the service weight to 0
    Given I switch to the first user
    When I run the :set_backends client command with:
      | routename | reen1              |
      | service   | service-secure=0   |
      | service   | service-secure-2=1 |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | reen1            |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "leastconn"
    """
    #Set all the service weight to 0
    Given I switch to the first user
    When I run the :set_backends client command with:
      | routename | reen1              |
      | service   | service-secure=0   |
      | service   | service-secure-2=0 |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | reen1            |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "leastconn"
    """


  # @author yadu@redhat.com
  # @case_id OCP-13521
  @admin
  Scenario: The passthrough route with multiple service will set load balance policy to RoundRobin by default
    #Create pod/service/route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/passthough/service_secure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/passthough/service_secure-2.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name    | pass1          |
      | service | service-secure |
    Then the step should succeed
    #Check the default load blance policy
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | pass1            |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "source"
    #Add multiple services to route
    Given I switch to the first user
    When I run the :set_backends client command with:
      | routename | pass1              |
      | service   | service-secure=1   |
      | service   | service-secure-2=9 |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | pass1            |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "roundrobin"
    """
    #Set one of the service weight to 0
    Given I switch to the first user
    When I run the :set_backends client command with:
      | routename | pass1              |
      | service   | service-secure=0   |
      | service   | service-secure-2=1 |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | pass1            |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "source"
    """
    #Set all the service weight to 0
    Given I switch to the first user
    When I run the :set_backends client command with:
      | routename | pass1              |
      | service   | service-secure=0   |
      | service   | service-secure-2=0 |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | pass1            |
      | -A               |
      | 10               |
      | haproxy.config   |
    Then the output should contain "source"
    """

  # @author yadu@redhat.com
  # @case_id OCP-15259
  Scenario: Could not set more than 3 additional backends for route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | service-unsecure     |
      | service   | service-unsecure=5   |
      | service   | service-unsecure-1=1 |
      | service   | service-unsecure-2=2 |
      | service   | service-unsecure-3=3 |
      | service   | service-unsecure-4=4 |
    Then the step should fail
    And the output should match:
      | cannot specify more than 3 .*backends |

  # @author yadu@redhat.com
  # @case_id OCP-15382
  Scenario: Set max backends weight for ab routing
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker-2.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-2.json |
    Then the step should succeed
    Given I wait for the "service-unsecure" service to become ready
    Given I wait for the "service-unsecure-2" service to become ready
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | service-unsecure      |
      | service   | service-unsecure=256  |
      | service   | service-unsecure-2=0  |
    Then the step should succeed
    When I wait up to 20 seconds for a web server to become available via the "service-unsecure" route
    Given I run the steps 10 times:
    """
    When I open web server via the "service-unsecure" route
    And the output should contain "Hello-OpenShift-1"
    And the output should not contain "Hello-OpenShift-2"
    """
    When I run the :set_backends client command with:
      | routename | service-unsecure      |
      | service   | service-unsecure=257  |
      | service   | service-unsecure-2=0  |
    Then the step should fail
    And the output should contain "weight must be an integer between 0 and 256"

  # @author yadu@redhat.com
  # @case_id OCP-15993
  Scenario: Each endpoint gets weight/numberOfEndpoints portion of the requests - edge route
    # Create pods and services
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/abwithrc_pod1.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/abwithrc_pod2.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/abwithrc_pod3.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/abwithrc_pod4.json |
    Then the step should succeed
    Given I wait for the "service-unsecure" service to become ready
    Given I wait for the "service-unsecure-2" service to become ready
    Given I wait for the "service-unsecure-3" service to become ready
    Given I wait for the "service-unsecure-4" service to become ready
    # Create route and set route backends
    When I run the :create_route_edge client command with:
      | name    | route-edge       |
      | service | service-unsecure |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge            |
      | service   | service-unsecure=20   |
      | service   | service-unsecure-2=10 |
      | service   | service-unsecure-3=30 |
      | service   | service-unsecure-4=40 |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge            |
    Then the step should succeed
    Then the output should contain:
      | 20% |
      | 10% |
      | 30% |
      | 40% |
    # Scale pods
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc-1              |
      | replicas | 2                      |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc-2              |
      | replicas | 4                      |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc-3              |
      | replicas | 3                      |
    Then the step should succeed
    And all pods in the project are ready
    # Access the route
    When I use the "service-unsecure" service
    Given the "access.log" file is deleted if it exists
    When I wait up to 20 seconds for a secure web server to become available via the "route-edge" route
    And I run the steps 20 times:
    """
    When I open secure web server via the "route-edge" route
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-4").size` is stored in the :accesslength4 clipboard
    Then the expression should be true> (6..10).include? cb.accesslength4
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-3").size` is stored in the :accesslength3 clipboard
    Then the expression should be true> (4..8).include? cb.accesslength3
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-2").size` is stored in the :accesslength2 clipboard
    Then the expression should be true> (1..3).include? cb.accesslength2
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-1").size` is stored in the :accesslength1 clipboard
    Then the expression should be true> (2..6).include? cb.accesslength1

  # @author yadu@redhat.com
  # @case_id OCP-15995
  Scenario: Each endpoint gets weight/numberOfEndpoints portion of the requests - reencrypt route
    # Create pods and services
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/abwithrc_pod1.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/abwithrc_pod2.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/abwithrc_pod3.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/abwithrc_pod4.json |
    Then the step should succeed
    Given I wait for the "service-secure" service to become ready
    Given I wait for the "service-secure-2" service to become ready
    Given I wait for the "service-secure-3" service to become ready
    Given I wait for the "service-secure-4" service to become ready
    # Create route and set route backends
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | route-reen              |
      | service    | service-secure          |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-reen          |
      | service   | service-secure=20   |
      | service   | service-secure-2=10 |
      | service   | service-secure-3=30 |
      | service   | service-secure-4=40 |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-reen            |
    Then the step should succeed
    Then the output should contain:
      | 20% |
      | 10% |
      | 30% |
      | 40% |
    # Scale pods
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc-1              |
      | replicas | 2                      |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc-2              |
      | replicas | 4                      |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc-3              |
      | replicas | 3                      |
    Then the step should succeed
    And all pods in the project are ready
    # Access the route
    When I use the "service-secure" service
    Given the "access.log" file is deleted if it exists
    When I wait up to 20 seconds for a secure web server to become available via the "route-reen" route
    And I run the steps 20 times:
    """
    When I open secure web server via the "route-reen" route
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-4").size` is stored in the :accesslength4 clipboard
    Then the expression should be true> (6..10).include? cb.accesslength4
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-3").size` is stored in the :accesslength3 clipboard
    Then the expression should be true> (4..8).include? cb.accesslength3
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-2").size` is stored in the :accesslength2 clipboard
    Then the expression should be true> (1..3).include? cb.accesslength2
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-1").size` is stored in the :accesslength1 clipboard
    Then the expression should be true> (2..6).include? cb.accesslength1

  # @author yadu@redhat.com
  # @case_id OCP-15902
  @admin
  Scenario: Endpoint will end up weight 1 when scaled weight per endpoint is less than 1
    # Create pods and services
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/abwithrc_pod1.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/abwithrc_pod2.json |
    Then the step should succeed
    Given I wait for the "service-secure" service to become ready
    Given I wait for the "service-secure-2" service to become ready
    # Create route and set route backends
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | service-unsecure      |
      | service   | service-unsecure=1    |
      | service   | service-unsecure-2=99 |
    Then the step should succeed
    # Scale pods
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc-1              |
      | replicas | 3                      |
    Then the step should succeed
    And all pods in the project are ready
    # Check the weight in haproxy.config
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep                             |
      | <%= cb.proj1 %>:service-unsecure |
      | -A                               |
      | 18                               |
      | haproxy.config                   |
    Then the output should contain 3 times:
      | weight 1 |
    """
    # Access the route
    When I use the "<%= cb.proj1 %>" project
    Given the "access.log" file is deleted if it exists
    When I wait up to 20 seconds for a web server to become available via the "service-unsecure" route
    And I run the steps 20 times:
    """
    When I open web server via the "service-unsecure" route
    And the output should contain "Hello-OpenShift"
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift-2").size` is stored in the :accesslength2 clipboard
    Then the expression should be true> (19..20).include? cb.accesslength2
