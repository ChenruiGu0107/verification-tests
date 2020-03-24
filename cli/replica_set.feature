Feature: replicaSet related tests

  # @author pruan@redhat.com
  # @case_id OCP-11327
  Scenario: Support to scale up/down with ReplicaSets in OpenShift
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/replicaSet/tc533163/rs.yaml |
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


