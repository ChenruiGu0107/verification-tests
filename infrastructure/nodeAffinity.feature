Feature: nodeAffinity
  # @author wjiang@redhat.com
  # @case_id OCP-14581
  Scenario: node affinity preferred invalid weight values
    # Given the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "pods/nodeAffinity/pod-node-affinity-preferred-weight-fraction.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-preferred-weight-fraction.yaml |
    Then the step should fail
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-preferred-weight-faction |
    Given I obtain test data file "pods/nodeAffinity/pod-node-affinity-preferred-weight-0.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-preferred-weight-0.yaml |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid value.*0.*must be in the range 1-100 |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-preferred-weight-0 |
    Given I obtain test data file "pods/nodeAffinity/pod-node-affinity-preferred-weight-101.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-preferred-weight-101.yaml |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid value.*101.*must be in the range 1-100 |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-preferred-weight-101 |

  # @author wjiang@redhat.com
  # @case_id OCP-14580
  Scenario: node affinity invalid value - value must be single value
    # Given the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "pods/nodeAffinity/pod-node-affinity-invalid-value-lt.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-invalid-value-lt.yaml |
    Then the step should fail
    And the output should match:
      | [Rr]equired value.*must be specified single value when `operator` is 'Lt' or 'Gt' |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-invalid-value-lt |

  # @author wjiang@redhat.com
  # @case_id OCP-14579
  Scenario: node affinity invalid value - value required
    # Given the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "pods/nodeAffinity/pod-node-affinity-invalid-value-empty.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-invalid-value-empty.yaml |
    Then the step should fail
    And the output should match:
      | [Rr]equired value.*must be specified when `operator` is 'In' or 'NotIn' |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-invalid-value-empty |

  # @author wjiang@redhat.com
  # @case_id OCP-14578
  Scenario: node affinity invalid value - key name must be non-empty
    # Given the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "pods/nodeAffinity/pod-node-affinity-invalid-key-empty.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-invalid-key-empty.yaml |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid value.*name part must be non-empty |
      | [Ii]nvalid value.*name part must consist of alphanumeric characters, '-', '_' or '.', and must start and end with an alphanumeric character |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-invalid-key-empty |

  # @author wjiang@redhat.com
  # @case_id OCP-14538
  Scenario: node affinity values forbidden when operator is DoesNotExist
    # Given the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "pods/nodeAffinity/pod-node-affinity-invalid-doesnotexist.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-invalid-doesnotexist.yaml |
    Then the step should fail
    And the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-invalid-doesnotexist |

  # @author wjiang@redhat.com
  # @case_id OCP-14536
  Scenario: node affinity values forbidden when operator is Exists
    # Given the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "pods/nodeAffinity/pod-node-affinity-invalid-exists.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-invalid-exists.yaml |
    Then the step should fail
    And the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-invalid-exists |

  # @author wjiang@redhat.com
  # @case_id OCP-14533
  Scenario: node affinity invalid operator Equals
    # Given the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "pods/nodeAffinity/pod-node-affinity-invalid-operator-equals.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-invalid-operator-equals.yaml |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid value.*"Equals": not a valid selector operator |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-invalid-operator-equals |

  # @author wmeng@redhat.com
  # @case_id OCP-14478
  Scenario: pod will not be scheduled if node affinity not match
    Given I have a project
    Given I obtain test data file "scheduler/node-affinity/node-affinity-required-case14478.yaml"
    When I run the :create client command with:
      | f | node-affinity-required-case14478.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod                              |
      | name     | node-affinity-required-case14478 |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | [Mm]atch\s?[Nn]ode\s?[Ss]elector  |

  # @author wmeng@redhat.com
  # @case_id OCP-14480
  Scenario: pod will not be scheduled if node anti-affinity not match
    Given I have a project
    Given I obtain test data file "scheduler/node-affinity/node-anti-affinity-required-case14480.yaml"
    When I run the :create client command with:
      | f | node-anti-affinity-required-case14480.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod                                   |
      | name     | node-anti-affinity-required-case14480 |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | [Mm]atch\s?[Nn]ode\s?[Ss]elector     |

  # @author wmeng@redhat.com
  # @case_id OCP-14479
  @admin
  Scenario: pod will be scheduled to the node which matches node affinity
    Given I have a project
    Given I store the schedulable workers in the :nodes clipboard
    And label "key14479=value14479" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/node-affinity-required-case14479.yaml"
    When I run the :create client command with:
      | f | node-affinity-required-case14479.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-required-case14479" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14484
  @admin
  Scenario: pod will be scheduled to the node which matches node anti-affinity
    Given environment has at least 2 schedulable nodes
    Given I have a project
    Given I store the schedulable workers in the :nodes clipboard
    And label "key14484=value14484" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/node-anti-affinity-required-case14484.yaml"
    When I run the :create client command with:
      | f | node-anti-affinity-required-case14484.yaml |
    Then the step should succeed
    Given the pod named "node-anti-affinity-required-case14484" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name != cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14488
  @admin
  Scenario: pod will still run on the node if labels on the node change and affinity rules no longer met - IgnoredDuringExecution
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And label "key14488=value14488" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/node-affinity-required-case14488.yaml"
    When I run the :create client command with:
      | f | node-affinity-required-case14488.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-required-case14488" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name
    When I run the :label admin command with:
      | resource  | node                    |
      | name      | <%= cb.nodes[0].name %> |
      | key_val   | key14488=valuenot14488  |
      | overwrite | true                    |
    Then the step should succeed
    And the pod named "node-affinity-required-case14488" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14509
  Scenario: if no preferred nodes are available non-preferred nodes will be chosen
    Given I have a project
    Given I obtain test data file "scheduler/node-affinity/node-affinity-preferred-case14509.yaml"
    When I run the :create client command with:
      | f | node-affinity-preferred-case14509.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-preferred-case14509" status becomes :running

  # @author wmeng@redhat.com
  # @case_id OCP-14556
  @admin
  Scenario: pod will not be scheduled if node affinity or node selector is not satisfied - node affinity
    Given I have a project
    Given I store the schedulable workers in the :nodes clipboard
    And label "case14556=case14556" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/pod-node-affinity-selector-case14556.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-selector-case14556.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod                              |
      | name     | node-affinity-selector-case14556 |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | [Mm]atch\s?[Nn]ode\s?[Ss]elector      |
    """

  # @author wmeng@redhat.com
  # @case_id OCP-14557
  @admin
  Scenario: pod will not be scheduled if node affinity or node selector is not satisfied - node selector
    Given I have a project
    Given I store the schedulable workers in the :nodes clipboard
    And label "zone14557=case14557" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/pod-node-affinity-selector-case14557.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-selector-case14557.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod                              |
      | name     | node-affinity-selector-case14557 |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | [Mm]atch\s?[Nn]ode\s?[Ss]elector    |
    """

  # @author wmeng@redhat.com
  # @case_id OCP-14576
  @admin
  Scenario: pod can be scheduled onto a node only if all matchExpressions can be satisfied
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And label "key14576=value14576" is added to the "<%= cb.nodes[0].name %>" node
    And label "company14576=redhat" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/pod-multiple-match-expressions-case14576.yaml"
    When I run the :create client command with:
      | f | pod-multiple-match-expressions-case14576.yaml |
    Then the step should succeed
    Given the pod named "multiple-match-expressions-case14576" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14577
  @admin
  Scenario: pod  will not be scheduled if not all matchExpressions can be satisfied
    Given I have a project
    Given I store the schedulable workers in the :nodes clipboard
    And label "key14577=value14577" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/pod-multiple-match-expressions-case14577.yaml"
    When I run the :create client command with:
      | f | pod-multiple-match-expressions-case14577.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod                                  |
      | name     | multiple-match-expressions-case14577 |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | [Mm]atch\s?[Nn]ode\s?[Ss]elector     |
    """

  # @author wmeng@redhat.com
  # @case_id OCP-14566
  @admin
  Scenario: If you specify both nodeSelector and nodeAffinity, both must be satisfied for the pod to be scheduled onto a candidate node
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And label "case14566=case14566" is added to the "<%= cb.nodes[0].name %>" node
    And label "zone14566=case14566" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/pod-node-affinity-selector-case14566.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-selector-case14566.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-selector-case14566" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14568
  @admin
  Scenario: If you specify multiple nodeSelectorTerms associated with nodeAffinity types, then the pod can be scheduled onto a node if one of the nodeSelectorTerms is satisfied
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And label "case14568c=case14568" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/pod-node-affinity-selector-terms-case14568.yaml"
    When I run the :create client command with:
      | f | pod-node-affinity-selector-terms-case14568.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-selector-terms-case14568" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14520
  @admin
  Scenario: pod will be scheduled to the node which matches node affinity - Exists
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And label "case14520=anyvalue" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/node-affinity-required-exists-case14520.yaml"
    When I run the :create client command with:
      | f | node-affinity-required-exists-case14520.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-required-exists-case14520" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14521
  @admin
  Scenario: pod will be scheduled to the node which matches node anti-affinity - DoesNotExist
    Given environment has at least 2 schedulable nodes
    And I have a project
    Given I store the schedulable workers in the :nodes clipboard
    And label "case14521=anyvalue" is added to the "<%= cb.nodes[0].name %>" node
    Given I obtain test data file "scheduler/node-affinity/node-anti-affinity-required-exists-case14521.yaml"
    When I run the :create client command with:
      | f | node-anti-affinity-required-exists-case14521.yaml |
    Then the step should succeed
    Given the pod named "node-anti-affinity-required-exists-case14521" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name != cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14522
  @admin
  Scenario: pod will be scheduled to the node which matches node affinity - Gt
    Given environment has at least 2 schedulable nodes
    And I have a project
    Given I store the schedulable workers in the :nodes clipboard
    And label "key14522=4" is added to the "<%= cb.nodes[0].name %>" node
    And label "key14522=6" is added to the "<%= cb.nodes[1].name %>" node
    Given I obtain test data file "scheduler/node-affinity/node-affinity-gt4-required-case14522.yaml"
    When I run the :create client command with:
      | f | node-affinity-gt4-required-case14522.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-gt4-required-case14522" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[1].name

  # @author wmeng@redhat.com
  # @case_id OCP-14525
  @admin
  Scenario: pod will be scheduled to the node which matches node affinity - Lt
    Given environment has at least 2 schedulable nodes
    And I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And label "key14525=6" is added to the "<%= cb.nodes[0].name %>" node
    And label "key14525=4" is added to the "<%= cb.nodes[1].name %>" node
    Given I obtain test data file "scheduler/node-affinity/node-affinity-lt6-required-case14525.yaml"
    When I run the :create client command with:
      | f | node-affinity-lt6-required-case14525.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-lt6-required-case14525" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[1].name

  # @author yinzhou@redhat.com
  @admin
  @destructive
  Scenario Outline: pod prefers to be scheduled to the nodes which matches affinity rules clone for 4.x
    Given environment has at least 2 schedulable nodes
    Given I store the schedulable workers in the :nodes clipboard
    And label "<label>" is added to the "<%= cb.nodes[0].name %>" node
    Then the step should succeed
    Given I have a project
    Given I obtain test data file "scheduler/node-affinity/<pod_file_name>.yaml"
    And I run the :create client command with:
      | f | <pod_file_name>.yaml |
    Then the step should succeed
    Given the pod named "<pod_file_name>" status becomes :running within 300 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name
    Examples:
      | label                         | pod_file_name                 |
      | beta.kubernetes.io/arch=intel | node-anti-affinity-preferred  | # @case_id OCP-26287
      | zone=us                       | node-affinity-preferred-us    | # @case_id OCP-26286
