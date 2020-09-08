Feature: podTopologySpreadConstraints

  # @author knarra@redhat.com
  # @case_id OCP-34017
  @admin
  @destructive
  Scenario: TopologySpreadConstraints do not work on cross namespaced pods
    Given the master version >= "4.6"
    Given I store the schedulable workers in the :nodes clipboard
    # Add labels to the nodes
    Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[2].name %>" node labels are restored after scenario
    And label "zone=zoneA" is added to the "<%= cb.nodes[0].name %>" node
    And label "node=node1" is added to the "<%= cb.nodes[0].name %>" node
    And label "zone=zoneA" is added to the "<%= cb.nodes[1].name %>" node
    And label "node=node2" is added to the "<%= cb.nodes[1].name %>" node
    And label "zone=zoneB" is added to the "<%= cb.nodes[2].name %>" node
    And label "node=node3" is added to the "<%= cb.nodes[2].name %>" node
    # Test runs here
    Given I have a project
    And I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp34017.yaml"
    When I run the :create client command with:
      | f | pod_ocp34017.yaml |
    Then the step should succeed
    And the pod named "pod-ocp34017-1" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[0].name
    When I run oc create over "pod_ocp34017.yaml" replacing paths:
      | ["metadata"]["name"]             | pod-ocp34017-2 |
      | ["spec"]["nodeSelector"]["node"] | node2          |
    Then the step should succeed
    And the pod named "pod-ocp34017-2" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[1].name
    # Validation
    Given I create a new project
    Given I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp34017_3.yaml"
    When I run the :create client command with:
      | f | pod_ocp34017_3.yaml |
    Then the step should succeed
    And the pod named "pod-ocp34017-3" status becomes :running
    And the expression should be true> pod.node_name != cb.nodes[2].name

  # @author knarra@redhat.com
  # @case_id OCP-34019
  @admin
  @destructive
  Scenario: Validate topologyspreadconstraints ignored the node without the label
    Given the master version >= "4.6"
    Given I store the schedulable workers in the :nodes clipboard
    # Add labels to the nodes
    Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[2].name %>" node labels are restored after scenario
    And label "zone=zoneA" is added to the "<%= cb.nodes[0].name %>" node
    And label "node=node1" is added to the "<%= cb.nodes[0].name %>" node
    And label "zone=zoneB" is added to the "<%= cb.nodes[1].name %>" node
    And label "node=node2" is added to the "<%= cb.nodes[1].name %>" node
    And label "zone=zoneC" is added to the "<%= cb.nodes[2].name %>" node
    # Test runs here
    Given I have a project
    Given I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp34019.yaml"
    When I run the :create client command with:
      | f | pod_ocp34019.yaml |
    Then the step should succeed
    And 2 pods become ready with labels:
      | app=ocp-34019 |
    When I run the :get client command with:
      | resource | pods |
      | o        | wide |
    Then the step should succeed
    And the output should not contain "<%= cb.nodes[2].name %>"
    # scale up the deployment and make sure that pods are not present on third node
    When I run the :scale client command with:
      | resource | deployment |
      | name     | ocp-34019  |
      | replicas | 5          |
    Then the step should succeed
    Given number of replicas of "ocp-34019" deployment becomes:
      | desired   | 5 |
      | current   | 5 |
      | updated   | 5 |
      | available | 5 |
    When I run the :get client command with:
      | resource | pods |
      | o        | wide |
     Then the step should succeed
     And the output should not contain "<%= cb.nodes[2].name %>"

  # @author knarra@redhat.com
  # @case_id OCP-33767
  @admin
  @destructive
  Scenario Outline: Validate TopologySpreadConstraints with nodeSelector/NodeAffinity
    Given the master version >= "4.6"
    Given I store the schedulable workers in the :nodes clipboard
    # Add labels to the nodes
    Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[2].name %>" node labels are restored after scenario
    And label "zone=zoneA" is added to the "<%= cb.nodes[0].name %>" node
    And label "node=node1" is added to the "<%= cb.nodes[0].name %>" node
    And label "zone=zoneA" is added to the "<%= cb.nodes[1].name %>" node
    And label "node=node2" is added to the "<%= cb.nodes[1].name %>" node
    And label "zone=zoneB" is added to the "<%= cb.nodes[2].name %>" node
    And label "node=node3" is added to the "<%= cb.nodes[2].name %>" node
    # Test runs here
    Given I have a project
    And I obtain test data file "scheduler/pod-topology-spread-constraints/<filename>"
    When I run the :create client command with:
      | f | <filename> |
    Then the step should succeed
    And the pod named "<pod1name>" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[0].name || cb.nodes[1].name
    Given evaluation of `pod.node_name` is stored in the :pod1node clipboard
    When I run oc create over "<filename>" replacing paths:
      | ["metadata"]["name"] | <pod2name> |
    Then the step should succeed
    And the pod named "<pod2name>" status becomes :running
    And the expression should be true> pod.node_name != cb.pod1node

    Examples:
      | filename          | pod1name     | pod2name       |
      | pod_ocp33767.yaml | pod-ocp33767 | pod-ocp33767-1 | # @case_id OCP-33767
      | pod-ocp34014.yaml | pod-ocp34014 | pod-ocp34014-1 | # @case_id OCP-34014

  # @author yinzhou@redhat.com
  # @case_id OCP-33824
  @admin
  @destructive
  Scenario: Validate TopologySpreadConstraint with podAffinity/podAntiAffinity
    Given the master version >= "4.6"
    Given I store the schedulable workers in the :nodes clipboard
    # Add labels to the nodes
    Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[2].name %>" node labels are restored after scenario
    And label "zone=zoneA" is added to the "<%= cb.nodes[0].name %>" node
    And label "node=node1" is added to the "<%= cb.nodes[0].name %>" node
    And label "zone=zoneB" is added to the "<%= cb.nodes[1].name %>" node
    And label "node=node2" is added to the "<%= cb.nodes[1].name %>" node
    And label "zone=zoneB" is added to the "<%= cb.nodes[2].name %>" node
    And label "node=node3" is added to the "<%= cb.nodes[2].name %>" node
    # Test runs here
    Given I have a project
    And I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp34017.yaml"
    When I run oc create over "pod_ocp34017.yaml" replacing paths:
      | ["metadata"]["name"] | pod-ocp33824-1 |
    Then the step should succeed
    And the pod named "pod-ocp33824-1" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[0].name
    When I run oc create over "pod_ocp34017.yaml" replacing paths:
      | ["metadata"]["name"]             | pod-ocp33824-2 |
      | ["metadata"]["labels"]           | security: S1   |
      | ["spec"]["nodeSelector"]["node"] | node3          |
    Then the step should succeed
    And the pod named "pod-ocp33824-2" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[2].name
    Given I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp33824.yaml"
    When I run the :create client command with:
      | f | pod_ocp33824.yaml |
    Then the step should succeed
    And the pod named "pod-ocp33824-3" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[1].name
    Given I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp33824-2.yaml"
    When I run the :create client command with:
      | f | pod_ocp33824-2.yaml |
    Then the step should succeed
    And the pod named "pod-ocp33824-4" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[2].name
    When I run oc create over "pod_ocp33824-2.yaml" replacing paths:
      | ["metadata"]["name"] | pod-ocp33824-5 |
    Then the step should succeed
    And the pod named "pod-ocp33824-5" status becomes :pending
    When I run the :describe client command with:
      | resource | pod            |
      | name     | pod-ocp33824-5 |
    Then the output should match:
      | FailedScheduling |

  # @author knarra@redhat.com
  # @case_id OCP-34087
  @admin
  @destructive
  Scenario: Validate sigle TopologySpreadConstraints with whenUnsatisfiable policy
    Given the master version >= "4.6"
    Given I store the schedulable workers in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    # Add labels to the nodes
    Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[2].name %>" node labels are restored after scenario
    And label "zone=zoneA" is added to the "<%= cb.nodes[0].name %>" node
    And label "node=node1" is added to the "<%= cb.nodes[0].name %>" node
    And label "zone=zoneA" is added to the "<%= cb.nodes[1].name %>" node
    And label "node=node2" is added to the "<%= cb.nodes[1].name %>" node
    And label "zone=zoneB" is added to the "<%= cb.nodes[2].name %>" node
    And label "node=node3" is added to the "<%= cb.nodes[2].name %>" node
    # Test runs here
    Given I have a project
    And I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp34017.yaml"
    When I run oc create over "pod_ocp34017.yaml" replacing paths:
      | ["metadata"]["name"] | pod-ocp34087-1 |
    Then the step should succeed
    And the pod named "pod-ocp34087-1" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[0].name
    When I run oc create over "pod_ocp34017.yaml" replacing paths:
      | ["metadata"]["name"]             | pod-ocp34087-2 |
      | ["spec"]["nodeSelector"]["node"] | node2          |
    Then the step should succeed
    And the pod named "pod-ocp34087-2" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[1].name
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[2].name %>           |
      | key_val   | dedicated=special-user:NoSchedule |
    Then the step should succeed
    Given I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp34087.yaml"
    When I run the :create client command with:
      | f | pod_ocp34087.yaml |
    Then the step should succeed
    And the pod named "pod-ocp34087-3" status becomes :pending
    #Validation
    When I run oc create over "pod_ocp34087.yaml" replacing paths:
      | ["metadata"]["name"]                                          | pod-ocp34087-4 |
      | ["spec"]["topologySpreadConstraints"][0]["whenUnsatisfiable"] | ScheduleAnyway |
    Then the step should succeed
    And the pod named "pod-ocp34087-4" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[0].name || cb.nodes[1].name

  # @author knarra@redhat.com
  # @case_id OCP-33836
  @admin
  @destructive
  Scenario: Validate Pod with only one TopologySpreadConstraint "topologyKey: node"
    Given the master version >= "4.6"
    Given I store the schedulable workers in the :nodes clipboard
    # Add labels to the nodes
    Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[2].name %>" node labels are restored after scenario
    And label "zone=zoneA" is added to the "<%= cb.nodes[0].name %>" node
    And label "node=node1" is added to the "<%= cb.nodes[0].name %>" node
    And label "zone=zoneA" is added to the "<%= cb.nodes[1].name %>" node
    And label "node=node2" is added to the "<%= cb.nodes[1].name %>" node
    And label "zone=zoneB" is added to the "<%= cb.nodes[2].name %>" node
    And label "node=node3" is added to the "<%= cb.nodes[2].name %>" node
    # Test runs here
    Given I have a project
    And I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp34017.yaml"
    When I run oc create over "pod_ocp34017.yaml" replacing paths:
      | ["metadata"]["name"] | pod-ocp33836 |
    Then the step should succeed
    And the pod named "pod-ocp33836" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[0].name
    When I run oc create over "pod_ocp34017.yaml" replacing paths:
      | ["metadata"]["name"]             | pod-ocp33836-1 |
      | ["spec"]["nodeSelector"]["node"] | node2          |
    Then the step should succeed
    And the pod named "pod-ocp33836-1" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[1].name
    Given I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp33836.yaml"
    When I run the :create client command with:
      | f | pod_ocp33836.yaml |
    Then the step should succeed
    And the pod named "pod-ocp33836-3" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[2].name

  # @author knarra@redhat.com
  # @case_id OCP-33845
  @admin
  @destructive
  Scenario: Validate with only one TopologySpreadConstraint "topologyKey: zone" and "maxSkew: 2"
    Given the master version >= "4.6"
    Given I store the schedulable workers in the :nodes clipboard
    # Add labels to the nodes
    Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[2].name %>" node labels are restored after scenario
    And label "zone=zoneA" is added to the "<%= cb.nodes[0].name %>" node
    And label "node=node1" is added to the "<%= cb.nodes[0].name %>" node
    And label "zone=zoneA" is added to the "<%= cb.nodes[1].name %>" node
    And label "node=node2" is added to the "<%= cb.nodes[1].name %>" node
    And label "zone=zoneB" is added to the "<%= cb.nodes[2].name %>" node
    And label "node=node3" is added to the "<%= cb.nodes[2].name %>" node
    # Test runs here
    Given I have a project
    And I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp34017.yaml"
    When I run oc create over "pod_ocp34017.yaml" replacing paths:
      | ["metadata"]["name"] | pod-ocp33845-1 |
    Then the step should succeed
    And the pod named "pod-ocp33845-1" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[0].name
    When I run oc create over "pod_ocp34017.yaml" replacing paths:
      | ["metadata"]["name"]             | pod-ocp33845-2 |
      | ["spec"]["nodeSelector"]["node"] | node2          |
    Then the step should succeed
    And the pod named "pod-ocp33845-2" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[1].name
    When I run oc create over "pod_ocp34017.yaml" replacing paths:
      | ["metadata"]["name"]             | pod-ocp33845-3 |
      | ["spec"]["nodeSelector"]["node"] | node3          |
    Then the step should succeed
    And the pod named "pod-ocp33845-3" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[2].name
    Given I obtain test data file "scheduler/pod-topology-spread-constraints/pod_ocp33845.yaml"
    When I run the :create client command with:
      | f | pod_ocp33845.yaml |
    Then the step should succeed
    And the pod named "pod-ocp33845-4" status becomes :running
    And the expression should be true> pod.node_name == cb.nodes[0].name || cb.nodes[1].name || cb.nodes[2].name
