Feature: route related features via cli
  # @author yinzhou@redhat.com
  # @case_id OCP-12559
  @flaky
  Scenario: Create a route without route's name named ---should be failed
    Given I have a project
    Given I obtain test data file "routing/negative/route_with_nil_routename.json"
    When I run the :create client command with:
      | f | route_with_nil_routename.json |
    Then the step should fail
    And the output should contain:
      | equired value |
    And the project is deleted
    Given I have a project
    Given I obtain test data file "routing/negative/route_with_no_routename.json"
    When I run the :create client command with:
      | f | route_with_no_routename.json |
    Then the step should fail
    And the output should contain:
      | equired value |

  # @author yinzhou@redhat.com
  # @case_id OCP-12560
  Scenario: Create a route without service named ---should be failed
    Given I have a project
    Given I obtain test data file "routing/negative/route_with_nil_servicename.json"
    When I run the :create client command with:
      | f | route_with_nil_servicename.json |
    Then the step should fail
    And the output should contain:
      | equired value |

    Given I obtain test data file "routing/negative/route_with_no_servicename.json"
    When I run the :create client command with:
      | f | route_with_no_servicename.json |
    Then the step should fail
    And the output should contain:
      | equired value |

  # @author yinzhou@redhat.com
  # @case_id OCP-12551
  Scenario: Create a route with invalid host ---should be failed
    Given I have a project
    Given I obtain test data file "routing/negative/route_with_invaid__host.json"
    When I run the :create client command with:
      | f | route_with_invaid__host.json |
    Then the step should fail
    And the output should contain:
      | DNS 952 subdomain |
    And the project is deleted

  # @author xiuwang@redhat.com
  # @case_id OCP-11209
  Scenario: Handle openshift cluster dns in builder containner when do sti build
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift/ruby-hello-world.git |
      | image_stream | openshift/ruby |
    Then the step should succeed
    Then the "ruby-hello-world-1" build completed
    Given I wait for the "ruby-hello-world" service to become ready up to 300 seconds
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

  # @author chuyu@redhat.com
  # @case_id OCP-15172
  Scenario: Changing from no-cert to edge encryption
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/appuio/example-php-sti-helloworld.git |
      | name     | example                                                  |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | svc     |
      | resource_name | example |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | route                                   |
      | resource_name | example                                 |
      | p             | {"spec":{"tls":{"termination":"edge"}}} |
    Then the step should succeed
