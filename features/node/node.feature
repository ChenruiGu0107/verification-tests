Feature: Node management
  # @author chaoyang@redhat.com
  # @case_id OCP-11084
  @admin
  Scenario: admin can get nodes
    Given I have a project
    When I run the :get admin command with:
      |resource|nodes|
    Then the step should succeed
    Then the outputs should contain "Ready"


  # @author yinzhou@redhat.com
  # @case_id OCP-11706
  @admin
  Scenario: The valid client cert and key should be accepted when connect to kubelet	
    Given I use the first master host
    And I run commands on the host:
      | curl https://<%= host.hostname %>:10250/spec/ --cert /etc/origin/master/master.kubelet-client.crt  --cacert /etc/origin/master/ca.crt --key /etc/origin/master/master.kubelet-client.key |
    Then the step should succeed


  # @author yinzhou@redhat.com
  # @case_id OCP-10712,OCP-11190,OCP-11755,OCP-11529
  @admin
  @destructive
  Scenario: Anonymous user can fetch metrics/stats after grant permission to it
    Given I use the first master host
    When I run commands on the host:
      | curl -X GET -k https://<%= host.hostname %>:10250/stats/ |
    And the output should contain "Forbidden"
    Given config of all nodes is merged with the following hash:
    """
    authConfig:
      authenticationCacheSize: 1000
      authenticationCacheTTL: "1m"
      authorizationCacheSize: 1000
      authorizationCacheTTL: "1m"
    """
    Then the step should succeed
    And the node service is restarted on all nodes
    Given cluster role "system:node-reader" is added to the "system:unauthenticated" group
    And 62 seconds have passed
    When I run commands on the host:
      | curl -X GET -k https://<%= host.hostname %>:10250/stats/ |
    And the output should not contain "Forbidden"
    Given I have a project
    When I run commands on the host:
      | curl -X GET -k https://<%= host.hostname %>:10250/stats/ -H "Authorization: Bearer <%= user.get_bearer_token.token %> " |
    And the output should contain "Forbidden"
    Given cluster role "system:node-reader" is added to the "first" user
    And 62 seconds have passed
    When I run commands on the host:
      | curl -X GET -k https://<%= host.hostname %>:10250/stats/ -H "Authorization: Bearer <%= user.get_bearer_token.token %> " |
    And the output should not contain "Forbidden"
    When I find a bearer token of the deployer service account
    When I run commands on the host:
      | curl -X GET -k https://<%= host.hostname %>:10250/stats/ -H "Authorization: Bearer <%= service_account.get_bearer_token.token %> " |
    And the output should contain "Forbidden"
    Given cluster role "system:node-reader" is added to the "system:serviceaccount:<%= project.name %>:deployer" service account
    And 62 seconds have passed
    When I run commands on the host:
      | curl -X GET -k https://<%= host.hostname %>:10250/stats/ -H "Authorization: Bearer <%= service_account.get_bearer_token.token %> " |
    And the output should not contain "Forbidden"

  # @author chezhang@redhat.com
  # @case_id OCP-11833
  @admin
  @destructive
  Scenario: Specify unsafe namespaced kernel parameters for pod with invalid value
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      experimental-allowed-unsafe-sysctls:
      - 'kernel.shm*,kernel.msg*,kernel.sem,fs.mqueue.*,net.*'
    """
    Then the step should succeed
    And the node service is restarted on all nodes
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/sysctls/pod-sysctl-unsafe-invalid1.yaml |
    Then the step should fail
    And the output should match:
      | Invalid value: "invalid": sysctl "invalid" not of the format sysctl_name |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/sysctls/pod-sysctl-unsafe-invalid3.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | po |
    Then the output should match:
      | hello-pod.*SysctlForbidden |
    When I run the :describe client command with:
      | resource | po        |
      | name     | hello-pod |
    Then the output should match:
      | Warning\\s+SysctlForbidden\\s+forbidden sysctl: "invalid" not whitelisted |
    """
    Given I ensure "hello-pod" pod is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/sysctls/pod-sysctl-unsafe-invalid2.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | po        |
      | name     | hello-pod |
    Then the output should match:
      | Warning.*Error syncing pod |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-11643
  @admin
  @destructive
  Scenario: Specify unsafe namespaced kernel parameters for pod
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/sysctls/pod-sysctl-unsafe.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | po |
    Then the output should match:
      | hello-pod.*SysctlForbidden |
    """
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      experimental-allowed-unsafe-sysctls:
      - 'kernel.shm*,kernel.msg*,kernel.sem,fs.mqueue.*,net.*'
    """
    Then the step should succeed
    And the node service is restarted on all nodes
    Given I ensure "hello-pod" pod is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/sysctls/pod-sysctl-unsafe.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I execute on the pod:
      | cat | /proc/sys/net/ipv4/ip_forward |
    Then the output should equal "0"

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
    Then the step should succeed
    And I try to restart the node service on all schedulable nodes
    Then the step should fail
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      eviction-hard:
      - "memory.available<100xMix"
    """
    Then the step should succeed
    And I try to restart the node service on all schedulable nodes
    Then the step should fail
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      eviction-hard:
      - "memory.available<1000000Gi"
    """
    Then the step should succeed
    And the node service is restarted on all nodes
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      eviction-hard:
      - "memory.available<0.00000000001Mi"
    """
    Then the step should succeed
    And the node service is restarted on all nodes
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      eviction-hard:
      - "memory.available<0Mi"
    """
    Then the step should succeed
    And I try to restart the node service on all schedulable nodes
    Then the step should fail

  # @author chezhang@redhat.com
  # @case_id OCP-10769
  @admin
  @destructive
  Scenario: ContainerGC will clean container after minimum-container-ttl-duration
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      maximum-dead-containers:
      - '20'
      maximum-dead-containers-per-container:
      - '1'
      minimum-container-ttl-duration:
      - 1m
    """
    Then the step should succeed
    And the node service is restarted on all nodes
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pod-pull-by-tag.yaml |
    Then the step should succeed
    And the pod named "pod-pull-by-tag" becomes ready
    Given evaluation of `pod("pod-pull-by-tag").node_name(user: user)` is stored in the :node clipboard
    Given I ensure "pod-pull-by-tag" pod is deleted
    Given 50 seconds have passed
    Given I use the "<%= cb.node %>" node
    Given I run commands on the host:
      | docker ps -a \|grep pod-pull-by-tag |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
   """
    Given I use the "<%= cb.node %>" node
    Given I run commands on the host:
      | docker ps -a \|grep pod-pull-by-tag |
    Then the step should fail
   """

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
    Then the step should succeed
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
    Then the step should succeed
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
    Then the step should succeed
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
    Then the step should succeed
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
    Then the step should succeed
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
    Then the step should succeed
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
  # @case_id OCP-12845
  @admin
  @destructive
  Scenario: Negative test for kubelet keep-terminated-pod-volumes parameter
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      keep-terminated-pod-volumes:
      - "invalid"
    """
    Then the step should succeed
    And I try to restart the node service on all schedulable nodes
    Then the step should fail
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      keep-terminated-pod-volumes:
      - "12345"
    """
    Then the step should succeed
    And I try to restart the node service on all schedulable nodes
    Then the step should fail
    Given config of all schedulable nodes is merged with the following hash:
    """
    kubeletArguments:
      keep-terminated-pod-volumes:
      - "$%^&*!@#"
    """
    Then the step should succeed
    And I try to restart the node service on all schedulable nodes
    Then the step should fail

  # @author chezhang@redhat.com
  # @case_id OCP-12843
  @admin
  @destructive
  Scenario: Kubelet should remove disk backed emptydir volumes when pod is terminated
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/emtydir-host.yaml |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | po |
    Then the output should match:
      | hello-pod\\s+.*Completed |
      | hello-pod-1\\s+.*Error   |
    """
    Given evaluation of `pod("hello-pod").node_name(user: user)` is stored in the :node1 clipboard
    Given evaluation of `pod("hello-pod-1").node_name(user: user)` is stored in the :node2 clipboard
    Given evaluation of `pod("hello-pod").uid(user: user)` is stored in the :uid1 clipboard
    Given evaluation of `pod("hello-pod-1").uid(user: user)` is stored in the :uid2 clipboard
    Given I use the "<%= cb.node1 %>" node
    Given I run commands on the host:
      | ls -l /var/lib/origin/openshift.local.volumes/pods/<%= cb.uid1 %>/volumes/kubernetes.io~empty-dir/tmp |
    Then the step should fail
    Given I use the "<%= cb.node2 %>" node
    Given I run commands on the host:
      | ls -l /var/lib/origin/openshift.local.volumes/pods/<%= cb.uid2 %>/volumes/kubernetes.io~empty-dir/tmp |
    Then the step should fail
    Given I ensure "hello-pod" pod is deleted
    Given I ensure "hello-pod-1" pod is deleted
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      keep-terminated-pod-volumes:
      - "true"
    """
    Then the step should succeed
    And the node service is restarted on all nodes
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/emtydir-host.yaml |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | po |
    Then the output should match:
      | hello-pod\\s+.*Completed |
      | hello-pod-1\\s+.*Error   |
    """
    Given evaluation of `pod("hello-pod").node_name(user: user, cached: false)` is stored in the :node1 clipboard
    Given evaluation of `pod("hello-pod-1").node_name(user: user, cached: false)` is stored in the :node2 clipboard
    Given evaluation of `pod("hello-pod").uid(user: user, cached: false)` is stored in the :uid1 clipboard
    Given evaluation of `pod("hello-pod-1").uid(user: user, cached: false)` is stored in the :uid2 clipboard
    Given I use the "<%= cb.node1 %>" node
    Given I run commands on the host:
      | ls -l /var/lib/origin/openshift.local.volumes/pods/<%= cb.uid1 %>/volumes/kubernetes.io~empty-dir/tmp |
    Then the step should succeed
    And the output should contain:
      | total 0 |
    Given I use the "<%= cb.node2 %>" node
    Given I run commands on the host:
      | ls -l /var/lib/origin/openshift.local.volumes/pods/<%= cb.uid2 %>/volumes/kubernetes.io~empty-dir/tmp |
    Then the step should succeed
    And the output should contain:
      | total 0 |

  # @author chezhang@redhat.com
  # @case_id OCP-11467
  @admin
  @destructive
  Scenario: Validation of pod manifest config
    Given I select a random node's host
    And node config is merged with the following hash:
    """
    podManifestConfig:
      fileCheckIntervalSeconds: 30
    """
    Then the step should succeed
    And I try to restart the node service on node
    And the step should fail
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "podManifestConfig.path: Required value" |
    Then the step should succeed
    And node config is merged with the following hash:
    """
    podManifestConfig:
      path: "/etc/origin/node/no-such-path"
      fileCheckIntervalSeconds: 30
    """
    Then the step should succeed
    And I try to restart the node service on node
    Then the step should fail
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "podManifestConfig.*Invalid value: \"/etc/origin/node/no-such-path\"" |
    Then the step should succeed
    And node config is merged with the following hash:
    """
    podManifestConfig:
      path: "/etc/origin/node"
      fileCheckIntervalSeconds: -30
    """
    Then the step should succeed
    And I try to restart the node service on node
    Then the step should fail
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "podManifestConfig.*Invalid value: -30: interval has to be positive" |
    Then the step should succeed
    And node config is merged with the following hash:
    """
    podManifestConfig:
      path: "/etc/origin/node"
      fileCheckIntervalSeconds: test
    """
    Then the step should succeed
    And I try to restart the node service on node
    Then the step should fail
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "could not load config file.*got first char" |
    Then the step should succeed

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
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "control process exited with error"
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
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "control process exited with error"
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
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "control process exited with error"
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
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "control process exited with error"
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
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "control process exited with error"
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "memory.available must be positive" |
    Then the step should succeed

  # @author chezhang@redhat.com
  # @case_id OCP-13737
  @admin
  @destructive
  Scenario: Misconfiguration for QoS level cgroup
    Given I select a random node's host
    And node config is merged with the following hash:
    """
    kubeletArguments:
      cgroups-per-qos:
      - 'true'
      cgroup-driver:
      - 'system'
    """
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "control process exited with error"
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "misconfiguration: kubelet cgroup driver: \"system\" is different from docker cgroup driver: \"systemd\"" |
    Then the step should succeed
    Given node config is merged with the following hash:
    """
    kubeletArguments:
      cgroups-per-qos:
      - 'true'
      cgroup-driver:
      - 'cgroupfs'
    """
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should fail
    And the output should contain "control process exited with error"
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-node --since "1 min ago" \| grep "misconfiguration: kubelet cgroup driver: \"cgroupfs\" is different from docker cgroup driver: \"systemd\"" |
    Then the step should succeed
    Given node config is merged with the following hash:
    """
    kubeletArguments:
      cgroups-per-qos:
      - 'true'
      cgroup-driver:
      - 'systemd'
    """
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should succeed

    Given node config is merged with the following hash:
    """
    kubeletArguments:
      cgroups-per-qos:
      - 'true'
      cgroup-driver:
      - ''
    """
    Then the step should succeed
    When I try to restart the node service on node
    Then the step should succeed

  # @author chezhang@redhat.com
  # @case_id OCP-10264
  @admin
  @destructive
  Scenario: ContainerGC will remain maximum-dead-containers-per-container
    Given config of all nodes is merged with the following hash:
    """
    kubeletArguments:
      maximum-dead-containers:
      - '100'
      maximum-dead-containers-per-container:
      - '2'
      minimum-container-ttl-duration:
      - 10s
    """
    Then the step should succeed
    And the node service is restarted on all nodes
    Given I have a project
    Given I store the schedulable nodes in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | size=large:NoSchedule                           |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %> |
      | key_val   | size-                   |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/maximum-dead-containers-per-container.yaml |
    Then the step should succeed
    Given 90 seconds have passed
    Given I use the "<%= cb.nodes[0].name %>" node
    Given I run commands on the host:
      | docker ps -a \|grep max-dead-containers-per-container \|grep Exited \| wc -l |
    Then the step should succeed
    And the output should equal "2"

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
