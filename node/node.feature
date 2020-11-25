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

  # @author minmli@redhat.com
  # @case_id OCP-11573
  @admin
  @destructive
  Scenario Outline: Set resource reservation for openshift-node with invalid value
    Given I switch to cluster admin pseudo user
    When I run the :label client command with:
      | resource | machineconfigpool           |
      | name     | worker                      |
      | key_val  | custom-kubelet=set-reserved |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :label client command with:
      | resource | machineconfigpool |
      | name     | worker            |
      | key_val  | custom-kubelet-   |
    Then the step should succeed
    """
    Given I obtain test data file "customresource/<kubeletcfg-name>.yaml"
    And I ensure "<kubeletcfg-name>" kubelet_config is deleted after scenario
    When I run the :create client command with:
      | f | <kubeletcfg-name>.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | kubeletconfig/<kubeletcfg-name> |
      | o             | yaml                            |
    Then the output should contain:
      | <output> |

    Examples: Set resource reservation for openshift-node with invalid value
      | kubeletcfg-name        | output                                                                  |
      | kubelet-set-negative   | Error: KubeletConfiguration: cpu reservation value cannot be negative    |
      | kubelet-set-nondigital | Error: KubeletConfiguration: invalid value specified for cpu reservation |

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
      | quay.io/openshifttest/hello-pod.*sha256:04b6af86b03c1836211be2589db870dba09b7811c197c47c07fbbe33c7f80ef7 |
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | node                 |
      | resource_name | <%= pod.node_name %> |
      | o             | yaml                 |
    Then the step should succeed
    And the output should contain "quay.io/openshifttest/hello-pod@sha256:04b6af86b03c1836211be2589db870dba09b7811c197c47c07fbbe33c7f80ef7"
    """
    And the expression should be true> pod.container_specs.first.image == 'quay.io/openshifttest/hello-pod@sha256:04b6af86b03c1836211be2589db870dba09b7811c197c47c07fbbe33c7f80ef7'
  
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
    And I wait up to 1200 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | node                 |
      | resource_name | <%= pod.node_name %> |
      | o             | yaml                 |
    Then the step should succeed
    And the output should contain "quay.io/openshifttest/hello-pod:latest"
    """
    And the expression should be true> pod.container_specs.first.image == 'quay.io/openshifttest/hello-pod:latest'

  # @author minmli@redhat.com
  # @case_id OCP-26948
  @admin
  @destructive
  Scenario: Should show image digests in node status - 4.x
    Given I store the schedulable nodes in the :nodes clipboard
    Given I use the "<%= cb.nodes[0].name %>" node
    Given I run commands on the host:
      | podman pull quay.io/openshifttest/mysql-56-centos7@sha256:a9fb44bd6753a8053516567a0416db84844e10989140ea2b19ed1d2d8bafc75f |
      | podman images --digests \| grep "mysql-56-centos7"                                                                         |
    Then the step should succeed
    And I wait up to 1200 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | no                      |
      | resource_name | <%= cb.nodes[0].name %> |
      | o             | yaml                    |
    Then the output should contain:
      | quay.io/openshifttest/mysql-56-centos7@sha256:a9fb44bd6753a8053516567a0416db84844e10989140ea2b19ed1d2d8bafc75f |         
    """

  # @author minmli@redhat.com
  # @case_id OCP-32402
  @admin
  Scenario: check hooks_dir in crio conf file
    Given I store the schedulable nodes in the :nodes clipboard
    And I use the "<%= cb.nodes[0].name %>" node
    Given I run commands on the host:
      | grep -i hooks /etc/crio/crio.conf.d/00-default |
    Then the step should succeed
    And the output should contain:
      | hooks_dir = [               |
      | /etc/containers/oci/hooks.d |

  # @author minmli@redhat.com
  # @case_id OCP-32529
  Scenario: [BZ1817568]Liveness probe exec check should succeed
    Given I have a project
    Given I obtain test data file "pods/liveness_probe.yaml"
    When I run the :create client command with:
      | f | liveness_probe.yaml |
    Then the step should succeed
    And the pod named "rhel-ubi" becomes ready
    When I run the :describe client command with:
      | resource | pod      |
      | name     | rhel-ubi |
    Then the step should succeed
    And the output should not contain:
      | Liveness probe failed                    |
      | Container rhel-ubi failed liveness probe |
      | Liveness probe errored                   |

  # @author weinliu@redhat.com
  # @case_id OCP-12808
  @admin
  Scenario: Kubelet should remove configmap volumes when pod is terminated
    Given I have a project
    And I obtain test data file "configmap/OCP-12808/terminatedpods-configmap.yaml"
    When I run the :create client command with:
      | f | terminatedpods-configmap.yaml |
    Then the step should succeed
    Given the pod named "hello-pod-1" status becomes :succeeded
    And evaluation of `pod.node_name` is stored in the :pod1_node clipboard
    And evaluation of `pod.uid(user: user)` is stored in the :pod1_uid clipboard
    When I run the :logs client command with:
      | resource_name | pod/hello-pod-1 |
    Then the step should succeed
    And the output should contain:
      | verycharm |
    Given I use the "<%= cb.pod1_node %>" node
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod1_uid %>/volumes/kubernetes.io~configmap/ |
    Then the output should not contain:
      | No such file or directory |
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod1_uid %>/volumes/kubernetes.io~configmap/configmap-volume |
    Then the output should contain:
      | No such file or directory |
    Given the pod named "hello-pod-2" status becomes :failed
    And evaluation of `pod.node_name` is stored in the :pod2_node clipboard
    And evaluation of `pod.uid(user: user)` is stored in the :pod2_uid clipboard
    When I run the :logs client command with:
      | resource_name | pod/hello-pod-2 |
    Then the step should succeed
    And the output should contain:
      | verycharm |
    Given I use the "<%= cb.pod2_node %>" node
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod2_uid %>/volumes/kubernetes.io~configmap/ |
    Then the output should not contain:
      | No such file or directory |
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod2_uid %>/volumes/kubernetes.io~configmap/configmap-volume |
    Then the output should contain:
      | No such file or directory |

  # @author weinliu@redhat.com
  # @case_id OCP-12809
  @admin
  Scenario: Kubelet should remove secret volumes when pod is terminated
    Given I have a project
    And I obtain test data file "configmap/OCP-12809/terminatedpods-secret-volume.yaml"
    When I run the :create client command with:
      | f | terminatedpods-secret-volume.yaml |
    Then the step should succeed
    Given the pod named "hello-pod-1" status becomes :succeeded
    And evaluation of `pod.node_name` is stored in the :pod1_node clipboard
    And evaluation of `pod.uid` is stored in the :pod1_uid clipboard
    When I run the :logs client command with:
      | resource_name | pod/hello-pod-1 |
    Then the step should succeed
    And the output should contain:
      | value-1 |
      | value-2 |
    Given I use the "<%= cb.pod1_node %>" node
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod1_uid %>/volumes/kubernetes.io~secret/ |
    Then the output should not contain:
      | No such file or directory |
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod1_uid %>/volumes/kubernetes.io~secret/secret-volume-1 |
    Then the output should contain:
      | No such file or directory |
    Given the pod named "hello-pod-2" status becomes :failed
    And evaluation of `pod.node_name` is stored in the :pod2_node clipboard
    And evaluation of `pod.uid` is stored in the :pod2_uid clipboard
    When I run the :logs client command with:
      | resource_name | pod/hello-pod-2 |
    Then the step should succeed
    And the output should contain:
      | value-1 |
      | value-2 |
    Given I use the "<%= cb.pod2_node %>" node
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod2_uid %>/volumes/kubernetes.io~secret/ |
    Then the output should not contain:
      | No such file or directory |
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod2_uid %>/volumes/kubernetes.io~secret/secret-volume-2 |
    Then the output should contain:
      | No such file or directory |

  # @author weinliu@redhat.com
  # @case_id OCP-12810
  @admin
  Scenario: Kubelet should remove memory based emptydir volumes when pod is terminated
    Given I have a project
    And I obtain test data file "configmap/OCP-12810/terminatedpods-empty-memory.yaml"
    When I run the :create client command with:
      | f | terminatedpods-empty-memory.yaml |
    Then the step should succeed
    Given the pod named "hello-pod-1" status becomes :succeeded
    And evaluation of `pod.node_name` is stored in the :pod1_node clipboard
    And evaluation of `pod.uid` is stored in the :pod1_uid clipboard
    Given I use the "<%= cb.pod1_node %>" node
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod1_uid %>/volumes/kubernetes.io~empty-dir/ |
    Then the output should not contain:
      | No such file or directory |
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod1_uid %>/volumes/kubernetes.io~empty-dir/tmp |
    Then the output should contain:
      | No such file or directory |
    Given the pod named "hello-pod-2" status becomes :failed
    And evaluation of `pod.node_name` is stored in the :pod2_node clipboard
    And evaluation of `pod.uid` is stored in the :pod2_uid clipboard
    Given I use the "<%= cb.pod2_node %>" node
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod2_uid %>/volumes/kubernetes.io~empty-dir/ |
    Then the output should not contain:
      | No such file or directory |
    When I run commands on the host:
      | ls -d /var/lib/kubelet/pods/<%= cb.pod2_uid %>/volumes/kubernetes.io~empty-dir/tmp |
    Then the output should contain:
      | No such file or directory |

  # @author minmli@redhat.com
  # @case_id OCP-32519
  @admin
  @destructive
  Scenario: Add blockedRegistries to image.config.openshift.io
    When I run the :patch admin command with:
      | resource      | image.config.openshift.io                                             |
      | resource_name | cluster                                                               |
      | p             | {"spec":{"registrySources":{"blockedRegistries":["chaosmonkey.io"]}}} |
      | type          | merge                                                                 |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    Then the expression should be true> machine_config_pool('worker').condition(type: 'Updating', cached: false)["status"] == "True"
    Then the expression should be true> machine_config_pool('master').condition(type: 'Updating', cached: false)["status"] == "True"
    """
    And I wait up to 1200 seconds for the steps to pass:
    """
    Then the expression should be true> machine_config_pool('worker').condition(type: 'Updating', cached: false)["status"] == "False"
    Then the expression should be true> machine_config_pool('worker').condition(type: 'Updated', cached: false)["status"] == "True"
    Then the expression should be true> machine_config_pool('master').condition(type: 'Updating', cached: false)["status"] == "False"
    Then the expression should be true> machine_config_pool('master').condition(type: 'Updated', cached: false)["status"] == "True"
    """
    Given I store the schedulable workers in the :workers clipboard
    Given I store the schedulable masters in the :masters clipboard
    And I use the "<%= cb.workers[0].name %>" node
    Given I run commands on the host:
      | grep "blocked" -B3 /etc/containers/registries.conf |
    Then the step should succeed
    And the output should contain:
      | location = "chaosmonkey.io" |
      | blocked = true              |
    And I use the "<%= cb.masters[0].name %>" node
    Given I run commands on the host:
      | grep "blocked" -B3 /etc/containers/registries.conf |
    Then the step should succeed
    And the output should contain:
      | location = "chaosmonkey.io" |
      | blocked = true              |

