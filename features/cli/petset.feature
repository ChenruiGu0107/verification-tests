Feature: Petset Related Scenarios

  # @author cryan@redhat.com
  # @case_id 532404
  Scenario: Check network identity works well after create petset
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/mdshuai/testfile-openshift/master/petset/hello-petset.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | app=hello-pod |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/mdshuai/testfile-openshift/master/k8s/busybox.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=busybox0 |
    When I execute on the "hello-petset-0" pod:
      | sh | -c | 'hostname' |
    Then the step should succeed
    And the output should contain "hello-petset-0"
    When I execute on the "hello-petset-1" pod:
      | sh | -c | 'hostname' |
    Then the step should succeed
    And the output should contain "hello-petset-1"
    When I execute on the "busybox0" pod:
      | nslookup | hello-petset-0.foo |
    Then the step should succeed
    And the output should match:
      | Server:\s+\d+\.\d+\.\d+\.\d+          |
      | Address 1:\s+\d+\.\d+\.\d+\.\d+\s+ip- |
      | Name:\s+hello-petset-0.foo            |
      | Address 1:\s+\d+\.\d+\.\d+\.\d+\s+ip- |
    When I execute on the "busybox0" pod:
      | nslookup | hello-petset-1.foo |
    Then the step should succeed
    And the output should match:
      | Server:\s+\d+\.\d+\.\d+\.\d+          |
      | Address 1:\s+\d+\.\d+\.\d+\.\d+\s+ip- |
      | Name:\s+hello-petset-1.foo            |
      | Address 1:\s+\d+\.\d+\.\d+\.\d+\s+ip- |
    When I execute on the "busybox0" pod:
      | nslookup | foo.<%= project.name %>  |
    Then the step should succeed
    And the output should match:
      | Server:\s+\d+\.\d+\.\d+\.\d+          |
      | Address 1:\s+\d+\.\d+\.\d+\.\d+\s+ip- |
    When I run the :delete client command with:
      | object_type       | pod            |
      | object_name_or_id | hello-petset-1 |
    Then the step should succeed
    When I execute on the "busybox0" pod:
      | nslookup | foo.<%= project.name %>  |
    Then the step should succeed
    And the output should match:
      | Server:\s+\d+\.\d+\.\d+\.\d+          |
      | Address 1:\s+\d+\.\d+\.\d+\.\d+\s+ip- |

  # @author cryan@redhat.com
  # @case_id 532405
  Scenario: Deleting the Pet Set will not delete any pets
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/mdshuai/testfile-openshift/master/petset/hello-petset.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | app=hello-pod |
    When I run the :delete client command with:
      | object_type       | petset       |
      | object_name_or_id | hello-petset |
      | cascade           | true         |
    Then the step should succeed
    Given I get project pods
    Then the output should contain:
      | hello-petset-0 |
      | hello-petset-1 |
    And the output should contain 2 times:
      | Running |

  # @author cryan@redhat.com
  # @case_id 532408
  Scenario: The only updatable field on a PetSet is replicas
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/mdshuai/testfile-openshift/master/petset/hello-petset.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | app=hello-pod |
    When I run the :patch client command with:
      | resource      | petset                  |
      | resource_name | hello-petset            |
      | p             | {"spec":{"replicas":5}} |
    Then the step should succeed
    And 5 pods become ready with labels:
      | app=hello-pod |
    When I run the :patch client command with:
      | resource      | petset                              |
      | resource_name | hello-petset                        |
      | p             | {"spec":{"containers":[{"name":"hello-openshift","image":"aosqe/hello-openshift"}]}} |
    Then the step should fail
    And the output should contain "fields other than 'replicas' are forbidden"
