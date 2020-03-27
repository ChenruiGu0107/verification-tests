Feature: oc_label.feature

  # @author cryan@redhat.com
  # @case_id OCP-12505
  Scenario: Add or update the openshift resource label
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/hello-pod.json |
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
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/tc482217/hello-pod.json |
    Then the step should succeed
    When I run the :label client command with:
      | resource  | pods           |
      | all       | true           |
      | key_val   | status=healthy |
      | overwrite | true           |
    Then the step should succeed
    And the output should match:
      | hello-openshift"? labeled |
      | tc482217-pod"? labeled    |
    When I run the :describe client command with:
      | resource | pod |
    Then the step should succeed
    And the output should match:
      | Labels:\\s+name=hello-openshift[\s,]+status=healthy |
      | Labels:\\s+name=tc482217-pod[\s,]+status=healthy    |
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
