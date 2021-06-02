Feature: etcd related features

  # @author geliu@redhat.com
  # @case_id OCP-24280
  @admin
  Scenario: Etcd basic verification
    Given I switch to cluster admin pseudo user
    When I use the "openshift-etcd" project
    Given 3 pods become ready with labels:
      | k8s-app=etcd |
    Given evaluation of `@pods[0].name` is stored in the :etcdpod clipboard
    When I execute on the pod:
      | bash| -c | etcdctl member list |
    Then the output should contain 3 times:
      | , started, |

  # @author geliu@redhat.com
  # @case_id OCP-19980
  @admin
  @destructive
  Scenario: etcd operator subscription and destroy
    Given I switch to cluster admin pseudo user
    Given admin ensures "etcd-9.2-test" subscriptions is deleted from the "openshift-operators" project after scenario
    Given admin ensures "etcdoperator.v0.9.4-clusterwide" csv is deleted from the "openshift-operators" project after scenario
    And I obtain test data file "admin/subscription.yaml"
    When I run the :create client command with:
      | f | subscription.yaml |
    When I use the "openshift-operators" project
    And status becomes :running of 1 pods labeled:
      | name=etcd-operator-alm-owned |
    When I obtain test data file "admin/etcd-cluster.yaml"
    And I replace lines in "etcd-cluster.yaml":
      | namespace: default | namespace: openshift-operators |
    Given admin ensures "example" etcd_cluster is deleted from the "openshift-operators" project after scenario
    When I run the :create client command with:
      | f | etcd-cluster.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | etcd_cluster=example |
    And status becomes :running of 3 pods labeled:
      | app=etcd |

  # @author geliu@redhat.com
  # @case_id OCP-19981
  @admin
  @destructive
  Scenario: Resize an etcd cluster
    Given I switch to cluster admin pseudo user
    Given admin ensures "etcd-9.2-test" subscriptions is deleted from the "openshift-operators" project after scenario
    Given admin ensures "etcdoperator.v0.9.4-clusterwide" csv is deleted from the "default" project after scenario
    And I obtain test data file "admin/subscription.yaml"
    When I run the :create client command with:
      | f | subscription.yaml |
    When I use the "openshift-operators" project
    And status becomes :running of 1 pods labeled:
      | name=etcd-operator-alm-owned |
    Given admin ensures "example" etcd_cluster is deleted from the "openshift-operators" project after scenario
    When I use the "default" project
    When I obtain test data file "admin/etcd-cluster.yaml"
    When I run the :create client command with:
      | f | etcd-cluster.yaml |
    Given a pod becomes ready with labels:
      | etcd_cluster=example |
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    When I replace lines in "etcd-cluster.yaml":
      | size: 3 | size: 4 |
    Then I run the :apply client command with:
      | f | etcd-cluster.yaml |
    Then the step should succeed
    And status becomes :running of 4 pods labeled:
      | app=etcd |

  # @author geliu@redhat.com
  # @case_id OCP-19982
  @admin
  @destructive
  Scenario: etcd operator automatically recover failure
    Given I switch to cluster admin pseudo user
    Given admin ensures "etcd-9.2-test" subscriptions is deleted from the "openshift-operators" project after scenario
    Given admin ensures "etcdoperator.v0.9.4-clusterwide" csv is deleted from the "default" project after scenario
    And I obtain test data file "admin/subscription.yaml"
    When I run the :create client command with:
      | f | subscription.yaml |
    When I use the "openshift-operators" project
    And status becomes :running of 1 pods labeled:
      | name=etcd-operator-alm-owned |
    Given admin ensures "example" etcd_cluster is deleted from the "openshift-operators" project after scenario
    When I use the "default" project
    When I obtain test data file "admin/etcd-cluster.yaml"
    When I run the :create client command with:
      | f | etcd-cluster.yaml |
    Given a pod becomes ready with labels:
      | etcd_cluster=example |
    And evaluation of `pod.name` is stored in the :pod1 clipboard
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    Given I ensure "<%= cb.pod1 %>" pod is deleted
    And status becomes :running of 3 pods labeled:
      | app=etcd |

  # @author geliu@redhat.com
  # @case_id OCP-19986
  @admin
  @destructive
  Scenario: upgrade an etcd cluster
    Given I switch to cluster admin pseudo user
    Given admin ensures "etcd-9.2-test" subscriptions is deleted from the "openshift-operators" project after scenario
    Given admin ensures "etcdoperator.v0.9.4-clusterwide" csv is deleted from the "default" project after scenario
    And I obtain test data file "admin/subscription.yaml"
    When I run the :create client command with:
      | f | subscription.yaml |
    When I use the "openshift-operators" project
    And status becomes :running of 1 pods labeled:
      | name=etcd-operator-alm-owned |
    Given admin ensures "example" etcd_cluster is deleted from the "openshift-operators" project after scenario
    When I use the "default" project
    When I obtain test data file "admin/etcd-cluster.yaml"
    When I run the :create client command with:
      | f | etcd-cluster.yaml |
    Given a pod becomes ready with labels:
      | etcd_cluster=example |
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    When I replace lines in "etcd-cluster.yaml":
      | 3.2.13 | 3.2.3 |
    Then I run the :apply client command with:
      | f | etcd-cluster.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | po       |
      | l        | app=etcd |
    Then the output should match:
      | etcd.version: 3.2.3 |
    """

  # @author geliu@redhat.com
  # @case_id OCP-20141
  @admin
  @destructive
  Scenario: etcd clusters could be managed in all namespaces
    Given I switch to cluster admin pseudo user
    Given admin ensures "etcd-9.2-test" subscriptions is deleted from the "openshift-operators" project after scenario
    Given admin ensures "etcdoperator.v0.9.4-clusterwide" csv is deleted from the "default" project after scenario
    And I obtain test data file "admin/subscription.yaml"
    When I run the :create client command with:
      | f | subscription.yaml |
    When I use the "openshift-operators" project
    And status becomes :running of 1 pods labeled:
      | name=etcd-operator-alm-owned |
    Given admin ensures "example" etcd_cluster is deleted from the "openshift-operators" project after scenario
    When I use the "default" project
    When I obtain test data file "admin/etcd-cluster.yaml"
    When I run the :create client command with:
      | f | etcd-cluster.yaml |
    Given a pod becomes ready with labels:
      | etcd_cluster=example |
    And status becomes :running of 3 pods labeled:
      | app=etcd |

  # @author knarra@redhat.com
  # @case_id OCP-32124
  @admin
  Scenario: etcd-memeber-pod should have working etcdctl
    Given the master version >= "4.4"
    Given I switch to cluster admin pseudo user
    When I use the "openshift-etcd" project
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    When I execute on the pod:
      | bash | -c | etcdctl |
    Then the output should contain:
      | NAME:                                             |
      | etcdctl - A simple command line client for etcd3. |
      | USAGE:                                            |
      | VERSION:                                          |
      | API VERSION:                                      |
      | COMMANDS:                                         |
      | OPTIONS:                                          |

  # @author knarra@redhat.com
  # @case_id OCP-33214
  @admin
  Scenario: Etcd metrics and defragment key metrics to monitor
    Given the master version >= "4.6"
    Given I switch to cluster admin pseudo user
    When I use the "openshift-etcd" project
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    # get sa/prometheus-k8s token
    Given I use the "openshift-monitoring" project
    When I run the :serviceaccounts_get_token admin command with:
      | serviceaccount_name | prometheus-k8s |
    Then the step should succeed
    And evaluation of `@result[:stdout]` is stored in the :sa_token clipboard
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                          |
      | pod              | prometheus-k8s-0                                                                                                                                              |
      | c                | prometheus                                                                                                                                                    |
      | oc_opts_end      |                                                                                                                                                               |
      | exec_command     | sh                                                                                                                                                            |
      | exec_command_arg | -c                                                                                                                                                            |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query?query=etcd_server_quota_backend_bytes |
    Then the step should succeed
    And the expression should be true> YAML.load(@result[:stdout])["data"]["result"][0]["value"][1] != nil
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                                  |
      | pod              | prometheus-k8s-0                                                                                                                                                      |
      | c                | prometheus                                                                                                                                                            |
      | oc_opts_end      |                                                                                                                                                                       |
      | exec_command     | sh                                                                                                                                                                    |
      | exec_command_arg | -c                                                                                                                                                                    |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query?query=etcd_mvcc_db_total_size_in_use_in_bytes |
    Then the step should succeed
    And the expression should be true> YAML.load(@result[:stdout])["data"]["result"][0]["value"][1] != nil
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                                     |
      | pod              | prometheus-k8s-0                                                                                                                                                         |
      | c                | prometheus                                                                                                                                                               |
      | oc_opts_end      |                                                                                                                                                                          |
      | exec_command     | sh                                                                                                                                                                       |
      | exec_command_arg | -c                                                                                                                                                                       |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query?query=etcd_debugging_mvcc_db_total_size_in_bytes |
    Then the step should succeed
    And the expression should be true> YAML.load(@result[:stdout])["data"]["result"][0]["value"][1] != nil

  # @author knarra@redhat.com
  # @case_id OCP-38722
  @admin
  @destructive
  Scenario: Cluster will gracefully recover if openshift-etcd namespace is removed
    Given I switch to cluster admin pseudo user
    When I use the "openshift-etcd" project
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    And status becomes :running of 3 pods labeled:
      | name=etcd-quorum-guard |
    When I run the :get admin command with:
      | resource | cm |
    Then the step should succeed
    And the output should match:
      | etcd-ca-bundle                  |
      | etcd-endpoints                  |
      | etcd-metrics-proxy-client-ca.*  |
      | etcd-metrics-proxy-serving-ca.* |
      | etcd-peer-client-ca.*           |
      | etcd-pod.*                      |
      | etcd-scripts                    |
      | etcd-serving-ca.*               |
      | restore-etcd-pod                |
   Given admin ensures "openshift-etcd" project is deleted
   And I wait up to 60 seconds for the steps to pass:
   """
   Given status becomes :running of 3 pods labeled:
     | app=etcd |
   Given  status becomes :running of 3 pods labeled:
     | name=etcd-quorum-guard |
   When I run the :get admin command with:
     | resource | cm |
   Then the step should succeed
   And the output should match:
     | etcd-ca-bundle                  |
     | etcd-endpoints                  |
     | etcd-metrics-proxy-client-ca.*  |
     | etcd-metrics-proxy-serving-ca.* |
     | etcd-peer-client-ca.*           |
     | etcd-pod.*                      |
     | etcd-scripts                    |
     | etcd-serving-ca.*               |
     | restore-etcd-pod                |
   """
  
  # @author knarra@redhat.com
  # @case_id OCP-38898
  @admin
  Scenario: Validate the functionality of the etcdctl container
    Given I switch to cluster admin pseudo user
    When I use the "openshift-etcd" project
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    When I execute on the pod:
      | bash | -c | etcdctl version |
    Then the output should contain:
      | etcdctl version |
      | API version     |
    When I execute on the pod:
      | bash | -c | etcdctl endpoint status -w table |
    Then the output should match:
      | ENDPOINT.*ID.*IS LEADER |
    When I execute on the pod:
      | bash | -c | etcdctl endpoint health |
    Then the output should contain 3 times:
      | is healthy: successfully committed proposal |

  # @author knarra@redhat.com
  # @case_id OCP-38959
  @admin
  Scenario: Provide an ability to turn off rollbackcopier
    Given I store the schedulable masters in the :masters clipboard
    Given I run commands on the nodes in the :masters clipboard after scenario:
      | sudo chattr -i /etc/kubernetes/rollbackcopy/tmp |
      | sudo rmdir /etc/kubernetes/rollbackcopy/tmp     |
    Given I switch to cluster admin pseudo user
    When I use the "openshift-etcd" project
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    When I execute on the pod:
      | bash | -c | etcdctl endpoint status -w json |
    And evaluation of `YAML.load(@result[:stdout]).find{ |e| e.dig("Status", "header", "leader") == e.dig("Status", "header", "memeber_id")}.values[0].split(":")[1].split("//")[1]` is stored in the :etcd_leader clipboard
    When I run the :get admin command with:
      | resource | node |
      | o        | custom-columns=:.metadata.name |
    Then the step should succeed
    And evaluation of `@result[:stdout].split("\n").find {|e| e.match("<%= cb.etcd_leader %>")}` is stored in the :leader_nodename clipboard
    When I run the :debug admin command with:
      | resource         | node/<%= cb.leader_nodename %>     |
      | oc_opts_end      |                                    |
      | exec_command     | chroot                             |
      | exec_command_arg | /host                              |
      | exec_command     | ls                                 |
      | exec_command     | -l                                 |
      | exec_command_arg | /etc/kubernetes                    |
    Then the step should succeed
    When I run the :debug admin command with:
      | resource         | node/<%= cb.leader_nodename %>                                    |
      | oc_opts_end      |                                                                   |
      | exec_command     | chroot                                                            |
      | exec_command_arg | /host                                                             |
      | exec_command     | cat                                                               |
      | exec_command_arg | /etc/kubernetes/rollbackcopy/currentVersion.latest/backupenv.json |
    And evaluation of `@result[:stdout]` is stored in the :snapshot_data clipboard
    Given I store the schedulable masters in the :masters clipboard
    Given I run commands on the nodes in the :masters clipboard:
      | sudo mkdir /etc/kubernetes/rollbackcopy/tmp     |
      | sudo chattr +i /etc/kubernetes/rollbackcopy/tmp |
    Then the step should succeed
    Given 3600 seconds have passed
    When I run the :debug admin command with:
      | resource         | node/<%= cb.leader_nodename %>                                    |
      | oc_opts_end      |                                                                   |
      | exec_command     | chroot                                                            |
      | exec_command_arg | /host                                                             |
      | exec_command     | cat                                                               |
      | exec_command_arg | /etc/kubernetes/rollbackcopy/currentVersion.latest/backupenv.json |
    And evaluation of `@result[:stdout]` is stored in the :snapshot_data_later clipboard
    And the expression should be true> cb.snapshot_data == cb.snapshot_data_later

  # @author knarra@redhat.com
  # @case_id OCP-39820
  @admin
  Scenario: A valid endpoint should have the URL scheme prepended
    Given I switch to cluster admin pseudo user
    When I use the "openshift-etcd-operator" project
    And status becomes :running of 1 pods labeled:
      | app=etcd-operator |
    And evaluation of `pod.name` is stored in the :pod_name clipboard
    When I run the :exec background client command with:
      | pod              | <%= cb.pod_name %>    |
      | c                | operator              |
      | exec_command     | cluster-etcd-operator |
      | exec_command_arg | rollbackcopy          |
    Then the step should succeed
    Given 60 seconds have passed
    When I terminate last background process
    And evaluation of `@result[:response]` is stored in the :etcd_endpoint clipboard
    And the expression should be true> cb.etcd_endpoint.include?("https://localhost:2379")

  # @author knarra@redhat.com
  # @case_id OCP-39812
  @admin
  Scenario: Etcd verification test on Single node cluster
    Given the cluster is Single Node Openshift
    # Store node name in clipboard
    When I run the :get admin command with:
      | resource    | node                                         |
      | o           | custom-columns=:.status.addresses[0].address |
    Then the step should succeed
    And evaluation of `@result[:stdout]` is stored in the :node_name clipboard
    Given I switch to cluster admin pseudo user
    # Validate that there is only one etcd member in openshift-etcd project
    When I use the "openshift-etcd" project
    And status becomes :running of 1 pods labeled:
      | app=etcd |
    # Find out the leader and store the value in etcd_leader clipboard
    When I execute on the pod:
      | bash | -c | etcdctl endpoint status -w json |
    And evaluation of `YAML.load(@result[:stdout]).find{ |e| e.dig("Status", "header", "leader") == e.dig("Status", "header", "memeber_id")}.values[0].split(":")[1].split("//")[1]` is stored in the :etcd_leader clipboard
    # Verified the etcd member is leader
    And the expression should be true> cb.etcd_leader == cb.node_name.strip()
    # Verify etcd operator pod is running in openshift-etcd-operator project & there is one quorum
    When I use the "openshift-etcd-operator" project
    And status becomes :running of 1 pods labeled:
      | app=etcd-operator |
    And evaluation of `pod.name` is stored in the :pod_name clipboard
    When I run the :logs client command with:
      | resource_name | pod/<%= cb.pod_name %> |
    And the output should contain:
      | etcd cluster has quorum of 1 |
   # Validate cluster operator status is normal
    Then the expression should be true> cluster_operator("etcd").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("etcd").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("etcd").condition(type: 'Available')['status'] == "True"

  # @author knarra@redhat.com
  # @case_id OCP-40615
  @admin
  Scenario: Avoid etcdInsufficientMembers alert fires incorrectly when any instance is down and not when quorum is lost
    Given I switch to cluster admin pseudo user
    When I use the "openshift-monitoring" project
    When I run the :get admin command with:
      | resource      | cm                         |
      | resource_name | prometheus-k8s-rulefiles-0 |
      | o             | yaml                       |
    Then the step should succeed
    And the output should contain:
      | - alert: etcdInsufficientMembers                                                                                                                                       |
      | expr: sum(up{job="etcd"} == bool 1 and etcd_server_has_leader{job="etcd"} == bool 1) without (instance,pod) < ((count(up{job="etcd"}) without (instance,pod) + 1) / 2) |

  # @author knarra@redhat.com
  # @case_id OCP-40059
  @admin
  Scenario: Backup script does not take static-pod-resources on a reliable way
    Given I store the schedulable masters in the :masters clipboard
    And I use the "<%= cb.masters.first.name %>" node
    When I run commands on the host:
      | ls -vd /etc/kubernetes/static-pod-resources/kube-apiserver-pod-* \| tail -1 |
    Then the step should succeed
    And evaluation of `@result[:stdout].split("/").pop().chomp()` is stored in the :static_kubeapiserver_pod clipboard
    When I run commands on the host:
      | grep -o -m 1 "/etc/kubernetes/static-pod-resources/kube-apiserver-pod-[0-9]*" "/etc/kubernetes/manifests/kube-apiserver-pod.yaml" |
    Then the step should succeed
    And evaluation of `@result[:stdout].split("/").pop().chomp()` is stored in the :latest_kubeapiserver_pod clipboard
    And the expression should be true> cb.static_kubeapiserver_pod == cb.latest_kubeapiserver_pod
    When I run commands on the host:
      | ls -vd /etc/kubernetes/static-pod-resources/kube-controller-manager-pod-* \| tail -1 |
    Then the step should succeed
    And evaluation of `@result[:stdout].split("/").pop().chomp()` is stored in the :static_kcm_pod clipboard
    When I run commands on the host:
      | grep -o -m 1 "/etc/kubernetes/static-pod-resources/kube-controller-manager-pod-[0-9]*" "/etc/kubernetes/manifests/kube-controller-manager-pod.yaml" |
    Then the step should succeed
    And evaluation of `@result[:stdout].split("/").pop().chomp()` is stored in the :latest_kcm_pod clipboard
    And the expression should be true> cb.static_kcm_pod == cb.latest_kcm_pod
    When I run commands on the host:
      | ls -vd /etc/kubernetes/static-pod-resources/kube-scheduler-pod-* \| tail -1 |
    Then the step should succeed
    And evaluation of `@result[:stdout].split("/").pop().chomp()` is stored in the :static_kubescheduler_pod clipboard
    When I run commands on the host:
      | grep -o -m 1 "/etc/kubernetes/static-pod-resources/kube-scheduler-pod-[0-9]*" "/etc/kubernetes/manifests/kube-scheduler-pod.yaml" |
    Then the step should succeed
    And evaluation of `@result[:stdout].split("/").pop().chomp()` is stored in the :latest_kubescheduler_pod clipboard
    And the expression should be true> cb.static_kubescheduler_pod == cb.latest_kubescheduler_pod

  # @author knarra@redhat.com
  # @case_id OCP-40981
  @admin
  @destructive
  Scenario: etcd should use socket option (SO_REUSEADDR) instead of wait for port release on process restart
    Given I switch to cluster admin pseudo user
    When I use the "openshift-etcd" project
    Given 3 pods become ready with labels:
      | app=etcd |
    Given evaluation of `@pods[0].name` is stored in the :etcdpod clipboard
    When I run the :rsh client command with:
      | c           | etcd              |
      | command     | -T                |
      | pod         | <%= cb.etcdpod %> |
      | command     | kill              |
      | command_arg | 1                 |
    Then the step should succeed
    Given I wait up to 80 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should match:
      | <%= cb.etcdpod %>\\s+3\/3\\s+Running\\s+1 |
    """

  # @author geliu@redhat.com
  # @case_id OCP-23802
  @admin
  @destructive
  Scenario: DR Backing up etcd in ocp 4.x	
    Given the master version >= "4.4"
    Given I switch to cluster admin pseudo user
    Given I store the schedulable masters in the :masters clipboard
    When I run the :debug admin command with:
      | resource         | node/<%= cb.masters[0].name %>   |
      | oc_opts_end      |                                  |
      | exec_command     | chroot                           |
      | exec_command_arg | /host                            |
      | exec_command     | /usr/local/bin/cluster-backup.sh |
      | exec_command_arg | /home/core/assets/backup         |
      | n                | openshift-etcd                   |
    Then the step should succeed
    And the output should contain:
      | snapshot db and kube resources are successfully saved to /home/core/assets/backup |
    When I run the :debug admin command with:
      | resource         | node/<%= cb.masters[1].name %>   |
      | oc_opts_end      |                                  |
      | exec_command     | chroot                           |
      | exec_command_arg | /host                            |
      | exec_command     | /usr/local/bin/cluster-backup.sh |
      | exec_command_arg | /home/core/assets/backup         |
      | n                | openshift-etcd                   |
    Then the step should succeed
    And the output should contain:
      | snapshot db and kube resources are successfully saved to /home/core/assets/backup |
    When I run the :debug admin command with:
      | resource         | node/<%= cb.masters[2].name %>   |
      | oc_opts_end      |                                  |
      | exec_command     | chroot                           |
      | exec_command_arg | /host                            |
      | exec_command     | /usr/local/bin/cluster-backup.sh |
      | exec_command_arg | /home/core/assets/backup         |
      | n                | openshift-etcd                   |
    Then the step should succeed
    And the output should contain:
      | snapshot db and kube resources are successfully saved to /home/core/assets/backup|

  # @author knarra@redhat.com
  # @case_id OCP-41095
  @admin
  Scenario:  Enable zap as default logger
    Given I switch to cluster admin pseudo user
    And I use the "openshift-etcd" project
    Given 3 pods become ready with labels:
      | app=etcd |
    Given evaluation of `@pods[0].name` is stored in the :podname clipboard
    When I run the :get admin command with:
      | resource | pod/<%= cb.podname %> |
      | o        | yaml                  |
    Then the step should succeed
    And the output should contain:
      | exec ionice -c2 -n0 etcd |
      | --logger=zap             |
      | --log-level=info         |
    And the output should not contain:
      | --logger=capnslog |

  # @author knarra@redhat.com
  # @case_id OCP-41291
  @admin
  @destructive
  Scenario:  Setting etcd spec.LogLevel in etcd CR
    Given the CR "etcd" named "cluster" is restored after scenario
    Given I switch to cluster admin pseudo user
    And I use the "openshift-etcd" project
    Given a pod becomes ready with labels:
      | app=etcd |
    Given evaluation of `@pods[0].name` is stored in the :podname clipboard
    When I run the :get admin command with:
      | resource | pod/<%= cb.podname %> |
      | o        | yaml                  |
    Then the step should succeed
    And the output should contain:
      | --log-level=info |
    When I run the :patch admin command with:
      | resource      | etcd                                                       |
      | resource_name | cluster                                                    |
      | p             | [{"op":"replace", "path":"/spec/logLevel", "value":Debug}] |
      | type          | json                                                       |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("etcd").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("etcd").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("etcd").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("etcd").condition(type: 'Available')['status'] == "True"
    """
    Given a pod becomes ready with labels:
      | app=etcd |
    Given evaluation of `@pods[0].name` is stored in the :podname clipboard
    When I run the :get admin command with:
      | resource | pod/<%= cb.podname %> |
      | o        | yaml                  |
    Then the step should succeed
    And the output should contain:
      | --log-level=debug |

  # @author knarra@redhat.com
  # @case_id OCP-41580
  @admin
  Scenario: sno cluster never pivots from bootstrapIP endpoint
    Given the cluster is Single Node Openshift
    Given I switch to cluster admin pseudo user
    And I use the "openshift-etcd" project
    Given a pod becomes ready with labels:
      | app=etcd |
    When I run the :get admin command with:
      | resource | ep                                         |
      | o        | custom-columns=:subsets[0].addresses[0].ip |
    Then the step should succeed
    Given evaluation of `@result[:stdout]` is stored in the :endpoint clipboard
    When I run the :get admin command with:
      | resource | cm/etcd-endpoints |
      | o        | yaml              |
    Then the step should succeed
    And the output should match:
      | data.*\\s.*<%= cb.endpoint.strip() %> |
    And the output should not match:
      | annotations.*\\s.*alpha.installer.openshift.io\/etcd-bootstrap |

  # @author knarra@redhat.com
  # @case_id OCP-41675
  @admin
  @destructive
  Scenario: etcd readinessProbe is reflective of actual readiness
    Given the CR "etcd" named "cluster" is restored after scenario
    Given I switch to cluster admin pseudo user
    And I use the "openshift-etcd" project
    Given 3 pods become ready with labels:
      | app=etcd |
    When I run the :patch admin command with:
      | resource      | etcd                                                                            |
      | resource_name | cluster                                                                         |
      | p             | {"spec": {"forceRedeploymentReason": "recovery-'\"$( date --rfc-3339=ns )\"'"}} |
      | type          | merge                                                                           |
    Then the step should succeed
    When I run the :get background client command with:
      | resource | pods           |
      | n        | openshift-etcd |
      | w        | true           |
    Then the step should succeed
    Given 60 seconds have passed
    When I terminate last background process
    And the expression should be true> @result[:response].include? ("0/3" || "1/3" || "2/3")
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("etcd").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("etcd").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("etcd").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("etcd").condition(type: 'Available')['status'] == "True"
    """

  # @author knarra@redhat.com
  # @case_id OCP-41930
  @admin
  Scenario: New etcd alerts to be added to the monitoring stack
    Given I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    Given all pods in the project are ready
    When I run the :get admin command with:
      | resource      | configmap                  |
      | resource_name | prometheus-k8s-rulefiles-0 |
      | namespace     | openshift-monitoring       |
      | o             | yaml                       |
    Then the step should succeed
    And the output should contain:
      | - alert: etcdHighFsyncDurations      |
      | - alert: etcdBackendQuotaLowSpace    |
      | - alert: etcdExcessiveDatabaseGrowth |
