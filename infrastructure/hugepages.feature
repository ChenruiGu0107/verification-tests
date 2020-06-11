Feature: Hugepages related feature
  # @case_id OCP-15728
  # @author wjiang@redhat.com
  @destructive
  @admin
  Scenario: Hugepages support - Should got fail when pod request a invalid hugepagesize
    Given nodes have 10 2Mi hugepages configured
    And I have a project
    Given I obtain test data file "infrastructure/hugepage/pod_15728.yaml"
    When I run the :create client command with:
      | f | pod_15728.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given I run the :describe client command with:
      | resource | pod |
      | name | pod-15728 |
    Then the step should succeed
    And the output should match:
      | FailedScheduling.*Insufficient\s+hugepages-3Mi|
    """

  # @case_id OCP-15732
  # @author wjiang@redhat.com
  @destructive
  @admin
  Scenario: Hugepages support - hugepage should work well as a requested resource for pods
    Given nodes have 10 2Mi hugepages configured
    And I have a project
    Given I obtain test data file "infrastructure/hugepage/pod_15732.yaml"
    When I run the :create client command with:
      | f | pod_15732.yaml |
      | n | <%= project.name%> |
    Then the step should succeed
    Given the pod named "pod-15732" becomes ready
    # make sure hugepages can be used via shmget syscall
    When I execute on the pod:
      | /hugepage-shm | 20 |
    Then the step should succeed
    And the output should contain:
      | Done |
    # make sure hugepages can not overcommit via shmget syscall
    When I execute on the pod:
      | /hugepage-shm | 21 |
    Then the step should fail
    And the output should contain:
      | Cannot allocate memory |
    # make sure hugepages can be used via mmap syscall with MAP_HUGETLB flag
    When I execute on the pod:
      | /map_hugetlb | 20 |
    Then the step should succeed
    And the output should contain:
      | DONE |
    # make sure hugepages can not overcommit via mmap syscall with MAP_HUGETLB flag
    When I execute on the pod:
      | /map_hugetlb | 21 |
    Then the step should fail
    And the output should contain:
      | Cannot allocate memory |
    # make sure hugepages can be used via mmap syscall with MAP_SHARED flag
    When I execute on the pod:
      | /hugepage-mmap | 20 |
    Then the step should succeed
    And the output should contain:
      | DONE |
    # make sure hugepages can not overcommit via mmap syscall with MAP_SHALED flag
    When I execute on the pod:
      | /hugepage-mmap | 21 |
    Then the step should fail
    And the output should contain:
      | Cannot allocate memory |


  # @case_id OCP-15740
  # @author wjiang@redhat.com
  @destructive
  @admin
  Scenario: Hugepages support - Should fail when pod requests hugepage exceed allocatable resources
    Given nodes have 10 2Mi hugepages configured
    And I have a project
    Given I obtain test data file "infrastructure/hugepage/pod_15740.yaml"
    When I run the :create client command with:
      | f | pod_15740.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given I run the :describe client command with:
      | resource | pod |
      | name | pod-15740 |
    Then the step should succeed
    And the output should match:
      | FailedScheduling.*Insufficient\s+hugepages-2Mi|
    """

  # @case_id OCP-15748
  # @author wjiang@redhat.com
  @admin
  @destructive
  Scenario: Hugepages support - Should fail when pod requests multiple hugepagesize
    Given nodes have 10 2Mi hugepages configured
    And I have a project
    Given I obtain test data file "infrastructure/hugepage/pod_15748.yaml"
    When I run the :create client command with:
      | f | pod_15748.yaml |
      | n | <%= project.name %> |
    Then the step should fail
    And the output should contain:
      | must use a single hugepage size in a pod spec |
