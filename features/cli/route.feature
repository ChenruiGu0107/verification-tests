Feature: route related features via cli
  # @author yinzhou@redhat.com
  # @case_id 470733
  Scenario: Create a route without route's name named ---should be failed
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_nil_routename.json |
    Then the step should fail
    And the output should contain:
      | equired value |
    And the project is deleted
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_no_routename.json |
    Then the step should fail
    And the output should contain:
      | equired value |

  # @author yinzhou@redhat.com
  # @case_id 470734
  Scenario: Create a route without service named ---should be failed
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_nil_servicename.json |
    Then the step should fail
    And the output should contain:
      | equired value |
    And the project is deleted
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_no_servicename.json |
    Then the step should fail
    And the output should contain:
      | equired value |
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
    Given I wait for the "myapp" service to become ready
    When I expose the "myapp" service
    Then the step should succeed
    Given I get project routes
    And the output should match:
      | myapp .* 8080    |
    When I run the :describe client command with:
      | resource | route |
      | name     | myapp |
    Then the step should succeed
    And the output should match "Labels:\s+app=test-perl"
    When I wait for a web server to become available via the "myapp" route
    Then the output should contain "Everything is fine"

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

  # @author xiuwang@redhat.com
  # @case_id 511843
  Scenario: Handle openshift cluster dns in builder containner when do sti build
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift/ruby-hello-world.git |
      | image_stream | openshift/ruby |
    Then the step should succeed
    Then the "ruby-hello-world-1" build completed
    Given I wait for the "ruby-hello-world" service to become ready
    When I run the :expose client command with:
      | resource      | svc              |
      | resource name | ruby-hello-world |
    Then the step should succeed
    And evaluation of `route("ruby-hello-world", service("ruby-hello-world")).dns(by: user)` is stored in the :route_host clipboard
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift-qe/sti-ruby-test.git |
      | image_stream | openshift/ruby |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | builds          |
      | object_name_or_id | sti-ruby-test-1 |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig   |
      | resource_name | sti-ruby-test |
      | p | {"spec": {"strategy": {"sourceStrategy": {"env": [{"name": "APP_ROUTE","value": "<%= cb.route_host%>"}]}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sti-ruby-test|
      | follow | true |
      | wait   | true |
    And the output should contain:
      | Hello from OpenShift v3 |

  # @author cryan@redhat.com
  # @case_id 535239
  # @bug_id 1374772
  Scenario: haproxy config information should be clean when changing the service to another route
    Given I have a project
    #Create PodA & serviceA
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure.json |
    Then the step should succeed

    #Create PodB & serviceB
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker-2.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-2.json |
    Then the step should succeed

    Given a pod becomes ready with labels:
      | name=caddy-docker |
    And a pod becomes ready with labels:
      | name=caddy-docker-2 |
    When I expose the "service-unsecure" service
    Then the step should succeed
    #Enable roundrobin mode for haproxy to more reliably trigger the bug
    When I run the :patch client command with:
      | resource      | routes                                                                            |
      | resource_name | service-unsecure                                                                  |
      | p             | {"metadata":{"annotations":{"haproxy.router.openshift.io/balance":"roundrobin"}}} |
    Then the step should succeed
    When I open web server via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift-1 http-8080"
    When I run the :patch client command with:
      | resource      | routes                                         |
      | resource_name | service-unsecure                               |
      | p             | {"spec":{"to":{"name": "service-unsecure-2"}}} |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift-2 http-8080"
    """
    And I run the steps 10 times:
    """
    When I open web server via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift-2 http-8080"
    """
