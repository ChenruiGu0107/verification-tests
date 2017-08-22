Feature: nodeAffinity
  # @author wjiang@redhat.com
  # @case_id OCP-14581
  Scenario: node affinity preferred invalid weight values
    # Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-preferred-weight-fraction.yaml |
    Then the step should fail
    And the output should match:
      | fractional integer |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-preferred-weight-faction |
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-preferred-weight-0.yaml |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid value.*0.*must be in the range 1-100 |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | node-affinity-preferred-weight-0 |
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-preferred-weight-101.yaml |
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
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-value-lt.yaml |
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
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-value-empty.yaml |
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
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-key-empty.yaml |
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
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-doesnotexist.yaml |
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
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-exists.yaml |
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
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-operator-equals.yaml |
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/node-affinity/node-affinity-required-case14478.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod                              |
      | name     | node-affinity-required-case14478 |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | MatchNodeSelector     |

  # @author wmeng@redhat.com
  # @case_id OCP-14480
  Scenario: pod will not be scheduled if node anti-affinity not match
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/node-affinity/node-anti-affinity-required-case14480.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod                                   |
      | name     | node-anti-affinity-required-case14480 |
    Then the step should succeed
    And the output should match:
      | PodScheduled\\s+False |
      | FailedScheduling      |
      | MatchNodeSelector     |

  # @author wmeng@redhat.com
  # @case_id OCP-14479
  @admin
  Scenario: pod will be scheduled to the node which matches node affinity
    Given I have a project
    And I store the schedulable nodes in the :nodes clipboard
    And label "key14479=value14479" is added to the "<%= cb.nodes[0].name %>" node
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/node-affinity/node-affinity-required-case14479.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-required-case14479" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14484
  @admin
  Scenario: pod will be scheduled to the node which matches node anti-affinity
    Given environment has at least 2 schedulable nodes
    Given I have a project
    And I store the schedulable nodes in the :nodes clipboard
    And label "key14484=value14484" is added to the "<%= cb.nodes[0].name %>" node
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/node-affinity/node-anti-affinity-required-case14484.yaml |
    Then the step should succeed
    Given the pod named "node-anti-affinity-required-case14484" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name != cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14488
  @admin
  Scenario: pod will still run on the node if labels on the node change and affinity rules no longer met - IgnoredDuringExecution
    Given I have a project
    And I store the schedulable nodes in the :nodes clipboard
    And label "key14488=value14488" is added to the "<%= cb.nodes[0].name %>" node
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/node-affinity/node-affinity-required-case14488.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-required-case14488" status becomes :running within 60 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name
    When I run the :label admin command with:
      | resource  | node                    |
      | name      | <%= cb.nodes[0].name %> |
      | key_val   | key14488=valuenot14488  |
      | overwrite | true                    |
    Then the step should succeed
    Given 30 seconds have passed
    Given the pod named "node-affinity-required-case14488" status becomes :running within 1 seconds
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author wmeng@redhat.com
  # @case_id OCP-14509
  Scenario: if no preferred nodes are available non-preferred nodes will be chosen
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/node-affinity/node-affinity-preferred-case14509.yaml |
    Then the step should succeed
    Given the pod named "node-affinity-preferred-case14509" status becomes :running within 60 seconds
