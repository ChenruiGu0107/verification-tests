Feature: Scheduler predicates and priority test suites

  # @author wjiang@redhat.com
  # @case_id OCP-12479
  @admin
  @destructive
  Scenario: [origin_runtime_646] Fixed predicates rules testing - PodFitsPorts
    Given I have a project
    Given I store the schedulable workers in the clipboard
    Given label "multihostports=true" is added to the "<%=node.name%>" node
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": "multihostports=true"}}}|
    Then the step should succeed
    Given I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | hostaccess          |
      | user_name | <%=user(0).name%>   |
    Given I obtain test data file "scheduler/pod_with_ports.json"
    When I run the :create client command with:
      | f | pod_with_ports.json |
    Then the step should succeed
    Given I obtain test data file "scheduler/pod_with_ports.json"
    When I run the :create client command with:
      | f | pod_with_ports.json |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    And I run the :describe client command with:
      | resource | pods |
    And the output should match:
      | FailedScheduling.*(PodFitsPorts\|didn't have free ports for the requested pod ports)|
    """

  # @author wjiang@redhat.com
  # @case_id OCP-12482
  Scenario: [origin_runtime_646] Fixed predicates rules testing - PodFitsResources
    Given I have a project
    Given I obtain test data file "scheduler/pod_with_resources.json"
    When I run the :create client command with:
      | f | pod_with_resources.json |
    And the step should succeed
    When I run the :describe client command with:
      | resource | pods |
    And the output should match:
      | (PodFitsResrouces\|Insufficient) |

  # @author wjiang@redhat.com
  @admin
  @destructive
  Scenario Outline: [infrastructure_public_295] Scheduler predicate should cap xxxVolumeCount for diff cloudprovider
    Given the master version >= "3.10"
    Given the expression should be true> env.iaas[:type] == "<cloudprovider>"
    Given evaluation of `env.master_hosts` is stored in the :masters clipboard
    Given I obtain test data file "scheduler/scheduler-maxvol.json"
    Given I run commands on all masters:
      | curl -o /etc/origin/master/scheduler-maxvol.json scheduler-maxvol.json |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    KubernetesMasterConfig:
      schedulerConfigFile: /etc/origin/master/scheduler-maxvol.json
    """
    Given the "/etc/origin/master/master.env" file is restored on all hosts in the "masters" clipboard after scenario
    Given I run commands on all masters:
      | echo "KUBE_MAX_PD_VOLS=1" >> /etc/origin/master/master.env |
    And the master service is restarted on all master nodes
    Given I have a project
    Given I wait for the "default" serviceaccount to appear
    When I run oc create over ERB test file: scheduler/pod_with_multivols.yaml
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    And I run the :describe client command with:
      | resource | pods                     |
      | name     | pod-multivolsexceedlimit |
    And the output should match:
      | FailedScheduling.*(MaxVolumeCound\|exceed max volume count) |
    """
    Examples:
      | cloudprovider |
      | aws           | # @case_id OCP-11254
      | gce           | # @case_id OCP-11571
      | azure         | # @case_id OCP-20753

  # @author wjiang@redhat.com
  # @case_id OCP-11256
  @admin
  @destructive
  Scenario: Scheduler should use "allocatable" for pod scheduling
    Given I have a project
    Given I store the schedulable workers in the :nodes clipboard
    And node schedulable status should be restored after scenario
    # make sure only one node can be scheduled for testing pod,
    # since this scenario need calculate the requests for specific node
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    # calculate the memory leave to new pods
    Given evaluation of `cb.nodes[0].remaining_resources[:memory]` is stored in the :pod_request_memory clipboard
    Given I obtain test data file "scheduler/pod_with_more_than_remanent_memory.json"
    When I run oc create over "pod_with_more_than_remanent_memory.json" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.pod_request_memory + 1%> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pods |
    And the output should match:
      | FailedScheduling.*(PodFitsResources\|Insufficient memory) |
    """
    Given I obtain test data file "scheduler/pod_with_remanent_memory.json"
    When I run oc create over "pod_with_remanent_memory.json" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.pod_request_memory %> |
    Then the step should succeed
    And the pod named "pod-with-remanent-memory" becomes ready
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author knarra@redhat.com
  # @case_id OCP-24240
  @admin
  @destructive
  Scenario: Configure master nodes schedulable
    Given the master version >= "4.1"
    Given the "cluster" scheduler CR is restored after scenario
    When I run the :patch admin command with:
      | resource      | Scheduler                            |
      | resource_name | cluster                              |
      | p             | {"spec":{"mastersSchedulable":true}} |
      | type          | merge                                |
    Given I have a project
    Given I obtain test data file "scheduler/pod_ocp24240.yaml"
    When I run the :create client command with:
      | f | pod_ocp24240.yaml |
    Then the step should succeed
    And the pod named "empty-operator-pod" becomes ready
    Then the expression should be true> node(pod.node_name).is_master?

  # @author knarra@redhat.com
  # @case_id OCP-19893
  @admin
  @destructive
  Scenario: Preemptor should reschedule once enough room is available even preemptor has nominatedNodeName
    Given the master version >= "4.1"
    Given admin ensures "priorityl" priority_class is deleted after scenario
    Given admin ensures "prioritym" priority_class is deleted after scenario
    # Creation of priority classes
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run the :create admin command with:
      | f | priorityl.yaml |
    Then the step should succeed
    And the output should contain "priorityclass.scheduling.k8s.io/priorityl created"
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run oc create as admin over "priorityl.yaml" replacing paths:
      | ["metadata"]["name"] | prioritym |
      | ["value"]            | 99        |
    Then the step should succeed
    And the output should contain "priorityclass.scheduling.k8s.io/prioritym created"
    # Mark two nodes as unschedulable
    Given I store the schedulable workers in the :nodes clipboard
    And node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    # Test runs
    Given I have a project
    And evaluation of `cb.nodes[0].remaining_resources[:memory]` is stored in the :node_memory clipboard
    And evaluation of `cb.nodes[0].remaining_resources[:memory]/2` is stored in the :node_allocate_memory clipboard
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | env=test |
    And evaluation of `pod.name` is stored in the :podone clipboard
    Then the expression should be true> pod.node_name == cb.nodes[0].name
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
      | ["metadata"]["labels"]                                       | env: test1                     |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | env=test1 |
    And evaluation of `pod.name` is stored in the :podtwo clipboard
    Then the expression should be true> pod.node_name == cb.nodes[0].name
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["metadata"]["generateName"]                                 | prioritym             |
      | ["metadata"]["labels"]                                       | env: testm            |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_memory %> |
      | ["spec"]["priorityClassName"]                                | prioritym             |
    Then the step should succeed
    Given status becomes :pending of 1 pods labeled:
      | env=testm |
    And evaluation of `pod.name` is stored in the :podm clipboard
    Then the expression should be true> pod.nominated_node_name == cb.nodes[0].name
    And the pod named "<%= cb.podone %>" becomes terminating
    And the pod named "<%= cb.podtwo %>" becomes terminating
    When I run the :delete client command with:
      | object_type       | pod              |
      | object_name_or_id | <%= cb.podone %> |
      | grace_period      | 0                |
      | force             | true             |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pod              |
      | object_name_or_id | <%= cb.podtwo %> |
      | grace_period      | 0                |
      | force             | true             |
    Then the step should succeed
    And the pod named "<%= cb.podm %>" status becomes :running
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author knarra@redhat.com
  # @case_id OCP-26842
  @admin
  @destructive
  Scenario: Deploy a custom scheduler
    Given the master version >= "4.1"
    Given I store master major version in the clipboard
    Given the "system:kube-scheduler" clusterole is recreated after scenario
    Given admin ensures "my-scheduler" deployment is deleted from the "kube-system" project after scenario
    Given admin ensures "my-scheduler" service_account is deleted from the "kube-system" project after scenario
    Given admin ensures "my-scheduler-as-kube-scheduler" clusterrolebinding is deleted after scenario
    Given I obtain test data file "customscheduler/my-scheduler-<%= cb.master_version %>.yaml"
    When I run the :create admin command with:
      | f | my-scheduler-<%= cb.master_version %>.yaml |
    Then the step should succeed
    And the output should contain "deployment.apps/my-scheduler created"
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource       | pod                 |
      | all_namespaces | true                |
      | l              | component=scheduler |
    Then the step should succeed
    And the output should contain "kube-system"
    """
    When I run the :patch admin command with:
      | resource      | clusterrole                                                               |
      | resource_name | system:kube-scheduler                                                     |
      | p             | [{"op":"add", "path":"/rules/2/resourceNames/1", "value":"my-scheduler"}] |
      | type          | json                                                                      |
    Then the step should succeed
    Given I have a project
    Given I obtain test data file "customscheduler/pod-noscheduler.yaml"
    When I run the :create client command with:
      | f | pod-noscheduler.yaml |
    And the pod named "no-annotation" becomes ready
    When I run the :describe client command with:
      | resource | pod           |
      | name     | no-annotation |
    Then the output should contain "default-scheduler"
    Given I obtain test data file "customscheduler/pod-noscheduler.yaml"
    When I run oc create over "pod-noscheduler.yaml" replacing paths:
      | ["metadata"]["name"]      | annotation-default-scheduler |
      | ["spec"]["schedulerName"] | default-scheduler            |
    And the pod named "annotation-default-scheduler" becomes ready
    When I run the :describe client command with:
      | resource | pod                          |
      | name     | annotation-default-scheduler |
    Then the output should contain "default-scheduler"
    Given I obtain test data file "customscheduler/pod-noscheduler.yaml"
    When I run oc create over "pod-noscheduler.yaml" replacing paths:
      | ["metadata"]["name"]      | annotation-second-scheduler |
      | ["spec"]["schedulerName"] | my-scheduler                |
    And the pod named "annotation-second-scheduler" becomes ready
    When I run the :describe client command with:
      | resource | pod                         |
      | name     | annotation-second-scheduler |
    Then the output should contain "my-scheduler"

  # @author knarra@redhat.com
  # @case_id OCP-19895
  @admin
  @destructive
  Scenario: Preemptor will choose the node with lowest number pods which violated PDBs
    Given the master version >= "4.1"
    Given admin ensures "priorityl" priority_class is deleted after scenario
    Given admin ensures "prioritym" priority_class is deleted after scenario
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run the :create admin command with:
      | f | priorityl.yaml |
    Then the step should succeed
    And the output should contain "priorityclass.scheduling.k8s.io/priorityl created"
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run oc create as admin over "priorityl.yaml" replacing paths:
      | ["metadata"]["name"] | prioritym |
      | ["value"]            | 99        |
    Then the step should succeed
    And the output should contain "priorityclass.scheduling.k8s.io/prioritym created"
    Given I store the schedulable workers in the :nodes clipboard
    And node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    # Test runs
    Given I have a project
    And evaluation of `cb.nodes[0].remaining_resources[:memory]/2` is stored in the :node_allocate_memory clipboard
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
    Then the step should succeed
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
    Then the step should succeed
    Given status becomes :running of 2 pods labeled:
      | env=test |
    When I run the :create_poddisruptionbudget client command with:
      | name          | pdbocp19895 |
      | min_available | 100%        |
      | selector      | env=test    |
    Then the step should succeed
     When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[1].name %> |
    Then the step should succeed
    And evaluation of `cb.nodes[1].remaining_resources[:memory]` is stored in the :nodeone_memory clipboard
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.nodeone_memory %> |
      | ["spec"]["containers"][0]["resources"]["requests"]["cpu"]    | 1m                       |
      | ["metadata"]["labels"]                                       | env: test1               |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | env=test1 |
    And evaluation of `pod.name` is stored in the :podthree clipboard
    And evaluation of `pod.node_name` is stored in the :nodethree clipboard
    When I run the :create_poddisruptionbudget client command with:
      | name          | pdb1ocp19895 |
      | min_available | 100%         |
      | selector      | env=test1    |
    Then the step should succeed
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["metadata"]["generateName"]                                 | prioritym                |
      | ["metadata"]["labels"]                                       | env: testm               |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.nodeone_memory %> |
      | ["spec"]["containers"][0]["resources"]["requests"]["cpu"]    | 1m                       |
      | ["spec"]["priorityClassName"]                                | prioritym                |
    Then the step should succeed
    Given status becomes :pending of 1 pods labeled:
      | env=testm |
    And evaluation of `pod.name` is stored in the :podm clipboard
    Then the expression should be true> pod.nominated_node_name == cb.nodethree
    And the pod named "<%= cb.podthree %>" becomes terminating
    Given the pod named "<%= cb.podm %>" status becomes :running
    Then the expression should be true> pod.node_name == cb.nodethree

  # @author knarra@redhat.com
  # @case_id OCP-19892
  @admin
  @destructive
  Scenario: Higher priority pod should preempt the resource even when lower priority pod has nominated node name
    Given the master version >= "4.1"
    Given admin ensures "priorityl" priority_class is deleted after scenario
    Given admin ensures "prioritym" priority_class is deleted after scenario
    Given admin ensures "priorityh" priority_class is deleted after scenario
    # Creation of priority classes
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run the :create admin command with:
      | f | priorityl.yaml |
    Then the step should succeed
    And the output should contain "priorityclass.scheduling.k8s.io/priorityl created"
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run oc create as admin over "priorityl.yaml" replacing paths:
      | ["metadata"]["name"] | prioritym |
      | ["value"]            | 99        |
    Then the step should succeed
    And the output should contain "priorityclass.scheduling.k8s.io/prioritym created"
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run oc create as admin over "priorityl.yaml" replacing paths:
      | ["metadata"]["name"] | priorityh |
      | ["value"]            | 100       |
    Then the step should succeed
    And the output should contain "priorityclass.scheduling.k8s.io/priorityh created"
    Given I store the schedulable workers in the :nodes clipboard
    And node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    # Test runs
    Given I have a project
    And evaluation of `cb.nodes[0].remaining_resources[:memory]` is stored in the :node_allocate_memory clipboard
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | env=test |
    And evaluation of `pod.name` is stored in the :podl clipboard
    Then the expression should be true> pod.node_name == cb.nodes[0].name
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["metadata"]["generateName"]                                 | prioritym                      |
      | ["metadata"]["labels"]                                       | env: testm                     |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
      | ["spec"]["priorityClassName"]                                | prioritym                      |
    Then the step should succeed
    Given status becomes :pending of 1 pods labeled:
      | env=testm |
    And evaluation of `pod.name` is stored in the :podm clipboard
    Then the expression should be true> pod.nominated_node_name == cb.nodes[0].name
    And the pod named "<%= cb.podl %>" becomes terminating
    Given a pod becomes ready with labels:
      | env=testm |
    Then the expression should be true> pod.node_name == cb.nodes[0].name
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["metadata"]["generateName"]                                 | priorityh                      |
      | ["metadata"]["labels"]                                       | env: testh                     |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
      | ["spec"]["priorityClassName"]                                | priorityh                      |
    Then the step should succeed
    Given status becomes :pending of 1 pods labeled:
      | env=testh |
    And evaluation of `pod.name` is stored in the :podh clipboard
    Then the expression should be true> pod.nominated_node_name == cb.nodes[0].name
    And the pod named "<%= cb.podm %>" becomes terminating
    Given a pod becomes ready with labels:
      | env=testh |
    Then the expression should be true> pod.node_name == cb.nodes[0].name

  # @author knarra@redhat.com
  # @case_id OCP-36111
  @admin
  @destructive
  Scenario: Priority/Preempting - Validate pods with higher priority having preemption policy set to never are placed ahead of lower-priority pods in the scheduling queue
    Given admin ensures "priorityl" priority_class is deleted after scenario
    Given admin ensures "priorityh" priority_class is deleted after scenario
    # Creation of priority classes
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run the :create admin command with:
      | f | priorityl.yaml |
    Then the step should succeed
    Given I obtain test data file "scheduler/priority-preemptionscheduling/non_preempting_priority.yaml"
    When I run the :create admin command with:
      | f | non_preempting_priority.yaml |
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    # Test runs
    Given I have a project
    And evaluation of `cb.nodes[0].remaining_resources[:memory]` is stored in the :node_allocate_memory clipboard
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
    Then the step should succeed
    And status becomes :pending of 1 pods labeled:
      | env=test |
    And evaluation of `pod.name` is stored in the :podl clipboard
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["metadata"]["generateName"]                                 | priorityh                      |
      | ["metadata"]["labels"]                                       | env: testh                     |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
      | ["spec"]["priorityClassName"]                                | priorityh                      |
    Then the step should succeed
    Given status becomes :pending of 1 pods labeled:
      | env=testh |
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | env=testh |
    And the pod named "<%= cb.podl %>" status becomes :pending

  # @author knarra@redhat.com
  # @case_id OCP-36110
  @admin
  @destructive
  Scenario: Priority/Preempting - validate higher priority pods will preempt pods with lowerprirority when preemtionPolicy is set to Never on them
    Given admin ensures "prioritym" priority_class is deleted after scenario
    Given admin ensures "priorityh" priority_class is deleted after scenario
    # Creation of priority classes
    Given I obtain test data file "scheduler/priority-preemptionscheduling/non_preempting_priority.yaml"
    When I run oc create as admin over "non_preempting_priority.yaml" replacing paths:
      | ["metadata"]["name"] | prioritym |
      | ["value"]            | 99        |
    Then the step should succeed
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run oc create as admin over "priorityl.yaml" replacing paths:
      | ["metadata"]["name"] | priorityh |
      | ["value"]            | 100       |
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    # Test runs
    Given I have a project
    And evaluation of `cb.nodes[0].remaining_resources[:memory]` is stored in the :node_allocate_memory clipboard
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["metadata"]["generateName"]                                 | prioritym                      |
      | ["metadata"]["labels"]                                       | env: testm                     |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
      | ["spec"]["priorityClassName"]                                | prioritym                      |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | env=testm |
    And evaluation of `pod.name` is stored in the :podm clipboard
    Then the expression should be true> pod.node_name == cb.nodes[0].name
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["metadata"]["generateName"]                                 | priorityh                      |
      | ["metadata"]["labels"]                                       | env: testh                     |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
      | ["spec"]["priorityClassName"]                                | priorityh                      |
    Then the step should succeed
    Given status becomes :pending of 1 pods labeled:
      | env=testh |
    And evaluation of `pod.name` is stored in the :podh clipboard
    And the pod named "<%= cb.podm %>" becomes terminating
    And a pod becomes ready with labels:
      | env=testh |

  # @author knarra@redhat.com
  # @case_id OCP-36108
  @admin
  @destructive
  Scenario: Priority/Preempting - validate pods with preemptionPolicy set to Never will not preempt any other pods which are running
    Given admin ensures "priorityl" priority_class is deleted after scenario
    Given admin ensures "prioritym" priority_class is deleted after scenario
    Given admin ensures "priorityh" priority_class is deleted after scenario
    # Creation of priority classes
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run the :create admin command with:
      | f | priorityl.yaml |
    Then the step should succeed
    Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
    When I run oc create as admin over "priorityl.yaml" replacing paths:
      | ["metadata"]["name"] | prioritym |
      | ["value"]            | 99        |
    Then the step should succeed
    Given I obtain test data file "scheduler/priority-preemptionscheduling/non_preempting_priority.yaml"
    When I run the :create admin command with:
      | f | non_preempting_priority.yaml |
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    # Test runs
    Given I have a project
    And evaluation of `cb.nodes[0].remaining_resources[:memory]` is stored in the :node_allocate_memory clipboard
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | env=test |
    And evaluation of `pod.name` is stored in the :podl clipboard
    Then the expression should be true> pod.node_name == cb.nodes[0].name
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["metadata"]["generateName"]                                 | prioritym                      |
      | ["metadata"]["labels"]                                       | env: testm                     |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
      | ["spec"]["priorityClassName"]                                | prioritym                      |
    Then the step should succeed
    Given status becomes :pending of 1 pods labeled:
      | env=testm |
    And evaluation of `pod.name` is stored in the :podm clipboard
    Then the expression should be true> pod.nominated_node_name == cb.nodes[0].name
    And the pod named "<%= cb.podl %>" becomes terminating
    Given a pod becomes ready with labels:
      | env=testm |
    Then the expression should be true> pod.node_name == cb.nodes[0].name
    Given I obtain test data file "scheduler/priority-preemptionscheduling/podl.yaml"
    When I run oc create over "podl.yaml" replacing paths:
      | ["metadata"]["generateName"]                                 | priorityh                      |
      | ["metadata"]["labels"]                                       | env: testh                     |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_allocate_memory %> |
      | ["spec"]["priorityClassName"]                                | priorityh                      |
    Then the step should succeed
    Given status becomes :pending of 1 pods labeled:
      | env=testh |
    And evaluation of `pod.name` is stored in the :podh clipboard
    Then the expression should be true> pod.nominated_node_name == nil
    Given I ensure "<%= cb.podm %>" pod is deleted
    And I wait up to 80 seconds for the steps to pass:
    """
    Given status becomes :running of 1 pods labeled:
      | env=testh |
    """
