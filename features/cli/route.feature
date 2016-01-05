Feature: route related features via cli
  # @author yinzhou@redhat.com
  # @case_id 470733
  Scenario: Create a route without route's name named ---should be failed
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_nil_routename.json |
    Then the step should fail
    And the output should contain:
      | required value |
    And the project is deleted
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_no_routename.json |
    Then the step should fail
    And the output should contain:
      | required value |
    And the project is deleted

  # @author yinzhou@redhat.com
  # @case_id 470734
  Scenario: Create a route without service named ---should be failed
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_nil_servicename.json |
    Then the step should fail
    And the output should contain:
      | required value |
    And the project is deleted
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_no_servicename.json |
    Then the step should fail
    And the output should contain:
      | required value |
    And the project is deleted

  # @author yinzhou@redhat.com
  # @case_id 470731
  Scenario: Create a route with invalid host ---should be failed
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_invaid__host.json |
    Then the step should fail
    And the output should contain:
      | DNS 952 subdomain |
    And the project is deleted

  # @author cryan@redhat.com
  # @case_id 483239
  Scenario: Expose routes from services
    Given I have a project
    When I run the :new_app client command with:
      | code | https://github.com/openshift/sti-perl |
      | l | app=test-perl|
      | context_dir | 5.20/test/sample-test-app/ |
      | name | myapp |
    Then the step should succeed
    And the "myapp-1" build completed
    When I run the :expose client command with:
      | resource | svc |
      | resource_name | myapp |
    Then the step should succeed
    And the output should contain "app=test-perl"
    When I run the :get client command with:
      | resource | route |
    Then the step should succeed
    And the output should contain "app=test-perl"
    When I run the :describe client command with:
      | resource | route |
      | name | myapp |
    Then the step should succeed
    And the output should match "Labels:\s+app=test-perl"
    When I use the "myapp" service
    Then the output should contain "OpenShift"

  # @author cryan@redhat.com
  # @case_id 470699
  Scenario: Be unable to add an existed alias name for service
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/route_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/route_unsecure.json |
    Then the step should fail
    And the output should contain "routes "route" already exists"

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
      | /var/lib/containers/router/certs |
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
