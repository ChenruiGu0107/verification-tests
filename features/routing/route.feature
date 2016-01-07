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
