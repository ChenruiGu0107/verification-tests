Feature: Stateful Set related feature on web console
  # @author yapei@redhat.com
  # @case_id OCP-15128
  Scenario: Environment handling for StatefulSet
    Given the master version >= "3.7"
    Given I create a new project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/hello-statefulset.yaml |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/secret.yaml                |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.yaml           |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | app=hello-pod |
    When I perform the :goto_stateful_sets_environment_tab web console action with:
      | project_name       | <%= project.name %> |
      | stateful_sets_name | hello-statefulset   |
    Then the step should succeed
    When I perform the :add_env_vars web console action with:
      | env_var_key   | env1   |
      | env_var_value | value1 |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | statefulsets      |
      | resource_name | hello-statefulset |
      | o             | json              |
    Then the step should succeed
    And the output should contain:
      | env1   |
      | value1 |

    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | my_configmap   |
      | resource_name | special-config |
      | resource_key  | special.how    |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | my_secret   |
      | resource_name | test-secret |
      | resource_key  | data-1      |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | statefulsets      |
      | resource_name | hello-statefulset |
      | o             | json              |
    Then the step should succeed
    And the output should match:
      | configMapKeyRef      |
      | key.*special.how     |
      | name.*special-config |
      | secretKeyRef         |
      |  key.*data-1         |
      | name.*test-secret    |
