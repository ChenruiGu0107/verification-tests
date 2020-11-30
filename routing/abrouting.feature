Feature: Testing abrouting

  # @author yadu@redhat.com
  # @case_id OCP-10889
  Scenario: Sticky session could work normally after set weight for route
    Given I have a project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
    Then the step should succeed
    And all pods in the project are ready

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
    # access the route without cookies
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
    And the output should contain "Hello-OpenShift abtest-websrv1"
    """
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift abtest-websrv2"
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
    And the output should contain "Hello-OpenShift abtest-websrv1"
    """

  # @author yadu@redhat.com
  # @case_id OCP-11351
  Scenario: Set backends weight to zero for ab routing
    Given I have a project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
    Then the step should succeed
    And all pods in the project are ready

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
    And the output should contain "Hello-OpenShift abtest-websrv1"
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
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl                                                                     |
      | -I                                                                       |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k                                                                       |
    Then the output should contain "503 Service Unavailable"
    """
    Given I run the steps 10 times:
    """
    When I execute on the pod:
      | curl                                                                     |
      | -I                                                                       |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k                                                                       |
    Then the output should contain "503 Service Unavailable"
    """

  # @author hongli@redhat.com
  # @case_id OCP-11608
  @admin
  Scenario: Set backends weight for edge route
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv1 |
    And evaluation of `pod.ip` is stored in the :pod_ip1 clipboard
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv2 |
    And evaluation of `pod.ip` is stored in the :pod_ip2 clipboard

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

    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep | <%= cb.pod_ip1 %> | /var/lib/haproxy/conf/haproxy.config | -C 1 |
    Then the output should match:
      | <%= cb.pod_ip1 %>.* weight 64  |
      | <%= cb.pod_ip2 %>.* weight 256 |
    """

  # @author hongli@redhat.com
  # @case_id OCP-11809
  @admin
  Scenario: Set backends weight for passthough route
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv1 |
    And evaluation of `pod.ip` is stored in the :pod_ip1 clipboard
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv2 |
    And evaluation of `pod.ip` is stored in the :pod_ip2 clipboard

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

    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep | <%= cb.pod_ip1 %> | /var/lib/haproxy/conf/haproxy.config | -C 1 |
    Then the output should match:
      | <%= cb.pod_ip1 %>.* weight 109 |
      | <%= cb.pod_ip2 %>.* weight 256 |
    """

  # @author yadu@redhat.com
  # @case_id OCP-11306
  Scenario: Set negative backends weight for ab routing
    Given I have a project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
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

  # @author hongli@redhat.com
  # @case_id OCP-12088
  @admin
  Scenario: Set multiple backends weight for route
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv1 |
    And evaluation of `pod.ip` is stored in the :pod_ip1 clipboard
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv2 |
    And evaluation of `pod.ip` is stored in the :pod_ip2 clipboard
    Given I obtain test data file "routing/abrouting/abtest-websrv3.yaml"
    When I run the :create client command with:
      | f | abtest-websrv3.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv3 |
    And evaluation of `pod.ip` is stored in the :pod_ip3 clipboard

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

    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep | <%= cb.pod_ip1 %> | /var/lib/haproxy/conf/haproxy.config | -C 2 |
    Then the output should match:
      | <%= cb.pod_ip1 %>.* weight 102 |
      | <%= cb.pod_ip2 %>.* weight 153 |
      | <%= cb.pod_ip3 %>.* weight 256 |
    """

  # @author yadu@redhat.com
  # @case_id OCP-13252
  @admin
  Scenario: The unsecure route with multiple service will set load balance policy to RoundRobin by default
    #Create pod/service/route
    Given I have a project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
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
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/example_wildcard.pem"
    Given I obtain test data file "routing/example_wildcard.key"
    Given I obtain test data file "routing/reencrypt/route_reencrypt.ca"
    Given I obtain test data file "routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | reen1                                     |
      | hostname   | <%= rand_str(5, :dns) %>-reen.example.com |
      | service    | service-secure                            |
      | cert       | example_wildcard.pem                      |
      | key        | example_wildcard.key                      |
      | cacert     | route_reencrypt.ca                        |
      | destcacert | route_reencrypt_dest.ca                   |
    Then the step should succeed
    #Check the default load blance policy
    Given I switch to cluster admin pseudo user
    And I use the router project
    And all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep           |
      | reen1          |
      | -A             |
      | 10             |
      | haproxy.config |
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
      | grep           |
      | reen1          |
      | -A             |
      | 10             |
      | haproxy.config |
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
      | grep           |
      | reen1          |
      | -A             |
      | 10             |
      | haproxy.config |
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
      | grep           |
      | reen1          |
      | -A             |
      | 10             |
      | haproxy.config |
    Then the output should contain "leastconn"
    """

  # @author hongli@redhat.com
  # @case_id OCP-13521
  @admin
  Scenario: The passthrough route with multiple service will set load balance policy to RoundRobin by default
    #Create pod/service/route
    Given I have a project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
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
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep             |
      | pass1            |
      | -A               |
      | 5                |
      | haproxy.config   |
    Then the output should contain "source"
    """
    #Add multiple services to route, then use roundrobin policy
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
      | 5                |
      | haproxy.config   |
    Then the output should contain "roundrobin"
    """
    #Set one of the service weight to 0, then use the default source policy
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
      | 5                |
      | haproxy.config   |
    Then the output should contain "source"
    """

  # @author yadu@redhat.com
  # @case_id OCP-15259
  Scenario: Could not set more than 3 additional backends for route
    Given I have a project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
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
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
    Then the step should succeed
    And all pods in the project are ready

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
    And the output should contain "Hello-OpenShift abtest-websrv1"
    And the output should not contain "Hello-OpenShift abtest-websrv2"
    """
    When I run the :set_backends client command with:
      | routename | service-unsecure      |
      | service   | service-unsecure=257  |
      | service   | service-unsecure-2=0  |
    Then the step should fail
    And the output should contain "weight must be an integer between 0 and 256"

  # @author hongli@redhat.com
  # @case_id OCP-15993
  @admin
  Scenario: Each endpoint gets weight/numberOfEndpoints portion of the requests - edge route
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    # Create pods and services
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    Given I obtain test data file "routing/abrouting/abtest-websrv3.yaml"
    Given I obtain test data file "routing/abrouting/abtest-websrv4.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
      | f | abtest-websrv2.yaml |
      | f | abtest-websrv3.yaml |
      | f | abtest-websrv4.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv1 |
    And evaluation of `pod.ip` is stored in the :pod_ip clipboard
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
      | name     | abtest-websrv1         |
      | replicas | 2                      |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | abtest-websrv2         |
      | replicas | 4                      |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | abtest-websrv3         |
      | replicas | 3                      |
    Then the step should succeed
    And all pods in the project are ready

    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep | <%= cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config | -C 9 |
    Then the output should match 2 times:
      | :service-unsecure:.* weight 64    |
    Then the output should match 4 times:
      | :service-unsecure-2:.* weight 16  |
    Then the output should match 3 times:
      | :service-unsecure-3:.* weight 64  |
    Then the output should match 1 times:
      | :service-unsecure-4:.* weight 256 |
    """

  # @author hongli@redhat.com
  # @case_id OCP-15995
  @admin
  Scenario: Each endpoint gets weight/numberOfEndpoints portion of the requests - reencrypt route
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    # Create pods and services
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    Given I obtain test data file "routing/abrouting/abtest-websrv3.yaml"
    Given I obtain test data file "routing/abrouting/abtest-websrv4.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
      | f | abtest-websrv2.yaml |
      | f | abtest-websrv3.yaml |
      | f | abtest-websrv4.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv1 |
    And evaluation of `pod.ip` is stored in the :pod_ip clipboard
    # Create route and set route backends
    Given I obtain test data file "routing/reencrypt/route_reencrypt_dest.ca"
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
      | routename | route-reen |
    Then the step should succeed
    Then the output should contain:
      | 20% |
      | 10% |
      | 30% |
      | 40% |
    # Scale pods
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | abtest-websrv1         |
      | replicas | 2                      |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | abtest-websrv2         |
      | replicas | 4                      |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | abtest-websrv3         |
      | replicas | 3                      |
    Then the step should succeed
    And all pods in the project are ready

    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | grep | <%= cb.pod_ip %> | /var/lib/haproxy/conf/haproxy.config | -C 9 |
    Then the output should match 2 times:
      | :service-secure:.* weight 64    |
    Then the output should match 4 times:
      | :service-secure-2:.* weight 16  |
    Then the output should match 3 times:
      | :service-secure-3:.* weight 64  |
    Then the output should match 1 times:
      | :service-secure-4:.* weight 256 |
    """

  # @author yadu@redhat.com
  # @case_id OCP-15902
  @admin
  Scenario: Endpoint will end up weight 1 when scaled weight per endpoint is less than 1
    # Create pods and services
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
      | f | abtest-websrv2.yaml |
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
      | name     | abtest-websrv1         |
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
    Given evaluation of `File.read("access.log").scan("Hello-OpenShift abtest-websrv2").size` is stored in the :accesslength2 clipboard
    Then the expression should be true> (19..20).include? cb.accesslength2
