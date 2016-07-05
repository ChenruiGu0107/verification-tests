Feature: configMap
  # @author chezhang@redhat.com
  # @case_id 520893
  Scenario: Consume ConfigMap in environment variables
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA        |
      | special-config.*2 |
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | special-config |
    Then the output should match:
      | special.how.*4 bytes  |
      | special.type.*5 bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-env.yaml |
    Then the step should succeed
    And the pod named "dapi-test-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-test-pod |
    Then the step should succeed
    And the output should contain:
      | SPECIAL_TYPE_KEY=charm |
      | SPECIAL_LEVEL_KEY=very |


  # @author chezhang@redhat.com
  # @case_id 520894
  Scenario: Consume ConfigMap via volume plugin
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA        |
      | special-config.*2 |
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | special-config |
    Then the output should match:
      | special.how.*4 bytes  |
      | special.type.*5 bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-volume1.yaml |
    Then the step should succeed
    And the pod named "dapi-test-pod-1" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-test-pod-1 |
    Then the step should succeed
    And the output should contain:
      | very |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-volume2.yaml |
    Then the step should succeed
    And the pod named "dapi-test-pod-2" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-test-pod-2 |
    Then the step should succeed
    And the output should contain:
      | charm |


  # @author chezhang@redhat.com
  # @case_id 520895
  Scenario: Perform CRUD operations against a ConfigMap resource
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap-example.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA        |
      | example-config.*3 |
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | example-config |
    Then the output should match:
      | example.property.file.*56 bytes |
      | example.property.1.*5 bytes     |
      | example.property.2.*5 bytes     |
    When I run the :patch client command with:
      | resource | configmap |
      | resource_name | example-config |
      | p | {"data":{"example.property.1":"hello_configmap_update"}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | example-config |
    Then the output should match:
      | example.property.file.*56 bytes |
      | example.property.1.*22 bytes    |
      | example.property.2.*5 bytes     |
    When I run the :delete client command with:
      | object_type | configmap         |
      | object_name_or_id | example-config |
    Then the step should succeed
    And the output should match:
      | configmap "example-config" deleted |


  # @author chezhang@redhat.com
  # @case_id 520903
  Scenario: Set command-line arguments with ConfigMap
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA        |
      | special-config.*2 |
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | special-config |
    Then the output should match:
      | special.how.*4 bytes  |
      | special.type.*5 bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-command.yaml |
    Then the step should succeed
    And the pod named "dapi-test-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-test-pod |
    Then the step should succeed
    And the output should contain:
      | very charm |
