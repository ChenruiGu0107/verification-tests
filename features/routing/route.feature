Feature: Testing route

  # @author: zzhao@redhat.com
  # @case_id: 470698
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
    And I wait for a server to become available via the route
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
    Then I wait for a server to become available via the "header-test-insecure-dup" route

  # @author: zzhao@redhat.com
  # @case_id: 470700
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
    Then I wait for a server to become available via the "header-test-insecure" route
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
  # @case_id 483200
  @admin
  Scenario: The certs for the edge/reencrypt termination routes should be removed when the routes removed
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard

    Given I switch to the first user
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge.json |
    Then the step should succeed

    Then evaluation of `project.name` is stored in the :proj_name clipboard
    And evaluation of `"secured-edge-route"` is stored in the :edge_route clipboard
    And evaluation of `"route-reencrypt"` is stored in the :reencrypt_route clipboard

    When I switch to cluster admin pseudo user
    And I use the "default" project
    And I execute on the "<%= cb.router_pod %>" pod:
      | ls                  |
      | /var/lib/containers/router/certs |
    Then the step should succeed
    And the output should contain:
      | _<%= cb.edge_route %>.pem |
      | _<%= cb.reencrypt_route %>.pem |
    When I execute on the pod:
      | ls                  |
      | /var/lib/containers/router/cacerts |
    Then the step should succeed
    And the output should contain:
      | _<%= cb.reencrypt_route %>.pem |

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
      | ls                  |
      | /var/lib/containers/router/certs |
    Then the step should succeed
    And the output should not contain:
      | _<%= cb.edge_route %>.pem |
    And the output should contain:
      | _<%= cb.reencrypt_route %>.pem |

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
      | ls                  |
      | /var/lib/containers/router/certs   |
      | /var/lib/containers/router/cacerts |
    Then the step should succeed
    And the output should not contain:
      | <%= cb.proj_name %>_<%= cb.reencrypt_route %>.pem |

    Then I switch to the first user
    And I use the "<%= cb.proj_name %>" project

  # @author yadu@redhat.com
  # @case_id 497886
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
  # @case_id: 516833
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
    When I get project route as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['host']` is stored in the :header_test clipboard
    When I wait for a server to become available via the route
    Then the output should contain ";host=<%= cb.header_test %>;proto=http"
