Feature: Testing route

  # @author: zzhao@redhat.com
  # @case_id: 470698
  Scenario: Be able to add more alias for service
    Given I have a project
    When I run the :create client command with:
      | f  |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/nginx-pod.json |
    Then the step should succeed
    When I run the :create client command with:
      | f  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    When I run the :create client command with:
      | f  | https://raw.githubusercontent.com/zhouying7780/v3-testfiles/master/routing/negative/route_with_no_host.json| 
    Then the step should succeed
    When I expose the "hello-nginx" service
    Then the step should succeed
    And I wait for a server to become available via the route
    And I wait for a server to become available via the "route" route

