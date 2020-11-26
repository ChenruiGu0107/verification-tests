Feature: idle service related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-20989
  Scenario: haproxy should load other routes even if headless service is idled
    Given I have a project
    Given I obtain test data file "routing/dns/headless-services.json"
    When I run oc create over "headless-services.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given I wait until number of replicas match "1" for replicationController "caddy-rc"
    And a pod becomes ready with labels:
      | name=caddy-pods |
    When I run the :idle client command with:
      | svc_name | service-unsecure |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "caddy-rc"

    Given I create a new project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I wait up to 30 seconds for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"
