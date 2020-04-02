Feature: StatefulSet related tests
  # @author dma@redhat.com
  # @case_id OCP-12981
  @destructive
  @admin
  Scenario: Using persistent storage in StatefulSet
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/stable-storage.yaml  |
      | n | <%= project.name %> |
    Then the step should succeed
    Given the pod named "hello-statefulset-0" becomes ready
    And evaluation of `pod.node_name` is stored in the :pod1_node clipboard
    When I execute on the pod:
      | /bin/bash                                                        |
      | -c                                                               |
      | echo "test-statefulset-0" > /tmp/index.html; cat /tmp/index.html |
    Then the step should succeed
    And the output should contain:
      | test-statefulset-0 |
    Given the pod named "hello-statefulset-1" becomes ready
    And evaluation of `pod.node_name` is stored in the :pod2_node clipboard
    When I run the :exec client command with:
      | pod              | hello-statefulset-1 |
      | c                | hello-pod           |
      | exec_command     | --                  |
      | exec_command     | /bin/bash           |
      | exec_command_arg | -c                  |
      | exec_command_arg | echo "test-statefulset-1" > /tmp/index.html; cat /tmp/index.html |
    Then the step should succeed
    And the output should contain:
      | test-statefulset-1 |
    Given node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | <%= cb.pod1_node %> |
    Then the step should succeed
    Given I ensure "hello-statefulset-0" pod is deleted
    Given the pod named "hello-statefulset-0" becomes ready
    Then I execute on the pod:
      | cat | /tmp/index.html |
    Then the step should succeed
    And the output should contain:
      | test-statefulset-0 |
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.pod1_node %> |
    Then the step should succeed
    When I run the :oadm_cordon_node admin command with:
      | node_name | <%= cb.pod2_node %> |
    Then the step should succeed
    Given I ensure "hello-statefulset-0" pod is deleted
    Given the pod named "hello-statefulset-1" becomes ready
    Then I run the :exec client command with:
      | pod              | hello-statefulset-1 |
      | c                | hello-pod           |
      | exec_command     | --                  |
      | exec_command     | /bin/bash           |
      | exec_command_arg | -c                  |
      | exec_command_arg | cat /tmp/index.html |
    Then the step should succeed
    And the output should contain:
      | test-statefulset-1 |

  # @author dma@redhat.com
  # @case_id OCP-12983
  Scenario: Scaling up/down StatefulSet
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/hello-statefulset.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    Given the pod named "hello-statefulset-0" becomes ready
    Given the pod named "hello-statefulset-1" becomes ready
    Given I wait until number of replica_count match "2" for StatefulSet "hello-statefulset"
    When I run the :scale client command with:
      | resource | statefulset       |
      | name     | hello-statefulset |
      | replicas | 5                 |
    Then the step should succeed
    And the output should match:
      | statefulset(\.apps)?(/)?( ")?hello-statefulset(")? scaled |
    Given the pod named "hello-statefulset-2" becomes ready
    Given the pod named "hello-statefulset-3" becomes ready
    Given the pod named "hello-statefulset-4" becomes ready
    Given I wait until number of replica_count match "5" for StatefulSet "hello-statefulset"
    When I run the :scale client command with:
      | resource | statefulset       |
      | name     | hello-statefulset |
      | replicas | 3                 |
    Given I wait until number of replica_count match "3" for StatefulSet "hello-statefulset"
    Then the pod named "hello-statefulset-0" becomes ready
    Then the pod named "hello-statefulset-1" becomes ready
    Then the pod named "hello-statefulset-2" becomes ready
    And the pod named "hello-statefulset-3" does not exist
    And the pod named "hello-statefulset-4" does not exist

  # @author dma@redhat.com
  # @case_id OCP-12987
  @admin
  Scenario: Deleting StatefulSets
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/stable-storage.yaml |
      | n | <%= project.name %>|
    Then the step should succeed
    And I wait for the "hello-statefulset" statefulset to appear
    And I wait for the "foo" service to appear
    Given the "www-hello-statefulset-0" PVC becomes :bound
    Given the "www-hello-statefulset-1" PVC becomes :bound
    Given the pod named "hello-statefulset-0" becomes ready
    Given the pod named "hello-statefulset-1" becomes ready
    Given I ensure "hello-statefulset" statefulset is deleted
    Then I check that there are no pods in the project
    Then I check that the "foo" service exists in the project
    And I check that the "www-hello-statefulset-0" persistentvolumeclaim exists in the project
    And I check that the "www-hello-statefulset-1" persistentvolumeclaim exists in the project
    When I delete the project
    Then the step should succeed

    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/stable-storage.yaml |
      | n | <%= project.name %>|
    Then the step should succeed
    And I wait for the "hello-statefulset" statefulset to appear
    And I wait for the "foo" service to appear
    Given the "www-hello-statefulset-0" PVC becomes :bound
    Given the "www-hello-statefulset-1" PVC becomes :bound
    Given the pod named "hello-statefulset-0" becomes ready
    Given the pod named "hello-statefulset-1" becomes ready
    Given I run the :delete client command with:
      | object_type       | statefulset       |
      | object_name_or_id | hello-statefulset |
      | cascade           | false             |
    Then the step should succeed
    Given I wait for the resource "statefulset" named "hello-statefulset" to disappear
    Given 10 seconds have passed
    Then I check that the "hello-statefulset-0" pod exists in the project
    Then I check that the "hello-statefulset-1" pod exists in the project
    Then I check that the "foo" service exists in the project
    And I check that the "www-hello-statefulset-0" persistentvolumeclaim exists in the project
    And I check that the "www-hello-statefulset-0" persistentvolumeclaim exists in the project

  # @author dma@redhat.com
  # @case_id OCP-12984
  Scenario: Update container image in StatefulSet
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/update-statefulset.yaml |
      | n | <%=project.name %>                                                                                     |
    Then the step should succeed
    Given the pod named "hello-statefulset-0" becomes ready
    Given the pod named "hello-statefulset-1" becomes ready
    When I run the :patch client command with:
      | resource      | statefulset       |
      | resource_name | hello-statefulset |
      | p             | [{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"docker.io/ocpqe/hello-pod:v2"}] |
      | type          | json              |
    And the step should succeed
    Given I ensure "hello-statefulset-0" pod is deleted
    Given the pod named "hello-statefulset-0" becomes ready
    When I run the :get client command with:
      | resource      | pod                 |
      | resource_name | hello-statefulset-0 |
      | template      | {{range $i, $c := .spec.containers}}{{$c.image}}{{end}} |
    Then the output should contain:
      | docker.io/ocpqe/hello-pod:v2 |
    Given I ensure "hello-statefulset-1" pod is deleted
    Given the pod named "hello-statefulset-1" becomes ready
    When I run the :get client command with:
      | resource      | pod                 |
      | resource_name | hello-statefulset-1 |
      | template      | {{range $i, $c := .spec.containers}}{{$c.image}}{{end}} |
    Then the output should contain:
      | docker.io/ocpqe/hello-pod:v2 |

  # @author dma@redhat.com
  # @case_id OCP-12975
  Scenario: Pods in a StatefulSet is using stable network identities
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/hello-statefulset.yaml |
      | n | <%=project.name %>                                                                                    |
    Then the step should succeed
    Given the pod named "hello-statefulset-0" becomes ready
    Given the pod named "hello-statefulset-1" becomes ready
    When I run the :exec client command with:
      | pod              | hello-statefulset-0 |
      | exec_command     | hostname            |
    Then the output should contain:
      | hello-statefulset-0 |
    When I run the :exec client command with:
      | pod              | hello-statefulset-1 |
      | exec_command     | hostname            |
    Then the output should contain:
      | hello-statefulset-1 |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/busybox-pod.yaml |
    Then the step should succeed
    Given the pod named "my-pod" becomes ready
    When I run the :exec client command with:
      | pod              | my-pod                       |
      | oc_opts_end      |                              |
      | exec_command     | ping                         |
      | exec_command_arg | -c                           |
      | exec_command_arg | 1                            |
      | exec_command_arg | hello-statefulset-0.foo      |
    And the output should match:
      | PING hello-statefulset-0.foo \((\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\) |
    And the output should not contain:
      | ping: bad address 'hello-statefulset-0.foo' |
    When I run the :exec client command with:
      | pod              | my-pod                       |
      | oc_opts_end      |                              |
      | exec_command     | ping                         |
      | exec_command_arg | -c                           |
      | exec_command_arg | 1                            |
      | exec_command_arg | hello-statefulset-1.foo      |
    And the output should match:
      | PING hello-statefulset-1.foo \((\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\) |
    And the output should not contain:
      | ping: bad address 'hello-statefulset-1.foo' |
    Given I ensure "hello-statefulset-0" pod is deleted
    Given I ensure "hello-statefulset-1" pod is deleted
    Given the pod named "hello-statefulset-0" becomes ready
    When I run the :exec client command with:
      | pod              | hello-statefulset-0 |
      | exec_command     | hostname            |
    Then the output should contain:
      | hello-statefulset-0 |
    When I run the :exec client command with:
      | pod              | my-pod                       |
      | oc_opts_end      |                              |
      | exec_command     | ping                         |
      | exec_command_arg | -c                           |
      | exec_command_arg | 1                            |
      | exec_command_arg | hello-statefulset-0.foo      |
    And the output should match:
      | PING hello-statefulset-0.foo \((\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\) |
    And the output should not contain:
      | ping: bad address 'hello-statefulset-0.foo' |
    Given the pod named "hello-statefulset-1" becomes ready
    When I run the :exec client command with:
      | pod              | hello-statefulset-1 |
      | exec_command     | hostname            |
    Then the output should contain:
      | hello-statefulset-1 |
    When I run the :exec client command with:
      | pod              | my-pod                       |
      | oc_opts_end      |                              |
      | exec_command     | ping                         |
      | exec_command_arg | -c                           |
      | exec_command_arg | 1                            |
      | exec_command_arg | hello-statefulset-1.foo      |
    And the output should match:
      | PING hello-statefulset-1.foo \((\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\) |
    And the output should not contain:
      | ping: bad address 'hello-statefulset-1.foo' |
