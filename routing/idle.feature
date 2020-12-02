Feature: idle service related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-20989
  Scenario: haproxy should load other routes even if headless service is idled
    Given I have a project
    Given I obtain test data file "routing/dns/headless-services.yaml"
    When I run oc create over "headless-services.yaml" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given I wait until number of replicas match "1" for replicationController "web-server-rc"
    And a pod becomes ready with labels:
      | name=web-server-rc |
    When I run the :idle client command with:
      | svc_name | service-unsecure |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "web-server-rc"

    Given I create a new project
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
    When I wait up to 30 seconds for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"
