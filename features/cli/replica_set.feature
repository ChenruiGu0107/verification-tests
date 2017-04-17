Feature: replicaSet related tests
  # @author pruan@redhat.com
  # @case_id OCP-10917
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

  # @author pruan@redhat.com
  # @case_id OCP-11327
  Scenario: Support to scale up/down with ReplicaSets in OpenShift
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/replicaSet/tc533163/rs.yaml |
    Then the step should succeed
    And I run the :scale client command with:
      | resource | replicaset |
      | name     | frontend   |
      | replicas | 2          |
    Then the step should succeed
    And I wait until number of replicas match "2" for replicaSet "frontend"
    And I run the :scale client command with:
      | resource | replicaset |
      | name     | frontend   |
      | replicas | 1          |
    Then the step should succeed
    And I wait until number of replicas match "1" for replicaSet "frontend"


