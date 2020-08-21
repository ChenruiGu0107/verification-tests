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
