Feature: taint toleration related scenarios
  # @author wmeng@redhat.com
  # @case_id OCP-13532
  Scenario: [Taint Toleration] pod with toleration can be scheduled as normal pod
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/taint-toleration/pod-toleration.yaml |
    Then the step should succeed
    Given the pod named "toleration" becomes ready
    When I run the :describe client command with:
      | resource | pods       |
      | name     | toleration |
    Then the output should match:
      | Status:\\s+Running                                  |
      | Tolerations:\\s+dedicated=special-user:.*NoSchedule |

  # @author wmeng@redhat.com
  # @case_id OCP-13773
  Scenario: [Taint Toleration] 'operator' only support "Equal", "Exists"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/taint-toleration/pod-toleration-fail-operator.yaml |
    Then the step should fail
    And the output should match:
      | The Pod "toleration-fail-operator" is invalid |
      | Unsupported value: "Bigger"                   |
      | supported values:\s+"?Equal"?,\s+"?Exists"?   |
    When I run the :get client command with:
      | resource      | pod                      |
      | resource_name | toleration-fail-operator |
    Then the step should fail

  # @author wmeng@redhat.com
  # @case_id OCP-13774
  Scenario: [Taint Toleration] Invalid value effect "PreferNoSchedule" when 'tolerationSeconds' is set
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/taint-toleration/pod-toleration-fail-second-prefer.yaml |
    Then the step should fail
    And the output should contain:
      | The Pod "toleration-fail-second-prefer" is invalid         |
      | Invalid value: "PreferNoSchedule"                          |
      | effect must be 'NoExecute' when `tolerationSeconds` is set |
    When I run the :get client command with:
      | resource      | pod                           |
      | resource_name | toleration-fail-second-prefer |
    Then the step should fail

  # @author wmeng@redhat.com
  # @case_id OCP-13775
  Scenario: [Taint Toleration] Invalid value effect "NoSchedule" when 'tolerationSeconds' is set
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/taint-toleration/pod-toleration-fail-second-no.yaml |
    Then the step should fail
    And the output should contain:
      | The Pod "toleration-fail-second-no" is invalid             |
      | Invalid value: "NoSchedule"                                |
      | effect must be 'NoExecute' when `tolerationSeconds` is set |
    When I run the :get client command with:
      | resource      | pod                       |
      | resource_name | toleration-fail-second-no |
    Then the step should fail

  # @author wmeng@redhat.com
  # @case_id OCP-13776
  Scenario: [Taint Toleration] effect supported values are NoSchedule, PreferNoSchedule, NoExecute, all others are unsupported
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/taint-toleration/pod-toleration-fail-effect.yaml |
    Then the step should fail
    And the output should match:
      | The Pod "toleration-fail-effect" is invalid               |
      | Unsupported value: "Run"                                  |
      | supported values: "?NoSchedule"?,\s+"?PreferNoSchedule"?,\s+"?NoExecute"? |
    When I run the :get client command with:
      | resource      | pod                    |
      | resource_name | toleration-fail-effect |
    Then the step should fail

  # @author chezhang@redhat.com
  # @case_id OCP-13537
  @admin
  @destructive
  Scenario: pods will be evicted from the node immediately if there's un-ignored taint
    Given I have a project
    Given I store the schedulable nodes in the :nodes clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/pod-pull-by-tag.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/toleration-noexecute.yaml |
    Then the step should succeed
    Given the pod named "pod-pull-by-tag" becomes ready
    Given the pod named "toleration-1" becomes ready
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | dedicated=special-user:NoExecute                |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    the project should be empty
    """

  # @author chezhang@redhat.com
  # @case_id OCP-13539
  @admin
  @destructive
  Scenario: pods that do tolerate the taint will never be evicted
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/toleration-noexecute.yaml |
    Then the step should succeed
    Given the pod named "toleration-1" becomes ready
    Given evaluation of `pod("toleration-1").node_name(user: user)` is stored in the :pod_node1 clipboard
    Given I store the schedulable nodes in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.pod_node1 %>   |
      | key_val   | key1=value1:NoExecute |
    Then the step should succeed
    Given 300 seconds have passed
    Given the pod named "toleration-1" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.pod_node1

  # @author chezhang@redhat.com
  # @case_id OCP-13541
  @admin
  @destructive
  Scenario: pods will not schedule to node if there's un-ignored NoExecute taint
    Given I have a project
    Given I store the schedulable nodes in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | key2=value2:NoExecute                           |
    Then the step should succeed
    When I run the :describe admin command with:
      | resource | node                    |
      | name     | <%= cb.nodes[0].name %> |
    Then the step should succeed
    And the output should match:
      | Taints:\\s+key2=value2:NoExecute |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/toleration-noexecute.yaml |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource      | po           |
      | name          | toleration-1 |
    Then the output should match:
      | Status:\\s+Pending |
      | FailedScheduling   |
    """
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | key1=value1:NoExecute                           |
      | key_val   | key2-                                           |
    Then the step should succeed
    When I run the :describe admin command with:
      | resource | node                    |
      | name     | <%= cb.nodes[0].name %> |
    Then the step should succeed
    And the output should match:
      | Taints:\\s+key1=value1:NoExecute |
    Given the pod named "toleration-1" becomes ready

  # @author chezhang@redhat.com
  # @case_id OCP-12811
  @admin
  @destructive
  Scenario: Start kubelet with taint
    Given I have a project
    Given I select a random node's host
    When I run the :delete admin command with:
      | object_type       | node             |
      | object_name_or_id | <%= node.name %> |
    Then the step should succeed
    Given I register clean-up steps:
    """
    When I run the :delete admin command with:
      | object_type       | node             |
      | object_name_or_id | <%= node.name %> |
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should succeed
    """
    Given node config is merged with the following hash:
    """
    kubeletArguments:
      register-with-taints:
      - "node.alpha.kubernetes.io/ismaster=:NoSchedule"
    """
    When I try to restart the node service on node
    When I run the :describe admin command with:
      | resource | node             |
      | name     | <%= node.name %> |
    Then the step should succeed
    And the output should match:
      | Taints:\\s+node.alpha.kubernetes.io/ismaster:NoSchedule |
    Given node config is merged with the following hash:
    """
    kubeletArguments:
      register-with-taints:
      - "node.alpha.kubernetes.io/ismaster=no:invalid"
    """
    And I try to restart the node service on node
    Then the step should fail
    Given I use the "<%= node.name %>" node
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep -i "Invalid.*node.alpha.kubernetes.io/ismaster=no:invalid.*" |
    Then the step should succeed

  # @author chezhang@redhat.com
  # @case_id OCP-13647
  @admin
  @destructive
  Scenario: Taint Toleration dedicated nodes
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable nodes in the :nodes clipboard
    And label "vip=vip1" is added to the "<%= cb.nodes[0].name %>" node
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %>           |
      | key_val   | dedicated=special-user:NoSchedule |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-dedicated-nodes.yaml |
    Then the step should succeed
    Given the pod named "dedicated-nodes" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[0].name

  # @author chezhang@redhat.com
  # @case_id OCP-13533
  @admin
  @destructive
  Scenario: Taint Toleration pod with 2 tolerations can be scheduled to matched tainted node
    Given I have a project
    Given I store the schedulable nodes in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | dedicated=special-user:NoSchedule               |
      | key_val   | color=red:NoSchedule                            |
      | key_val   | size=large:NoSchedule                           |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %> |
      | key_val   | size-                   |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-toleration.yaml |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource      | po             |
      | name          | pod-toleration |
    Then the output should match:
      | Status:\\s+Pending |
      | FailedScheduling   |
    """
    Given I ensure "pod-toleration" pod is deleted
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-2tolerations.yaml |
    Then the step should succeed
    Given the pod named "pod-2tolerations" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[0].name

  # @author chezhang@redhat.com
  # @case_id OCP-13531
  @admin
  @destructive
  Scenario: Taint Toleration pod with toleration can be scheduled to taint node
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable nodes in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | dedicated=special-user:NoSchedule               |
      | key_val   | size=large:NoSchedule                           |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %> |
      | key_val   | size-                   |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-no-toleration.yaml |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource      | po         |
      | name          | hello-pod1 |
    Then the output should match:
      | Status:\\s+Pending |
      | FailedScheduling   |
    """
    Given I ensure "hello-pod1" pod is deleted
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-toleration1.yaml |
    Then the step should succeed
    Given the pod named "pod-toleration" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[0].name

  # @author chezhang@redhat.com
  # @case_id OCP-13771
  @admin
  @destructive
  Scenario: Taint Toleration pod with wildcard toleration can be scheduled to taint node
    Given I have a project
    Given I store the schedulable workers in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | dedicated=special-user:NoSchedule               |
      | key_val   | size=large:NoSchedule                           |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %> |
      | key_val   | size-                   |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-no-toleration1.yaml |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource      | po         |
      | name          | hello-pod1 |
    Then the output should match:
      | Status:\\s+Pending |
      | FailedScheduling   |
    """
    Given I ensure "hello-pod1" pod is deleted
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-wildcard-toleration.yaml |
    Then the step should succeed
    Given the pod named "wildcard-toleration" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[0].name

  # @author chezhang@redhat.com
  # @case_id OCP-13536
  @admin
  @destructive
  Scenario: Taint Toleration pods with toleration should be scheduled to corresponding node (NoSchedule and PreferNoSchedule)
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable nodes in the :nodes clipboard
    Given environment has at least 2 schedulable nodes
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes[0..-1].map(&:name).join(" ") %>    |
      | key_val   | additional=true:NoSchedule |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %>           |
      | key_val   | dedicated=special-user:NoSchedule |
      | key_val   | additional-                       |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-toleration-dedicated.yaml |
    Then the step should succeed
    Given the pod named "pod-toleration-dedicated" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[0].name
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[1].name %>    |
      | key_val   | color=red:PreferNoSchedule |
      | key_val   | additional-                |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-toleration-red-prefer.yaml |
    Then the step should succeed
    Given the pod named "pod-toleration-red-prefer" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[1].name

  # @author chezhang@redhat.com
  # @case_id OCP-13534
  @admin
  @destructive
  Scenario: Taint Toleration pods with toleration should be scheduled to corresponding node (NoSchedule)
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable nodes in the :nodes clipboard
    Given environment has at least 2 schedulable nodes
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes[0..-1].map(&:name).join(" ") %> |
      | key_val   | additional=true:NoSchedule    |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %>           |
      | key_val   | dedicated=special-user:NoSchedule |
      | key_val   | additional-                       |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-toleration-dedicated.yaml |
    Then the step should succeed
    Given the pod named "pod-toleration-dedicated" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[0].name
    When I run the :oadm_taint_nodes admin command with:
      | node_name |  <%= cb.nodes[1].name%> |
      | key_val   | color=red:NoSchedule    |
      | key_val   | additional-             |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-toleration-red.yaml |
    Then the step should succeed
    Given the pod named "pod-toleration-red" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[1].name

  # @author chezhang@redhat.com
  # @case_id OCP-13535
  @admin
  @destructive
  Scenario: Taint Toleration pods with toleration should be scheduled to corresponding node (PreferNoSchedule)
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable nodes in the :nodes clipboard
    Given environment has at least 2 schedulable nodes
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes[0..-1].map(&:name).join(" ") %>                 |
      | key_val   | additional=true:NoSchedule |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %>                 |
      | key_val   | dedicated=special-user:PreferNoSchedule |
      | key_val   | additional-                             |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-toleration-dedicated-prefer.yaml |
    Then the step should succeed
    Given the pod named "pod-toleration-dedicated-prefer" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[0].name
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[1].name %>    |
      | key_val   | color=red:PreferNoSchedule |
      | key_val   | additional-                |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-toleration-red-prefer.yaml |
    Then the step should succeed
    Given the pod named "pod-toleration-red-prefer" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[1].name

  # @author wmeng@redhat.com
  # @case_id OCP-13660
  Scenario: Taint Toleration - value must be empty when 'operator' is 'Exists'
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/taint-toleration/pod-with-toleration-fail.yaml |
    Then the step should fail
    And the output should contain:
      | The Pod "pod-toleration-fail" is invalid        |
      | value must be empty when `operator` is 'Exists' |
    When I run the :get client command with:
      | resource      | pod                 |
      | resource_name | pod-toleration-fail |
    Then the step should fail

  # @author wmeng@redhat.com
  # @case_id OCP-13772
  Scenario: Taint Toleration - key must be provided when 'operator' is 'Equal'
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/taint-toleration/pod-with-toleration-fail-no-key.yaml |
    Then the step should fail
    And the output should contain:
      | The Pod "pod-toleration-fail-no-key" is invalid |
      | operator must be Exists when `key` is empty     |
    When I run the :get client command with:
      | resource      | pod                        |
      | resource_name | pod-toleration-fail-no-key |
    Then the step should fail

  # @author chezhang@redhat.com
  # @case_id OCP-13538
  @admin
  @destructive
  Scenario: pods will be bound to the node for tolerationSeconds even there's matched taint
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/tolerationSeconds.yaml |
    Then the step should succeed
    Given the pod named "tolerationseconds-1" becomes ready
    Given evaluation of `pod("tolerationseconds-1").node_name(user: user)` is stored in the :pod_node1 clipboard
    Given I store the schedulable nodes in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.pod_node1 %>   |
      | key_val   | key1=value1:NoExecute |
    Then the step should succeed
    When I run the :describe admin command with:
      | resource | node                |
      | name     | <%= cb.pod_node1 %> |
    Then the step should succeed
    And the output should match:
      | Taints:\\s+key1=value1:NoExecute |
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.pod_node1 %> |
      | key_val   | key1:NoExecute-     |
    Then the step should succeed
    When I run the :describe admin command with:
      | resource | node                |
      | name     | <%= cb.pod_node1 %> |
    Then the step should succeed
    And the output should match:
      | Taints:\\s+<none> |
    Given 120 seconds have passed
    Given the pod named "tolerationseconds-1" becomes ready
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.pod_node1 %>   |
      | key_val   | key1=value1:NoExecute |
    Then the step should succeed
    Given 100 seconds have passed
    Given the pod named "tolerationseconds-1" becomes ready
    Given 20 seconds have passed
    And the project should be empty

  # @author xiuli@redhat.com
  # @case_id OCP-13543
  @admin
  @destructive
  Scenario: DaemonSet pods are created with defaultToleration but no tolerationSeconds
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        DefaultTolerationSeconds:
          configuration:
            kind: DefaultAdmissionConfig
            apiVersion: v1
            disable: false
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/daemon/daemonset.yaml |
      | n | <%= project.name %>                                                                      |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pod  |
      | o        | yaml |
    Then the step should succeed
    And the output should not contain:
      | tolerationSeconds |
    """

  # @author minmli@redhat.com
  # @case_id OCP-20046
  @admin
  @destructive
  Scenario: default 'operator' is 'Equal' if not specified
    Given I have a project
    Given I run the :patch admin command with:
      | resource      | namespace                                                       |
      | resource_name | <%=project.name%>                                               |
      | p             | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I store the schedulable nodes in the :nodes clipboard
    #And label "vip=vip1" is added to the "<%= cb.nodes[0].name %>" node
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %>           |
      | key_val   | dedicated=special-user:NoSchedule |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/pod-with-toleration-empty-operator.yaml |
    Then the step should succeed
    Given the pod named "empty-operator-pod" becomes ready
    Then the expression should be true> pod.node_name(user: user) == cb.nodes[0].name

