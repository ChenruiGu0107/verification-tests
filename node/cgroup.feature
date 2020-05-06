Feature: Cgroup related scenario

  # @author qwang@redhat.com
  # @case_id OCP-14660
  @admin
  @destructive
  Scenario: Test enforce-node-allocatable with --cgroups-per-qos=false
    Given I select a random node's host
    When I run the :get admin command with:
      | resource      | node             |
      | resource_name | <%= node.name %> |
      | o             | yaml             |
    Then the step should succeed
    And evaluation of `@result[:parsed]["status"]["capacity"]["cpu"]` is stored in the :node_capacity_cpu clipboard
    And evaluation of `@result[:parsed]["status"]["capacity"]["memory"].gsub(/Ki/,'')` is stored in the :node_capacity_memory clipboard
    And evaluation of `@result[:parsed]["status"]["allocatable"]["cpu"]` is stored in the :node_allocate_cpu clipboard
    And evaluation of `@result[:parsed]["status"]["allocatable"]["memory"].gsub(/Ki/,'')` is stored in the :node_allocate_memory clipboard
    # Set cgroups-per-qos to false and enforce-node-allocatable with values
    When node config is merged with the following hash:
    """
    kubeletArguments:
      cgroups-per-qos:
      - "false"
      cgroup-driver:
      - "systemd"
      enforce-node-allocatable:
      - "pods"
    """
    And I try to restart the node service on node
    Then the step should fail
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "10 sec ago" \| grep "Cgroup" |
    Then the step should succeed
    And the output should match:
      | ([Ff]ailed to run Kubelet:\s+Node Allocatable enforcement\|EnforceNodeAllocatable \(--enforce-node-allocatable\)) is not supported unless Cgroups ?Per ?QOS\s?(\s?\(--cgroups-per-qos\))? feature is turned on |
    # Set cgroups-per-qos to false and enforce-node-allocatable without values
    When node config is merged with the following hash:
    """
    kubeletArguments:
      cgroups-per-qos:
      - "false"
      cgroup-driver:
      - "systemd"
      enforce-node-allocatable:
      - ""
      kube-reserved:
      - "cpu=100m,memory=100Mi"
      system-reserved:
      - "cpu=200m,memory=200Mi"
    """
    And I try to restart the node service on node
    Then the step should succeed
    When I run the :describe admin command with:
      | resource | node             |
      | name     | <%= node.name %> |
    Then the step should succeed
    And the output by order should match:
      | cpu:\\s+<%= cb.node_capacity_cpu %>                     |
      | memory:\\s+<%= cb.node_capacity_memory %>               |
      | cpu:\\s+<%= cb.node_allocate_cpu.to_i*1000-300 %>       |
      | memory:\\s+<%= cb.node_allocate_memory.to_i-300*1024 %> |
    When I run commands on the host:
      | cat /sys/fs/cgroup/memory/kubepods.slice/memory.limit_in_bytes |
    Then the step should succeed
    And the output should contain:
      | <%= cb.node_capacity_memory.to_i*1024 %> |
