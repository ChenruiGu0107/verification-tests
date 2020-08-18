Feature: emptyDir specific scenarios
  # @author qwang@redhat.com
  # @author weinliu@redhat.com
  # @case_id OCP-14350
  @admin
  Scenario: EmptyDir won't lead to memory exhaustion
    Given I have a project
    Given I obtain test data file "storage/emptydir/pod-emptydir.yaml"
    When I run the :create client command with:
      | filename  | pod-emptydir.yaml |
    Then the step should succeed
    Given I wait for the "pod-emptydir" pod to appear in the project
    And evaluation of `pod.node_name` is stored in the :pod_node clipboard
    And evaluation of `pod.uid` is stored in the :pod_uid clipboard

    When the pod named "pod-emptydir" status becomes :pending
    Then I wait for the steps to pass:
    """
    Given the expression should be true> pod.container(name: "c1").completed?[:success]
    """
    Given I use the "<%= cb.pod_node %>" node
    When I run commands on the host:
      | mount \| grep myvol |
    Then the step should succeed
    And the output should contain "myvol"
    When I run commands on the host:
      | ls -alh /var/lib/kubelet/pods/<%= cb.pod_uid %>/volumes/kubernetes.io~empty-dir/myvol |
    Then the output should contain:
      | 200M  |
      | zero  |
    Given I ensure "pod-emptydir" pod is deleted
    Given I obtain test data file "storage/emptydir/pod-emptydir-oom.yaml"
    When I run the :create client command with:
      | filename  | pod-emptydir-oom.yaml |
    Then the step should succeed

    Given I wait for the "pod-emptydir-oom" pod to appear in the project
    And evaluation of `pod.node_name` is stored in the :pod_node clipboard
    And evaluation of `pod.uid` is stored in the :pod_uid clipboard
    Then I wait for the steps to pass:
    """
    Given the expression should be true> pod.container(name: "c1").completed?[:matched_state] == "OOMKilled"
    """
    Given I use the "<%= cb.pod_node %>" node
    When I run commands on the host:
      | mount \| grep myvol |
    Then the step should succeed
    And the output should contain "myvol"
    When I run commands on the host:
      | ls -alh /var/lib/kubelet/pods/<%= cb.pod_uid %>/volumes/kubernetes.io~empty-dir/myvol \| grep zero \| awk '{print $5}' |
    And the output should match:
      | (1015M\|1013M\|1011M) |
