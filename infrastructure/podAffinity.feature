Feature: podAffinity
  # @author wjiang@redhat.com
  # @case_id OCP-14696
  Scenario: pod affinity - invalid operator
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/podAffinity/pod-pod-affinity-invalid-operator.yaml |
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
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/podAffinity/pod-pod-affinity-exists-value.yaml |
    Then the step should fail
    And the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' | 
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | pod-affinity-exists-value |
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/podAffinity/pod-pod-affinity-doesnotexist-value.yaml |
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
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/podAffinity/pod-pod-affinity-invalid-topologykey-empty.yaml |
    Then the step should fail
    And the output should match:
      | ([Rr]equired value.*can only be empty for PreferredDuringScheduling pod anti affinity\|[Rr]equired value:\s+can not be empty) |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | pod-affinity-invalid-topologykey-empty |

  # @author wmeng@redhat.com
  # @case_id OCP-14603
  Scenario: pod will not be scheduled if pod affinity not match
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/pod-pod-affinity-s1.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod             |
      | name     | pod-affinity-s1 |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | [Mm]atch\s?(Inter)?[Pp]od\s?[Aa]ffinity |

  # @author wmeng@redhat.com
  # @case_id OCP-14688
  Scenario: pod will be scheduled on the node which meets pod affinity - In
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/pod-s1.yaml |
    Then the step should succeed
    Given the pod named "security-s1" status becomes :running within 60 seconds
    And evaluation of `pod("security-s1").node_name` is stored in the :node clipboard
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/pod-pod-affinity-s1.yaml |
    Then the step should succeed
    Given the pod named "pod-affinity-s1" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.node

  # @author wmeng@redhat.com
  # @case_id OCP-14690
  Scenario: pod will be scheduled on the node which meets pod affinity - Exists
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/pod-s1.yaml |
    Then the step should succeed
    Given the pod named "security-s1" status becomes :running within 60 seconds
    And evaluation of `pod("security-s1").node_name` is stored in the :node clipboard
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/pod-pod-affinity-exists.yaml |
    Then the step should succeed
    Given the pod named "pod-affinity-exists" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.node

  # @author wmeng@redhat.com
  # @case_id OCP-14697
  Scenario: pod will be scheduled on the node which meets pod affinity specified namespace
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/pod-s1.yaml |
    Then the step should succeed
    Given the pod named "security-s1" status becomes :running within 60 seconds
    And evaluation of `pod("security-s1").node_name` is stored in the :node clipboard
    And I create a new project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/pod-pod-affinity-s1.yaml |
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
      | [Mm]atch\s?(Inter)?[Pp]od\s?[Aa]ffinity |
    """
    When I run oc create over ERB URL: <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/pod-pod-affinity-proj-case14697.yaml
    Then the step should succeed
    Given the pod named "pod-affinity-proj-case14697" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.node


  # @author wjiang@redhat.com
  # @case_id OCP-14698
  Scenario: pod with pod affinity will not be scheduled if not all matchExpressions are satisfied
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/pod-s1.yaml |
    Then the step should succeed
    Given the pod named "security-s1" status becomes :running within 300 seconds
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/pod-pod-affinity-multi-matchexpressions.yaml | 
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource  | pod                                 |
      | name      | pod-affinity-multi-matchexpressions |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | [Mm]atch\s?(Inter)?[Pp]od\s?[Aa]ffinity |
    """

  # @author wjiang@redhat.com
  @admin
  Scenario Outline: pod will be scheduled on the node which meets pod affinity
    Given environment has at least 2 schedulable nodes
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/<pod-affinity-dst-pod> |
    Then the step should succeed
    Given the pod named "<dst-pod-name>" status becomes :running within 300 seconds
    And evaluation of `pod("<dst-pod-name>").node_name` is stored in the :node clipboard
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/<pod-affinity-src-pod> |
    Then the step should succeed
    And the pod named "<src-pod-name>" status becomes :running within 300 seconds
    Then the expression should be true> pod.node_name <same_node>= cb.node
    Examples:
      | dst-pod-name  | pod-affinity-dst-pod  | src-pod-name              | pod-affinity-src-pod                | same_node |
      | security-s1   | pod-s1.yaml           | pod-affinity-notin-s2     | pod-pod-affinity-notin-s2.yaml      | =         | # @case_id OCP-14689
      | security-s1   | pod-s1.yaml           | pod-affinity-doesnotexist | pod-pod-affinity-doesnotexist.yaml  | !         | # @case_id OCP-14692
      # below examples not implemented yet, maybe will be available in v3.8
      | team4         | pod-pod-team4.yaml    | pod-affinity-lt-5         | pod-pod-affinity-lt-5.yaml          | =         | # @case_id OCP-14694
      | team4         | pod-pod-team4.yaml    | pod-affinity-gt-3         | pod-pod-affinity-gt-3.yaml          | =         | # @case_id OCP-14693

  # @author yinzhou@redhat.com
  @admin
  Scenario Outline: pod prefers to be scheduled to the nodes which matches affinity rules cases for 4.x
    Given environment has at least 2 schedulable nodes
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/<pod-affinity-dst-pod-file> |
    Then the step should succeed
    Given the pod named "<dst-pod-name>" status becomes :running within 300 seconds
    And evaluation of `pod("<dst-pod-name>").node_name` is stored in the :pod_node clipboard
    And I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/scheduler/pod-affinity/<pod-affinity-src-pod-file> |
    Then the step should succeed
    And the pod named "<src-pod-name>" status becomes :running within 300 seconds
    Then the expression should be true> pod.node_name <equality> cb.pod_node
    Examples:
      | dst-pod-name  | pod-affinity-dst-pod-file | src-pod-name                      | pod-affinity-src-pod-file                   | equality  |
      | security-s1   | pod-s1.yaml               | pod-affinity-in-s1-preferred      | pod-pod-affinity-in-s1-preferred.yaml       | ==        | # @case_id OCP-26285
      | security-s1   | pod-s1.yaml               | pod-anti-affinity-in-s1-preferred | pod-pod-anti-affinity-in-s1-preferred.yaml  | !=        | # @case_id OCP-25870
