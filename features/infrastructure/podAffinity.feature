Feature: podAffinity
  # @author wjiang@redhat.com
  # @case_id OCP-14696
  Scenario: pod affinity - invalid operator
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-invalid-operator.yaml |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid value.*Equals.*not a valid selector operator |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | pod-affinity-invalid-operator |

  # @author wjiang@redhat.com
  # @case_id OCP-14691
  Scenario: pod affinity - value may not be specified when operator is Exists or DoesNotExist
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-exists-value.yaml |
    Then the step should fail
    And the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' | 
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | pod-affinity-exists-value |
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-doesnotexist-value.yaml |
    Then the step should fail
    And the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | pod-affinity-doesnetexist-value |

  # @author wjiang@redhat.com
  # @case_id OCP-14607
  Scenario: pod affinity topologykey cannot be empty
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-invalid-topologykey-empty.yaml |
    Then the step should fail
    And the output should match:
      | [Rr]equired value.*can only be empty for PreferredDuringScheduling pod anti affinity |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | pod-affinity-invalid-topologykey-empty |

  # @author wmeng@redhat.com
  # @case_id OCP-14603
  Scenario: pod will not be scheduled if pod affinity not match
    Given I have a project
    When I run the :get client command with:
      | resource | pods        |
      | l        | security=s1 |
    Then the step should succeed
    And the output should contain:
      | No resources found. |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod-affinity/pod-pod-affinity-s1.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod             |
      | name     | pod-affinity-s1 |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | MatchInterPodAffinity |

  # @author wmeng@redhat.com
  # @case_id OCP-14688
  Scenario: pod will be scheduled on the node which meets pod affinity - In
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod-affinity/pod-s1.yaml |
    Then the step should succeed
    Given the pod named "security-s1" status becomes :running within 60 seconds
    And evaluation of `pod("security-s1").node_name` is stored in the :node clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod-affinity/pod-pod-affinity-s1.yaml |
    Then the step should succeed
    Given the pod named "pod-affinity-s1" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.node

  # @author wmeng@redhat.com
  # @case_id OCP-14690
  Scenario: pod will be scheduled on the node which meets pod affinity - Exists
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod-affinity/pod-s1.yaml |
    Then the step should succeed
    Given the pod named "security-s1" status becomes :running within 60 seconds
    And evaluation of `pod("security-s1").node_name` is stored in the :node clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod-affinity/pod-pod-affinity-exists.yaml |
    Then the step should succeed
    Given the pod named "pod-affinity-exists" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.node

  # @author wmeng@redhat.com
  # @case_id OCP-14697
  Scenario: pod will be scheduled on the node which meets pod affinity specified namespace
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod-affinity/pod-s1.yaml |
    Then the step should succeed
    Given the pod named "security-s1" status becomes :running within 60 seconds
    And evaluation of `pod("security-s1").node_name` is stored in the :node clipboard
    And I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod-affinity/pod-pod-affinity-s1.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod             |
      | name     | pod-affinity-s1 |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | MatchInterPodAffinity |
    """
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod-affinity/pod-pod-affinity-proj-case14697.yaml
    Then the step should succeed
    Given the pod named "pod-affinity-proj-case14697" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.node
