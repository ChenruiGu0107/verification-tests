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
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_ports.json
    Then the step should succeed
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_ports.json
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
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_resources.json
    And the step should succeed
    When I run the :describe client command with:
      | resource | pods |
    And the output should match:
      | (PodFitsResrouces\|Insufficient) |

  # @author wjiang@redhat.com
  # @case_id OCP-14583
  @admin
  Scenario: When custom scheduler name is supplied, the pod is scheduled using the custom scheduler
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/multiple-schedulers/custom-scheduler.yaml |
    Then the step should succeed
    Given the pod named "custom-scheduler" becomes present
    Given I store the schedulable workers in the clipboard
    When I run oc create as admin over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/multiple-schedulers/binding.json 
    And the step should succeed
    Given the pod named "custom-scheduler" becomes ready
    Then the expression should be true> pod.node_name == node.name

  # @author wjiang@redhat.com
  @admin
  @destructive
  Scenario Outline: [infrastructure_public_295] Scheduler predicate should cap xxxVolumeCount for diff cloudprovider
    Given the master version >= "3.10"
    Given the expression should be true> env.iaas[:type] == "<cloudprovider>"
    Given evaluation of `env.master_hosts` is stored in the :masters clipboard
    Given I run commands on all masters:
      | curl -o /etc/origin/master/scheduler-maxvol.json https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/scheduler-maxvol.json |
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
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_multivols.yaml
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    And I run the :describe client command with:
      | resource  | pods                      |
      | name      | pod-multivolsexceedlimit  |
    And the output should match:
      | FailedScheduling.*(MaxVolumeCound\|exceed max volume count)|
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
    Given environment has at least 2 schedulable nodes
    Given I store the schedulable workers in the :nodes clipboard
    And the expression should be true> cb.nodes.delete(node)
    Given the taints of the nodes in the clipboard are restored after scenario
    # make sure only one node can be scheduled for testing pod,
    # since this scenario need calculate the requests for specific node
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %>  |
      | key_val   | additional=true:NoSchedule                              |
    Then the step should succeed
    # calculate the memory leave to new pods
    Given evaluation of `node.remaining_resources[:memory]` is stored in the :pod_request_memory clipboard
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_more_than_remanent_memory.json
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pods |
    And the output should match:
      | FailedScheduling.*(PodFitsResources\|Insufficient memory) |
    """
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_remanent_memory.json
    Then the step should succeed
    And the pod named "pod-with-remanent-memory" becomes ready
    Then the expression should be true> pod.node_name == node.name

  # @author knarra@redhat.com
  # @case_id OCP-24240
  @admin
  @destructive
  Scenario: Configure master nodes schedulable
    Given the master version >= "4.1"
    Given I set all worker nodes status to unschedulable
    Given node schedulable status should be restored after scenario
    Given the "cluster" scheduler CR is restored after scenario
    When I run the :patch admin command with:
      | resource      | Scheduler                                     |
      | resource_name | cluster                                       |
      | p             | {"spec":{"mastersSchedulable":true}}          |
      | type          | merge                                         |
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_ocp24240.yaml |
    Then the step should succeed
    And the pod named "empty-operator-pod" becomes ready
    Then the expression should be true> node(pod.node_name).is_master?
