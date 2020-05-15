Feature: cluster-capacity related features
  # @author wjiang@redhat.com
  # @case_id OCP-14796
  @admin
  @destructive
  Scenario: Cluster capacity image support: Cluster capacity can work well with taint and unschedulable
    Given environment has at least 3 schedulable nodes
    Given I have a project
    Given I have a cluster-capacity pod in my project
    Given I store the schedulable nodes in the :nodes clipboard
    Given evaluation of `cb.nodes.map {|n| n.max_pod_count_schedulable(cpu: convert_cpu("150m"), memory: convert_to_bytes("100Mi"))}` is stored in the :expected_number_per_node clipboard
    # following is for taint scenario
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %> |
      | key_val   | cc=cc:NoSchedule        |
    Then the step should succeed
    When I run the :exec client command with:
      | pod               | cluster-capacity              |
      | oc_opts_end       |                               |
      | exec_command      | cluster-capacity              |
      | exec_command_arg  | --kubeconfig                  |
      | exec_command_arg  | /admin-creds/admin.kubeconfig |
      | exec_command_arg  | --podspec                     |
      | exec_command_arg  | /test-pod/pod.yaml            |
    Then the step should succeed
    Then the expression should be true> @result[:response].to_i == cb.expected_number_per_node[1..-1].reduce(&:+)
    When I run the :exec client command with:
      | pod               | cluster-capacity              |
      | oc_opts_end       |                               |
      | exec_command      | cluster-capacity              |
      | exec_command_arg  | --kubeconfig                  |
      | exec_command_arg  | /admin-creds/admin.kubeconfig |
      | exec_command_arg  | --podspec                     |
      | exec_command_arg  | /test-pod/pod_with_taint.yaml |
    Then the step should succeed
    Then the expression should be true> @result[:response].to_i == cb.expected_number_per_node.reduce(&:+)
    # following is for unschedulable scenario
    Given node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | <%= cb.nodes[1].name %> |
    Then the step should succeed
    When I run the :exec client command with:
      | pod               | cluster-capacity              |
      | oc_opts_end       |                               |
      | exec_command      | cluster-capacity              |
      | exec_command_arg  | --kubeconfig                  |
      | exec_command_arg  | /admin-creds/admin.kubeconfig |
      | exec_command_arg  | --podspec                     |
      | exec_command_arg  | /test-pod/pod.yaml            |
    Then the step should succeed
    Then the expression should be true> @result[:response].to_i == cb.expected_number_per_node[2..-1].reduce(&:+)

  # @author wjiang@redhat.com
  # @case_id OCP-14797
  @admin
  @destructive
  Scenario: Cluster capacity image support: Cluster capacity can work well with resource reservation
    Given environment has at least 2 schedulable nodes
    Given I have a project
    Given I have a cluster-capacity pod in my project
    Given I register clean-up steps:
    """
      And I wait for the steps to pass:
        | the expression should be true> env.nodes.map { |n| n.capacity_cpu(cached:false) - n.allocatable_cpu(cached:false) == 0 }.reduce(&:&) |
      Then the expression should be true> env.nodes(refresh: true)
    """
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      system-reserved:
      - "cpu=100m,memory=100Mi"
      kube-reserved:
      - "cpu=100m,memory=50Mi"
    """
    Then the node service is restarted on all schedulable nodes
    Given I store the schedulable nodes in the :nodes clipboard
    # we have to wait the node configuration take effect here
    And I wait for the steps to pass:
    """
    Then the expression should be true> cb.nodes.map { |n| n.capacity_cpu(cached:false) - n.allocatable_cpu(cached:false) == 200 }.reduce(&:&)
    """
    Given evaluation of `cb.nodes.map {|n| n.max_pod_count_schedulable(cached: false, cpu: convert_cpu("150m"), memory: convert_to_bytes("100Mi"))}` is stored in the :expected_number_per_node clipboard
    When I run the :exec client command with:
      | pod               | cluster-capacity              |
      | oc_opts_end       |                               |
      | exec_command      | cluster-capacity              |
      | exec_command_arg  | --kubeconfig                  |
      | exec_command_arg  | /admin-creds/admin.kubeconfig |
      | exec_command_arg  | --podspec                     |
      | exec_command_arg  | /test-pod/pod.yaml            |
    Then the step should succeed
    Then the expression should be true> @result[:response].to_i == cb.expected_number_per_node.reduce(&:+)

  # @author wjiang@redhat.com
  # @case_id OCP-14798
  @admin
  Scenario: Cluster capacity image support: Cluster capacity can work well with nodeselector
    Given environment has at least 2 schedulable nodes
    Given I have a project
    Given I have a cluster-capacity pod in my project
    Given I store the schedulable nodes in the :nodes clipboard
    Given evaluation of `cb.nodes.map {|n| n.max_pod_count_schedulable(cpu: convert_cpu("150m"), memory: convert_to_bytes("100Mi"))}` is stored in the :expected_number_per_node clipboard
    Given label "cc=true" is added to the "<%=cb.nodes[0].name%>" node
    When I run the :exec client command with:
      | pod               | cluster-capacity              |
      | oc_opts_end       |                               |
      | exec_command      | cluster-capacity              |
      | exec_command_arg  | --kubeconfig                  |
      | exec_command_arg  | /admin-creds/admin.kubeconfig |
      | exec_command_arg  | --podspec                     |
      | exec_command_arg  | /test-pod/pod.yaml            |
    Then the step should succeed
    Then the expression should be true> @result[:response].to_i == cb.expected_number_per_node.reduce(&:+)
    When I run the :exec client command with:
      | pod               | cluster-capacity              |
      | oc_opts_end       |                               |
      | exec_command      | cluster-capacity              |
      | exec_command_arg  | --kubeconfig                  |
      | exec_command_arg  | /admin-creds/admin.kubeconfig |
      | exec_command_arg  | --podspec                     |
      | exec_command_arg  | /test-pod/pod_with_nodeSelector.yaml  |
    Then the step should succeed
    Then the expression should be true> @result[:response].to_i == cb.expected_number_per_node[0]

  # @author wjiang@redhat.com
  # @case_id OCP-14800
  @admin
  @destructive
  Scenario: Cluster capacity image support: Cluster capacity can work well while pods capacity update
    Given environment has at least 2 schedulable nodes
    Given I have a project
    Given I have a cluster-capacity pod in my project
    Given I register clean-up steps:
    """
      And I wait for the steps to pass:
        | the expression should be true> cb.nodes.map { |n| n.capacity_pods(cached: false) == 250 }.reduce(&:&) |
      Then the expression should be true> env.nodes(refresh: true)
    """
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      max-pods:
      - "20"
    """
    Then the node service is restarted on all schedulable nodes
    Given I store the schedulable nodes in the :nodes clipboard
    # we have to wait node configuration take effect here
    And I wait for the steps to pass:
    """
    Then the expression should be true> cb.nodes.map { |n| n.capacity_pods(cached: false) == 20 }.reduce(&:&)
    """
    Given evaluation of `cb.nodes.map {|n| n.max_pod_count_schedulable(cached: false, cpu: convert_cpu("150m"), memory: convert_to_bytes("100Mi"))}.reduce(&:+)` is stored in the :expected_number_total clipboard
    When I run the :exec client command with:
      | pod               | cluster-capacity              |
      | oc_opts_end       |                               |
      | exec_command      | cluster-capacity              |
      | exec_command_arg  | --kubeconfig                  |
      | exec_command_arg  | /admin-creds/admin.kubeconfig |
      | exec_command_arg  | --podspec                     |
      | exec_command_arg  | /test-pod/pod.yaml            |
    Then the step should succeed
    Then the expression should be true> @result[:response].to_i == cb.expected_number_total

  # @author wjiang@redhat.com
  # @case_id OCP-14801
  @admin
  @destructive
  Scenario: Cluster capacity image support: Cluster capacity can work well when remove/add node
    Given environment has at least 2 schedulable nodes
    Given I have a project
    Given I have a cluster-capacity pod in my project
    # choose a node to be deleted but should not be the node cluster-capacity on,
    # and this is really destructive
    Then the expression should be true> @host = env.nodes.shuffle.find { |n| n.schedulable? and n.name != pod.node_name }.host
    Given evaluation of `env.nodes.find { |n| n.host.hostname == @host.hostname }.name` is stored in the :target_node_name clipboard
    # have to make sure node is back after scenario
    Given I register clean-up steps:
    """
      Given admin wait for the "<%=cb.target_node_name%>" node to appear
      And I wait for the steps to pass:
        | the expression should be true> node.schedulable?(cached: false) == true |
      Then the expression should be true> env.nodes(refresh: true)
    """
    Given the node service is restarted on the host after scenario
    When I run the :delete admin command with:
      | object_type       | node  |
      | object_name_or_id | <%= cb.target_node_name%> |
    Then the step should succeed
    # here should refresh the node list in cache
    Then the expression should be true> env.nodes(refresh: true)
    Given I store the schedulable nodes in the :nodes clipboard
    Given evaluation of `cb.nodes.map {|n| n.max_pod_count_schedulable(cached: false, cpu: convert_cpu("150m"), memory: convert_to_bytes("100Mi"))}.reduce(&:+)` is stored in the :expected_number_total clipboard

    When I run the :exec client command with:
      | pod               | cluster-capacity              |
      | oc_opts_end       |                               |
      | exec_command      | cluster-capacity              |
      | exec_command_arg  | --kubeconfig                  |
      | exec_command_arg  | /admin-creds/admin.kubeconfig |
      | exec_command_arg  | --podspec                     |
      | exec_command_arg  | /test-pod/pod.yaml            |
    Then the step should succeed
    Then the expression should be true> @result[:response].to_i == cb.expected_number_total

  # @author weinliu@redhat.com
  # @case_id OCP-30193
  @admin
  Scenario: Cluster capacity image stage check
    Given I have a project
    Given I store master major version in the :master_version clipboard
    Given I create the serviceaccount "cluster-capacity-sa"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/infrastructure/cluster-capacity-cluster-role.yaml |
    Then the step should succeed
    When admin ensures "cluster-capacity-role" clusterrole is deleted after scenario
    And cluster role "cluster-capacity-role" is added to the "system:serviceaccount:<%= project.name %>:cluster-capacity-sa" service account
    Then the step should succeed
    Given I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/testdata/infrastructure/cluster-capacity/cluster-capacity-configmap.yaml |
    Then the step should succeed
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/infrastructure/cluster-capacity-rc.yaml |
      | p | IMAGE=registry.stage.redhat.io/openshift4/ose-cluster-capacity:<%= cb.master_version %> |
      | p | NAMESPACE=<%= project.name %>                                                           |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=cluster-capacity |
    Then evaluation of `pod.name` is stored in the :capacity_pod clipboard
    Given I wait until replicationController "cluster-capacity" is ready       
    And I wait until number of replicas match "2" for replicationController "cluster-capacity"
    When I run the :logs client command with:
      | resource_name | pod/<%= cb.capacity_pod %> |
      | since         | 60s                        |
    Then the step should succeed
    And the output should match:
      | The\s+cluster\s+can\s+schedule\s+[1-9]*     |
      | instance\(s\)\s+of\s+the\s+pod\s+small-pod. |
