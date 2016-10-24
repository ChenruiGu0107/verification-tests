Feature: Testing abrouting

  # @author yadu@redhat.com
  # @case_id 531404
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

  # @author yadu@redhat.com
  # @case_id 533859
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
    Given I have a pod-for-ping in the project
    Given I run the steps 10 times:
    """
    When I execute on the pod:
      | curl                                                                     |
      | -sS                                                                       |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k                                                                       |
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
      | -sS                                                                       |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k                                                                       |
    Then the output should contain "503"
    """

  # @author yadu@redhat.com
  # @case_id 531409
  Scenario: Set weight for unsecure route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
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
    When I run the :annotate client command with:
      | resource     | route                                          |
      | resourcename | service-unsecure                               |
      | overwrite    | true                                           |
      | keyval       | haproxy.router.openshift.io/balance=roundrobin |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | service-unsecure      |
      | service   | service-unsecure=20   |
      | service   | service-unsecure-2=80 |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | service-unsecure      |
    Then the step should succeed
    Then the output should contain 1 times:
      | (20%) |
      | (80%) |
    Given I have a pod-for-ping in the project
    Given I run the steps 20 times:
    """
    When I execute on the pod:
      | curl      |
      | --resolve |
      | -sS       |
      | <%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>:80:<%= cb.router_ip[0] %> |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-2")}.length` is stored in the :accesslength2 clipboard
    Then the expression should be true> cb.accesslength2 == 16
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-1")}.length` is stored in the :accesslength1 clipboard
    Then the expression should be true> cb.accesslength1 == 4
    When I run the :set_backends client command with:
      | routename | service-unsecure      |
      | adjust    | true                  |
      | service   | service-unsecure=-10% |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | service-unsecure      |
    Then the step should succeed
    Then the output should contain 1 times:
      | (10%) |
      | (90%) |
    Given I run the steps 20 times:
    """
    When I execute on the pod:
      | curl      |
      | --resolve |
      | -sS       |
      | <%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>:80:<%= cb.router_ip[0] %> |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the "access1.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access1.log").split("\n").select {|str| str.include?("Hello-OpenShift-2")}.length` is stored in the :accesslength4 clipboard
    Then the expression should be true> cb.accesslength4 == 18
    Given evaluation of `File.read("access1.log").split("\n").select {|str| str.include?("Hello-OpenShift-1")}.length` is stored in the :accesslength3 clipboard
    Then the expression should be true> cb.accesslength3 == 2


  # @author yadu@redhat.com
  # @case_id 531406
  Scenario: Set backends weight for edge route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
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
      | service   | service-unsecure=60   |
      | service   | service-unsecure-2=80 |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge  |
    Then the step should succeed
    Then the output should contain 1 times:
      | 60 |
      | 80 |
    Given I have a pod-for-ping in the project
    Given I run the steps 20 times:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-edge", service("route-edge")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -ksS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-2")}.length` is stored in the :accesslength2 clipboard
    Then the expression should be true> cb.accesslength2 == 12
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-1")}.length` is stored in the :accesslength1 clipboard
    Then the expression should be true> cb.accesslength1 == 8
    When I run the :set_backends client command with:
      | routename | route-edge             |
      | adjust    | true                   |
      | service   | service-unsecure=20    |
    When I run the :set_backends client command with:
      | routename | route-edge |
    Then the step should succeed
    Then the output should contain 1 times:
      | (20%) |
      | (80%) |
    Given I run the steps 20 times:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-edge", service("route-edge")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -ksS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

    And the "access1.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access1.log").split("\n").select {|str| str.include?("Hello-OpenShift-2")}.length` is stored in the :accesslength4 clipboard
    Then the expression should be true> cb.accesslength4 == 16
    Given evaluation of `File.read("access1.log").split("\n").select {|str| str.include?("Hello-OpenShift-1")}.length` is stored in the :accesslength3 clipboard
    Then the expression should be true> cb.accesslength3 == 4


  # @author yadu@redhat.com
  # @case_id 531407
  Scenario: Set backends weight for passthough route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
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
      | service   | service-secure=20   |
      | service   | service-secure-2=80 |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-pass  |
    Then the step should succeed
    Then the output should contain 1 times:
      | (20%) |
      | (80%) |
    Given I have a pod-for-ping in the project
    Given I run the steps 20 times:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-pass", service("route-pass")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-pass", service("route-pass")).dns(by: user) %>/ |
      | -ksS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-2")}.length` is stored in the :accesslength2 clipboard
    Then the expression should be true> cb.accesslength2 == 16
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-1")}.length` is stored in the :accesslength1 clipboard
    Then the expression should be true> cb.accesslength1 == 4
    When I run the :set_backends client command with:
      | routename | route-pass            |
      | adjust    | true                  |
      | service   | service-secure=+20%   |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-pass  |
    Then the step should succeed
    Then the output should contain 1 times:
      | (40%) |
      | (60%) |
    Given I run the steps 20 times:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-pass", service("route-pass")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-pass", service("route-pass")).dns(by: user) %>/ |
      | -ksS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the "access1.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access1.log").split("\n").select {|str| str.include?("Hello-OpenShift-2")}.length` is stored in the :accesslength4 clipboard
    Then the expression should be true> cb.accesslength4 == 12
    Given evaluation of `File.read("access1.log").split("\n").select {|str| str.include?("Hello-OpenShift-1")}.length` is stored in the :accesslength3 clipboard
    Then the expression should be true> cb.accesslength3 == 8


  # @author yadu@redhat.com
  # @case_id 531408
  @case_id 531407
  Scenario: Set backends weight for reencrypt route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker-2.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/reencrypt/service_secure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/reencrypt/service_secure-2.json |
    Then the step should succeed
    Given I wait for the "service-secure" service to become ready
    Given I wait for the "service-secure-2" service to become ready
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
      | resource     | route                                          |
      | resourcename | route-reencrypt                                |
      | overwrite    | true                                           |
      | keyval       | haproxy.router.openshift.io/balance=roundrobin |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-reencrypt     |
      | service   | service-secure=3    |
      | service   | service-secure-2=7  |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-reencrypt |
    Then the step should succeed
    Then the output should contain 1 times:
      | (30%) |
      | (70%) |
    Given I have a pod-for-ping in the project
    Given I run the steps 10 times:
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
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-2")}.length` is stored in the :accesslength2 clipboard
    Then the expression should be true> cb.accesslength2 == 7
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-1")}.length` is stored in the :accesslength1 clipboard
    Then the expression should be true> cb.accesslength1 == 3
    When I run the :set_backends client command with:
      | routename | route-reencrypt        |
      | adjust    | true                   |
      | service   | service-secure=-20%  |
    When I run the :set_backends client command with:
      | routename | route-reencrypt |
    Then the step should succeed
    Then the output should contain 1 times:
      | (10%) |
      | (90%) |
    Then the step should succeed
    Given I run the steps 10 times:
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

    And the "access1.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access1.log").split("\n").select {|str| str.include?("Hello-OpenShift-2")}.length` is stored in the :accesslength4 clipboard
    Then the expression should be true> cb.accesslength4 == 9
    Given evaluation of `File.read("access1.log").split("\n").select {|str| str.include?("Hello-OpenShift-1")}.length` is stored in the :accesslength3 clipboard
    Then the expression should be true> cb.accesslength3 == 1

  # @author yadu@redhat.com
  # @case_id 531405
  Scenario: Set negative backends weight for ab routing
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
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
  # @case_id 534317
  Scenario: Set backends weight for edge route
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
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
      | service   | service-unsecure=2   |
      | service   | service-unsecure-2=3 |
      | service   | service-unsecure-3=5 |
    Then the step should succeed
    When I run the :set_backends client command with:
      | routename | route-edge  |
    Then the step should succeed
    Then the output should contain:
      | 20% |
      | 30% |
      | 50% |
    Given I have a pod-for-ping in the project
    Given I run the steps 20 times:
    """
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("route-edge", service("route-edge")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -ksS |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    And the "access.log" file is appended with the following lines:
      | #{@result[:response].strip} |
    """
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-3")}.length` is stored in the :accesslength3 clipboard
    Then the expression should be true> cb.accesslength3 == 10
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-2")}.length` is stored in the :accesslength2 clipboard
    Then the expression should be true> cb.accesslength2 == 6
    Given evaluation of `File.read("access.log").split("\n").select {|str| str.include?("Hello-OpenShift-1")}.length` is stored in the :accesslength1 clipboard
    Then the expression should be true> cb.accesslength1 == 4
