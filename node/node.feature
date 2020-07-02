Feature: Node management
  # @author chezhang@redhat.com
  # @case_id OCP-12162
  @admin
  @destructive
  Scenario: Set invalid value for kubelet hard eviction parameters - memory
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      eviction-hard:
      - "memory.available<-100Mi"
    """
    And I try to restart the node service on all schedulable nodes
    Then the step should fail
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      eviction-hard:
      - "memory.available<100xMix"
    """
    And I try to restart the node service on all schedulable nodes
    Then the step should fail
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      eviction-hard:
      - "memory.available<1000000Gi"
    """
    And the node service is restarted on all nodes
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      eviction-hard:
      - "memory.available<0.00000000001Mi"
    """
    And the node service is restarted on all nodes
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      eviction-hard:
      - "memory.available<0Mi"
    """
    And I try to restart the node service on all schedulable nodes
    Then the step should fail

  # @author chezhang@redhat.com
  # @case_id OCP-10472
  @admin
  @destructive
  Scenario: enable pods-per-core and max-pods in node configuration
    Given I store the schedulable nodes in the :nodes clipboard
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      pods-per-core:
      - '10'
    """
    And the node service is restarted on all nodes
    When I run the :get admin command with:
      | resource      | node                    |
      | resource_name | <%= cb.nodes[0].name %> |
      | o             | yaml                    |
    Then the step should succeed
    And evaluation of `@result[:parsed]["status"]["capacity"]["cpu"]` is stored in the :nodecpu clipboard
    And the output should match 2 times:
      | pods:\\s+"<%= cb.nodecpu %>0" |
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      pods-per-core:
      - '0'
    """
    And the node service is restarted on all nodes
    When I run the :get admin command with:
      | resource      | node                    |
      | resource_name | <%= cb.nodes[0].name %> |
      | o             | yaml                    |
    Then the step should succeed
    And the output should match 2 times:
      | pods:\\s+"250" |

  # @author chezhang@redhat.com
  # @case_id OCP-11573
  @admin
  @destructive
  Scenario: Set resource reservation for openshift-node with invalid value
    Given I store the schedulable nodes in the :nodes clipboard
    When I run the :get admin command with:
      | resource      | node                    |
      | resource_name | <%= cb.nodes[0].name %> |
      | o             | yaml                    |
    Then the step should succeed
    And evaluation of `@result[:parsed]["status"]["capacity"]["cpu"]` is stored in the :node_capacity_cpu clipboard
    And evaluation of `@result[:parsed]["status"]["capacity"]["memory"]` is stored in the :node_capacity_memory clipboard
    And evaluation of `@result[:parsed]["status"]["allocatable"]["cpu"]` is stored in the :node_allocate_cpu clipboard
    And evaluation of `@result[:parsed]["status"]["allocatable"]["memory"]` is stored in the :node_allocate_memory clipboard
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      system-reserved:
      - "cpu=0m,memory=0G"
      kube-reserved:
      - "cpu=0m,memory=0G"
    """
    And the node service is restarted on all nodes
    When I run the :describe admin command with:
      | resource | node   |
      | name     | <%= cb.nodes[0].name %> |
    Then the step should succeed
    Then the output by order should match:
      | cpu:\\s+<%= cb.node_capacity_cpu %>       |
      | memory:\\s+<%= cb.node_capacity_memory %> |
      | cpu:\\s+<%= cb.node_allocate_cpu %>       |
      | memory:\\s+<%= cb.node_allocate_memory %> |
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      system-reserved:
      - "cpu=-200m,memory=-1G"
      kube-reserved:
      - "cpu=-200m,memory=-1G"
    """
    And I try to restart the node service on all schedulable nodes
    Then the step should fail
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      system-reserved:
      - "cpu=-200km,memory=-1Gk"
      kube-reserved:
      - "cpu=-200km,memory=-1Gk"
    """
    And I try to restart the node service on all schedulable nodes
    Then the step should fail
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      system-reserved:
      - "cpu=200,memory=1000G"
      kube-reserved:
      - "cpu=200,memory=1000G"
    """
    And the node service is restarted on all nodes
    When I run the :describe admin command with:
      | resource | node                    |
      | name     | <%= cb.nodes[0].name %> |
    Then the step should succeed
    Then the output by order should match:
      | cpu:\\s+<%= cb.node_capacity_cpu %>       |
      | memory:\\s+<%= cb.node_capacity_memory %> |
      | cpu:\\s+0                                 |
      | memory:\\s+0                              |

  # @author chezhang@redhat.com
  # @case_id OCP-12218
  @admin
  @destructive
  Scenario: Set invalid value for kubelet soft eviction parameters - memory
    Given I select a random node's host
    And node config is merged with the following hash:
    """
    kubeletArguments:
      eviction-soft:
      - "memory.available<-300Mi"
      eviction-soft-grace-period:
      - "memory.available=-30s"
    """
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "atomic-openshift-node.service failed"
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "memory.available must be positive" |
    Then the step should succeed
    Given node config is merged with the following hash:
    """
    kubeletArguments:
      eviction-soft:
      - "memory.available<xf300Mi"
      eviction-soft-grace-period:
      - "memory.available=x30sx"
      eviction-max-pod-grace-period:
      - "xf10fs"
    """
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "atomic-openshift-node.service failed"
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "eviction-max-pod-grace-period: Invalid value: \"xf10fs\"" |
    Then the step should succeed
    Given node config is merged with the following hash:
    """
    kubeletArguments:
      eviction-soft:
      - "memory.available<10000000000000Mi"
      eviction-soft-grace-period:
      - "memory.available=3000000000000s"
      eviction-max-pod-grace-period:
      - "3000000000000"
    """
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "atomic-openshift-node.service failed"
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "eviction-max-pod-grace-period: Invalid value: \"3000000000000\"" |
    Then the step should succeed
    Given node config is merged with the following hash:
    """
    kubeletArguments:
      eviction-soft:
      - "memory.available<0.00000000001Mi"
      eviction-soft-grace-period:
      - "memory.available=0.00000000001s"
      eviction-max-pod-grace-period:
      - "0.00000000001"
    """
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "atomic-openshift-node.service failed"
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "eviction-max-pod-grace-period: Invalid value: \"0.00000000001\"" |
    Then the step should succeed
    Given node config is merged with the following hash:
    """
    kubeletArguments:
      eviction-soft:
      - "memory.available<0Mi"
      eviction-soft-grace-period:
      - "memory.available=0s"
      eviction-max-pod-grace-period:
      - "0"
    """
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "atomic-openshift-node.service failed"
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "memory.available must be positive" |
    Then the step should succeed

  # @author zzhao@redhat.com
  # @case_id OCP-15189
  @admin
  Scenario: Check the ARP cache on the node
    Given I select a random node's host
    When I run commands on the host:
      | sysctl -a \| grep net.ipv4.neigh.default.gc_thresh |
    Then the step should succeed
    And the output should contain:
      | net.ipv4.neigh.default.gc_thresh1 = 8192  |
      | net.ipv4.neigh.default.gc_thresh2 = 32768 |
      | net.ipv4.neigh.default.gc_thresh3 = 65536 |

  # @author qwang@redhat.com
  # @case_id OCP-14638
  @admin
  @destructive
  Scenario: Eviction thresholds is enable by default and can be enable/disable via experimental-allocatable-ignore-eviction
    # Make sure when there are multi-node, you just modify one and operate on this one
    Given I store the schedulable nodes in the :nodes clipboard
    And I use the "<%= cb.nodes[0].name %>" node
    And evaluation of `cb.nodes[0].capacity_cpu(user: admin)` is stored in the :node_capacity_cpu clipboard
    And evaluation of `cb.nodes[0].capacity_memory` is stored in the :node_capacity_memory clipboard
    And evaluation of `cb.nodes[0].allocatable_cpu` is stored in the :node_allocate_cpu clipboard
    And evaluation of `cb.nodes[0].allocatable_memory` is stored in the :node_allocate_memory clipboard
    And the expression should be true> <%= cb.node_capacity_cpu %> == <%= cb.node_allocate_cpu %>
    And the expression should be true> <%= cb.node_capacity_memory %> - <%= cb.node_allocate_memory %> == 100 * 1024 * 1024
    When I run commands on the host:
      | cat /sys/fs/cgroup/memory/kubepods.slice/memory.limit_in_bytes |
    Then the step should succeed
    # Eviction-hard-threhold is not used in the calculation for memory.limit_in_bytes. It's by design
    And the output should contain:
      | <%= cb.node_capacity_memory %> |
    When node config is merged with the following hash:
    """
    kubeletArguments:
      experimental-allocatable-ignore-eviction:
      - "true"
    """
    When I try to restart the node service on node
    Then the step should succeed
    And the expression should be true> cb.nodes[0].capacity_cpu(user: admin, cached: false) == cb.nodes[0].allocatable_cpu
    And the expression should be true> cb.nodes[0].capacity_memory == cb.nodes[0].allocatable_memory
    And the expression should be true> cb.nodes[0].allocatable_memory - <%= cb.node_allocate_memory %> == 100 * 1024 * 1024
    When I run commands on the host:
      | cat /sys/fs/cgroup/memory/kubepods.slice/memory.limit_in_bytes |
    Then the step should succeed
    And the output should contain:
      | <%= cb.node_capacity_memory %> |

  # @author xxia@redhat.com
  # @case_id OCP-15870
  @admin
  Scenario: Verify node authorization is enabled
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I run the :get admin command with:
      | resource | secret/not-existing-secret       |
      | n        | <%= project.name %>              |
      | as       | system:node:<%= pod.node_name %> |
      | as_group | system:nodes                     |
    Then the step should fail
    And the output should contain "forbidden"

    When I run the :create_secret client command with:
      | secret_type   | generic  |
      | name          | mysecret |
      | from_literal  | user=Bob |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | secret/mysecret                  |
      | n        | <%= project.name %>              |
      | as       | system:node:<%= pod.node_name %> |
      | as_group | system:nodes                     |
    Then the step should fail
    And the output should contain "forbidden"

    Given I get project pod named "hello-openshift" as YAML
    And evaluation of `@result[:parsed]['spec']['volumes'].find { |v| v['secret'] }['secret']['secretName']` is stored in the :pod_secret_name clipboard
    When I run the :get admin command with:
      | resource | secret/<%= cb.pod_secret_name %> |
      | n        | <%= project.name %>              |
      | as       | system:node:<%= pod.node_name %> |
      | as_group | system:nodes                     |
    Then the step should succeed

    Given I store the nodes in the clipboard
    And evaluation of `cb.nodes.find { |n| n.name != pod.node_name }.name` is stored in the :other_node_name clipboard
    When I run the :label admin command with:
      | resource | no/<%= cb.other_node_name %>     |
      | key_val  | testlabel=testvalue              |
      | as       | system:node:<%= pod.node_name %> |
      | as_group | system:nodes                     |
    Then the step should fail
    And the output should contain "forbidden"

  # @author minmli@redhat.com
  # @case_id OCP-29655
  @admin
  Scenario: NodeStatus and PodStatus show correct imageID while pulling by digests - 4.x
    Given I have a project
    Given I obtain test data file "pods/pod-pull-by-digests.yaml"
    When I run the :create client command with:
      | f | pod-pull-by-digests.yaml |
    Then the step should succeed
    And the pod named "pod-pull-by-digests" becomes ready
    Given I use the "<%= pod.node_name %>" node
    Given I run commands on the host:
      | podman images --digests \| grep hello-pod |
    Then the step should succeed
    And the output should match:
      | quay.io/openshifttest/hello-pod.*sha256:fd771a64c32e77eda0901d6c4c2d05b0dd1a5a79d9f29b25ae0b1b66d9149615 |
    When I run the :get admin command with:
      | resource      | node                 |
      | resource_name | <%= pod.node_name %> |
      | o             | yaml                 |
    Then the step should succeed
    And the output should contain "quay.io/openshifttest/hello-pod@sha256:fd771a64c32e77eda0901d6c4c2d05b0dd1a5a79d9f29b25ae0b1b66d9149615"
    And the expression should be true> pod.container_specs.first.image == 'quay.io/openshifttest/hello-pod@sha256:fd771a64c32e77eda0901d6c4c2d05b0dd1a5a79d9f29b25ae0b1b66d9149615'
  
  # @author minmli@redhat.com
  # @case_id OCP-29679
  @admin
  Scenario: NodeStatus and PodStatus show correct imageID while pulling by tag - 4.x
    Given I have a project
    Given I obtain test data file "pods/pod-pull-by-tag.yaml"
    When I run the :create client command with:
      | f | pod-pull-by-tag.yaml |
    Then the step should succeed
    And the pod named "pod-pull-by-tag" becomes ready
    Given I use the "<%= pod.node_name %>" node
    Given I run commands on the host:
      | podman images --digests \| grep hello-pod |
    Then the step should succeed
    And the output should match:
      | quay.io/openshifttest/hello-pod.*latest |
    When I run the :get admin command with:
      | resource      | node                 |
      | resource_name | <%= pod.node_name %> |
      | o             | yaml                 |
    Then the step should succeed
    And the output should contain "quay.io/openshifttest/hello-pod:latest"
    And the expression should be true> pod.container_specs.first.image == 'quay.io/openshifttest/hello-pod:latest'

  # @author minmli@redhat.com
  # @case_id OCP-26948
  @admin
  @destructive
  Scenario: Should show image digests in node status - 4.x
    Given I store the schedulable nodes in the :nodes clipboard
    Given I use the "<%= cb.nodes[0].name %>" node
    Given I run commands on the host:
      | podman pull quay.io/openshifttest/caddy-docker-2:latest                                                                    |
      | podman pull quay.io/openshifttest/nginx:latest                                                                             |
      | podman pull quay.io/openshifttest/mysql-56-centos7@sha256:a9fb44bd6753a8053516567a0416db84844e10989140ea2b19ed1d2d8bafc75f |
      | podman images --digests \| grep -E "caddy-docker-2\|nginx\|mysql-56-centos7"                                               |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | no                      |
      | resource_name | <%= cb.nodes[0].name %> |
      | o             | yaml                    |
    Then the output should contain:
      | quay.io/openshifttest/caddy-docker-2:latest                                                                    |
      | quay.io/openshifttest/nginx:latest                                                                             |
      | quay.io/openshifttest/mysql-56-centos7@sha256:a9fb44bd6753a8053516567a0416db84844e10989140ea2b19ed1d2d8bafc75f |         
    """
    Given I use the "<%= cb.nodes[0].name %>" node
    Given I run commands on the host:
      | podman image rm  quay.io/openshifttest/nginx:latest |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | no                      |
      | resource_name | <%= cb.nodes[0].name %> |
      | o             | yaml                    |
    Then the output should not contain:
      | quay.io/openshifttest/nginx:latest |
    """

