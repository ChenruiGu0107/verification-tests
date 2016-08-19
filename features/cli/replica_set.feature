Feature: replicaSet related tests
  # @author pruan@redhat.com
  # @case_id 533162
  Scenario: Support endpoints of RS in OpenShift
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/replicaSet/tc533162/rs_endpoints.yaml |
    Then the step should succeed
    And the expression should be true> rs('frontend').replicas(user: user) == 3
    When I run the :patch client command with:
      | resource      | rs                      |
      | resource_name | frontend                |
      | p             | {"spec":{"replicas":4}} |
    Then the step should succeed
    And the expression should be true> rs('frontend').replicas(user: user) == 4
    When I run the :delete client command with:
      | object_type       | rs       |
      | object_name_or_id | frontend |
    Then the step should succeed
    # verified that the rs is gone
    When I run the :get client command with:
      | resource      | rs       |
      | resource_name | frontend |
    Then the step should not succeed
    And the output should contain:
      | replicasets "frontend" not found |
