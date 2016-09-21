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
      | -s                                                                       |
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
      | -s                                                                       |
      | https://<%= route("route-edge", service("route-edge")).dns(by: user) %>/ |
      | -k                                                                       |
    Then the output should contain "503"
    """
