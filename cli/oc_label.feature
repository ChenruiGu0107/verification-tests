Feature: oc_label.feature

  # @author cryan@redhat.com
  # @case_id OCP-12505
  Scenario: Add or update the openshift resource label
    Given I have a project
    Given I obtain test data file "pods/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed
    When I run the :label client command with:
      | resource | pods            |
      | name     | hello-openshift |
      | key_val  | status=healthy  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod             |
      | name     | hello-openshift |
    Then the step should succeed
    And the output should match:
      |Labels:\\s+name=hello-openshift[\s,]+status=healthy|
    When I run the :label client command with:
      | resource | pods             |
      | name     | hello-openshift  |
      | key_val  | status=unhealthy |
    Then the step should fail
    And the output should contain:
      | already has a value  |
      | --overwrite is false |
    When I run the :label client command with:
      | resource  | pods             |
      | name      | hello-openshift  |
      | key_val   | status=unhealthy |
      | overwrite | true             |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod             |
      | name     | hello-openshift |
    Then the step should succeed
    And the output should match:
      | Labels:\\s+name=hello-openshift[\s,]+status=unhealthy |
    Given I obtain test data file "templates/ocp12505/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed
    When I run the :label client command with:
      | resource  | pods           |
      | all       | true           |
      | key_val   | status=healthy |
      | overwrite | true           |
    Then the step should succeed
    And the output should match:
      | hello-openshift"? labeled |
      | ocp12505-pod"? labeled    |
    When I run the :describe client command with:
      | resource | pod |
    Then the step should succeed
    And the output should match:
      | Labels:\\s+name=hello-openshift[\s,]+status=healthy |
      | Labels:\\s+name=ocp12505-pod[\s,]+status=healthy    |
    When I run the :label client command with:
      | resource | pods            |
      | name     | hello-openshift |
      | key_val  | status=""       |
    Then the step should fail
    And the output should match "invalid label (value|spec)|at least one label update is required"
    When I run the :label client command with:
      | resource | pods            |
      | name     | hello-openshift |
      | key_val  | status=$%@#     |
    Then the step should fail
    When I run the :label client command with:
      | resource | pods            |
      | name     | hello-openshift |
      | key_val  | status-         |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod             |
      | name     | hello-openshift |
    Then the step should succeed
    And the output should not contain "status=unhealthy"
