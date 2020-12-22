Feature: Testing Scheduler Operator related scenarios
	
  # @author knarra@redhat.com
  # @case_id OCP-12459
  @admin
  @destructive
  Scenario: Fixed predicates rules testing Hostname for 4.x
    Given the master version >= "4.1"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the CR "Scheduler" named "cluster" is restored after scenario
    Given I obtain test data file "scheduler/policy_hostname.json"
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                |
      | from_file | policy.cfg=policy_hostname.json |
      | namespace | openshift-config                |
      Then the step should succeed
    When I run the :patch admin command with:
      | resource      | Scheduler                                       |
      | resource_name | cluster                                         |
      | p             | {"spec":{"policy":{"name":"scheduler-policy"}}} |
      | type          | merge                                           |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given I have a project
    Given I store the schedulable workers in the :nodes clipboard
    Given I obtain test data file "scheduler/pod_with_nodename.json"
    When I run oc create over "pod_with_nodename.json" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.nodes[0].name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=nodename-pod |
    And the expression should be true> pod.node_name == cb.nodes[0].name

  # @author knarra@redhat.com
  # @case_id OCP-12496
  @admin
  @destructive
  Scenario: Fixed priority rules testing ServiceSpreadingPriority for 4.x
    Given the master version >= "4.1"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the CR "Scheduler" named "cluster" is restored after scenario
    Given I obtain test data file "scheduler/policy_servicespreadingpriority.json"
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                |
      | from_file | policy.cfg=policy_servicespreadingpriority.json |
      | namespace | openshift-config                                |
    Then the step should succeed
    Given as admin I successfully merge patch resource "Scheduler/cluster" with:
      | {"spec":{"policy":{"name":"scheduler-policy"}}} |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given I have a project
    Given I store the schedulable workers in the :nodes clipboard
    Given I obtain test data file "scheduler/list_for_servicespreading.json"
    When I run the :create client command with:
      | f | list_for_servicespreading.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :get client command with:
      | resource | pods |
      | o        | wide |
    Then the step should succeed
    And I repeat the following steps for each :node in cb.nodes:
    """
    And the output should contain "#{cb.node.name}"
    """


  # @author knarra@redhat.com
  # @case_id OCP-12518
  @admin
  @destructive
  Scenario: Set scheduler policy with invalid json file for 4.x
    Given the master version >= "4.1"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the CR "Scheduler" named "cluster" is restored after scenario

    When I run the :patch admin command with:
      | resource      | scheduler                        |
      | resource_name | cluster                          |
      | p             | {"spec":{"policy":{"name":" "}}} |
      | type          | merge                            |
    Then the step should fail
    And the output should match "The Scheduler "cluster" is invalid"

    When I run the :patch admin command with:
      | resource      | scheduler                                       |
      | resource_name | cluster                                         |
      | p             | {"spec":{"policy":{"name":"scheduler-policy"}}} |
      | type          | merge                                           |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given I obtain test data file "scheduler/policy_empty.json"
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy             |
      | from_file | policy.cfg=policy_empty.json |
      | namespace | openshift-config             |
    Then the step should succeed

    When I run the :patch admin command with:
      | resource      | scheduler                                       |
      | resource_name | cluster                                         |
      | p             | {"spec":{"policy":{"name":"scheduler-policy"}}} |
      | type          | merge                                           |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """

    Given I have a project
    When I run the :create_deploymentconfig client command with:
      | image | quay.io/openshifttest/hello-openshift@sha256:aaea76ff622d2f8bcb32e538e7b3cd0ef6d291953f3e7c9f556c1ba5baf47e2e |
      | name  | openshift1                                                                                                    |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | deploymentconfig=openshift1 |

  # @author knarra@redhat.com
  # @case_id OCP-12489
  @admin
  @destructive
  Scenario: Fixed priority rules testing - LeastRequestedPriority
    Given the master version >= "4.1"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the CR "Scheduler" named "cluster" is restored after scenario

    Given I obtain test data file "scheduler/policy_leastrequestedpriority.json"
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                              |
      | from_file | policy.cfg=policy_leastrequestedpriority.json |
      | namespace | openshift-config                              |
    Then the step should succeed

    Given as admin I successfully merge patch resource "Scheduler/cluster" with:
      | {"spec":{"policy":{"name":"scheduler-policy"}}} |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    # Mark one node as unschedulable
    Given I store the schedulable workers in the :nodes clipboard
    Given node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    Given I have a project
    And evaluation of `cb.nodes[0].remaining_resources[:memory]` is stored in the :node_memory clipboard
    Given I obtain test data file "scheduler/pod_ocp12489.yaml"
    When I run oc create over "pod_ocp12489.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_memory %> |
    Then the step should succeed
    Given the pod named "pod-request" status becomes :running within 60 seconds
    And evaluation of `pod.node_name` is stored in the :nodename clipboard
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[1].name %> |
    Then the step should succeed
    Given I obtain test data file "scheduler/pod_ocp12489.yaml"
    When I run oc create over "pod_ocp12489.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-request1 |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | 200Mi        |
    Then the step should succeed
    And the pod named "pod-request1" becomes ready
    And the expression should be true> pod.node_name != cb.nodename

  # @author yinzhou@redhat.com
  @admin
  @destructive
  Scenario Outline: Schedule pods within the same service for 4.x
    Given the master version >= "4.1"
    Given admin ensures "my-scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the CR "Scheduler" named "cluster" is restored after scenario
    Given I obtain test data file "scheduler/<filename>"
    When I run the :create_configmap admin command with:
      | name      | my-scheduler-policy   |
      | from_file | policy.cfg=<filename> |
      | namespace | openshift-config      |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | scheduler                                          |
      | resource_name | cluster                                            |
      | p             | {"spec":{"policy":{"name":"my-scheduler-policy"}}} |
      | type          | merge                                              |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given I store the schedulable workers in the :nodes clipboard
    Given node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[1].name %> |
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
    And label "usertestregion=r1" is added to the "<%= cb.nodes[0].name %>" node
    And label "usertestregion=r2" is added to the "<%= cb.nodes[1].name %>" node
    And label "usertestzone=z21" is added to the "<%= cb.nodes[1].name %>" node
    Given I have a project
    When I run the :create_deploymentconfig client command with:
      | image | quay.io/openshifttest/hello-openshift@sha256:aaea76ff622d2f8bcb32e538e7b3cd0ef6d291953f3e7c9f556c1ba5baf47e2e |
      | name  | hello-openshift                                                                                               |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deploymentconfig=hello-openshift |
    Then the expression should be true> pod.node_name == <nodename>
    Examples:
      | filename                         | nodename         |
      | policy-label-presence-false.json | cb.nodes[0].name | # @case_id OCP-11100
      | policy-label-presence-true.json  | cb.nodes[1].name | # @case_id OCP-11465

  # @author knarra@redhat.com
  @admin
  @destructive
  Scenario Outline: Schedule pods within the same service based on nested levels
    Given the master version >= "4.4"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the CR "Scheduler" named "cluster" is restored after scenario
    Given I store the schedulable workers in the :nodes clipboard
    Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
    Given node schedulable status should be restored after scenario
    Given I obtain test data file "scheduler/<filename>"
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                                |
      | from_file | policy.cfg=<filename> |
      | namespace | openshift-config                                                                |
    Then the step should succeed
    Given as admin I successfully merge patch resource "Scheduler/cluster" with:
      | {"spec":{"policy":{"name":"scheduler-policy"}}} |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[1].name %> |
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And label "ocpaffrack=a111" is added to the "<%= cb.nodes[0].name %>" node
    And label "ocpaffregion=r1" is added to the "<%= cb.nodes[0].name %>" node
    And label "ocpaffzone=z11" is added to the "<%= cb.nodes[0].name %>" node
    And label "ocpaffrack=a211" is added to the "<%= cb.nodes[1].name %>" node
    And label "ocpaffregion=r2" is added to the "<%= cb.nodes[1].name %>" node
    And label "ocpaffzone=z21" is added to the "<%= cb.nodes[1].name %>" node
    Given I have a project
    Given I obtain test data file "scheduler/<podfilename>"
    When I process and create "<podfilename>"
    Then the step should succeed
    Given status becomes :running of 3 pods labeled:
      | deploymentconfig=database |
    Given evaluation of `@pods[0].node_name` is stored in the :nodename clipboard
    When I run the :get client command with:
      | resource | pod                       |
      | l        | deploymentconfig=database |
      | o        | wide                      |
    Then the step should succeed
    And the output should contain 3 times:
       | <%= cb.nodename %> |
    Examples:
      | filename                          | podfilename       |
      | policy_aff_aff_antiaffi.json      | pod_ocp11889.json | # @case_id OCP-11889
      | policy_aff_antiaffi_antiaffi.json | pod_ocp12191.json | # @case_id OCP-12191

  # @author knarra@redhat.com
  # @case_id OCP-12523
  @admin
  @destructive
  Scenario: Tune the node priority by the weight attribute
    Given the master version >= "4.1"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the CR "Scheduler" named "cluster" is restored after scenario
    Given I obtain test data file "scheduler/policy_weightattribute.json"
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                       |
      | from_file | policy.cfg=policy_weightattribute.json |
      | namespace | openshift-config                       |
    Then the step should succeed

    Given as admin I successfully merge patch resource "Scheduler/cluster" with:
      | {"spec":{"policy":{"name":"scheduler-policy"}}} |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given I store the schedulable workers in the :nodes clipboard
    Given node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[1].name %> |
    Then the step should succeed
    # Test for ServiceSpreadingPriority weight attribute
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "scheduler/list_for_servicespreading.json"
    When I run oc create over "list_for_servicespreading.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given I successfully patch resource "replicationcontroller/service-spreading" with:
      | {"spec":{"replicas":2}} |
    And I wait until number of replicas match "2" for replicationController "service-spreading"
    Given status becomes :running of 2 pods labeled:
      | name=service-spreading |
    And evaluation of `@pods[0].node_name` is stored in the :nodename clipboard
    And evaluation of `@pods[1].node_name` is stored in the :podnodename clipboard
    Then the expression should be true> cb.podnodename != cb.nodename
    # Edit weight attribute for leastrequestpriority
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project
    Given I obtain test data file "scheduler/policy_weightattributeone.json"
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                          |
      | from_file | policy.cfg=policy_weightattributeone.json |
      | namespace | openshift-config                          |
    Then the step should succeed

    Given as admin I successfully merge patch resource "Scheduler/cluster" with:
      | {"spec":{"policy":{"name":"scheduler-policy"}}} |
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    # Test for LeastRequestedPriority weight attribute
    Given I use the "<%= cb.proj_name%>" project
    When I run the :oadm_cordon_node admin command with:
      | node_name | <%= cb.nodes[1].name %> |
    Then the step should succeed
    And evaluation of `cb.nodes[0].remaining_resources[:memory]` is stored in the :node_memory clipboard
    Given I obtain test data file "scheduler/pod_ocp12489.yaml"
    When I run oc create over "pod_ocp12489.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_memory %> |
    Then the step should succeed
    Given the pod named "pod-request" status becomes :running within 60 seconds
    And evaluation of `pod.node_name` is stored in the :nodename clipboard
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[1].name %> |
    Then the step should succeed
    Given I obtain test data file "scheduler/pod_ocp12489.yaml"
    When I run oc create over "pod_ocp12489.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-request5 |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | 200Mi        |
    Then the step should succeed
    And the pod named "pod-request5" becomes ready
    And the expression should be true> pod.node_name != cb.nodename

  # @author knarra@redhat.com
  @admin
  @destructive
  Scenario Outline: Schedule pods within the same service based on nested levels < OCP4.3
    Given the master version <= "4.3"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the CR "Scheduler" named "cluster" is restored after scenario
    Given I store the schedulable workers in the :nodes clipboard
    Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
    Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
    Given node schedulable status should be restored after scenario
    Given I obtain test data file "scheduler/<filename>"
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy      |
      | from_file | policy.cfg=<filename> |
      | namespace | openshift-config      |
    Then the step should succeed
    Given as admin I successfully merge patch resource "Scheduler/cluster" with:
      | {"spec":{"policy":{"name":"scheduler-policy"}}} |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[1].name %> |
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And label "ocpaffrack=a111" is added to the "<%= cb.nodes[0].name %>" node
    And label "ocpaffregion=r1" is added to the "<%= cb.nodes[0].name %>" node
    And label "ocpaffzone=z11" is added to the "<%= cb.nodes[0].name %>" node
    And label "ocpaffrack=a211" is added to the "<%= cb.nodes[1].name %>" node
    And label "ocpaffregion=r2" is added to the "<%= cb.nodes[1].name %>" node
    And label "ocpaffzone=z21" is added to the "<%= cb.nodes[1].name %>" node
    Given I have a project
    Given I obtain test data file "scheduler/<podfilename>"
    When I process and create "<podfilename>"
    Then the step should succeed
    Given status becomes :running of 3 pods labeled:
      | deploymentconfig=database |
    Given evaluation of `@pods[0].node_name` is stored in the :nodename clipboard
    When I run the :get client command with:
      | resource | pod                       |
      | l        | deploymentconfig=database |
      | o        | wide                      |
    Then the step should succeed
    And the output should contain 3 times:
      | <%= cb.nodename %> |
    Examples:
      | filename                            | podfilename       |
      | policy_aff_aff_antiaffi43.json      | pod_ocp11889.json | # @case_id OCP-30067
      | policy_aff_antiaffi_antiaffi43.json | pod_ocp12191.json | # @case_id OCP-30068

  # @author knarra@redhat.com
  # @case_id OCP-37484
  @admin
  @destructive
  Scenario: Scheduler_plugins - Validate HighNodeUtilization profile
    Given the CR "Scheduler" named "cluster" is restored after scenario
    When I run the :patch admin command with:
      | resource      | Scheduler                                                          |
      | resource_name | cluster                                                            |
      | p             |[{"op":"add", "path":"/spec/profile", "value":HighNodeUtilization}] |
      | type          | json                                                               |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given I switch to cluster admin pseudo user
    And I use the "openshift-kube-scheduler" project
    When I run the :get admin command with:
      | resource | configmap/config |
      | o        | yaml             |
    And the output should contain:
      | {"disabled":[{"name":"NodeResourcesLeastAllocated"}],"enabled":[{"name":"NodeResourcesMostAllocated"}]} |
    Given a pod becomes ready with labels:
      | app=openshift-kube-scheduler |
    Given evaluation of `@pods[0].name` is stored in the :podname clipboard
    When I run the :logs admin command with:
      | resource_name | <%= cb.podname %> |
    Then the step should succeed
    And the output should contain:
      | apiVersion: kubescheduler.config.k8s.io/v1beta1 |
      | kind: NodeResourcesMostAllocatedArgs            |
      | NodeResourcesMostAllocated                      |

  # @author knarra@redhat.com
  # @case_id OCP-37483
  @admin
  @destructive
  Scenario: Scheduler_plugins - Validate LowNodeUtilization profile
    Given the CR "Scheduler" named "cluster" is restored after scenario
    When I run the :patch admin command with:
      | resource      | Scheduler                                                           |
      | resource_name | cluster                                                             |
      | p             |[{"op":"add", "path":"/spec/profile", "value":"LowNodeUtilization"}] |
      | type          | json                                                                |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "openshift-kube-scheduler" project
    When I run the :get admin command with:
      | resource | configmap/config |
      | o        | yaml             |
    And the output should contain:
      | {"leaderElect":true,"resourceLock":"configmaps","resourceNamespace":"openshift-kube-scheduler"} |
    Given a pod becomes ready with labels:
      | app=openshift-kube-scheduler |
    Given evaluation of `@pods[0].name` is stored in the :podname clipboard
    When I run the :logs admin command with:
      | resource_name | <%= cb.podname %> |
    Then the step should succeed
    And the output should contain:
      | apiVersion: kubescheduler.config.k8s.io/v1beta1 |
      | kind: NodeResourcesLeastAllocatedArgs           |
      | NodeResourcesLeastAllocated                     |

  # @author knarra@redhat.com
  # @case_id OCP-37485
  @admin
  @destructive
  Scenario: Scheduler_plugins - Validate NoScoring profile
    Given the CR "Scheduler" named "cluster" is restored after scenario
    When I run the :patch admin command with:
      | resource      | Scheduler                                                  |
      | resource_name | cluster                                                    |
      | p             |[{"op":"add", "path":"/spec/profile", "value":"NoScoring"}] |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given I switch to cluster admin pseudo user
    And I use the "openshift-kube-scheduler" project
    When I run the :get admin command with:
      | resource | configmap/config |
      | o        | yaml             |
    And the output should contain:
      | "profiles":[{"plugins":{"preScore":{"disabled":[{"name":"*"}]},"score":{"disabled":[{"name":"*"}]}} |
    Given a pod becomes ready with labels:
      | app=openshift-kube-scheduler |
    Given evaluation of `@pods[0].name` is stored in the :podname clipboard
    When I run the :logs admin command with:
      | resource_name | <%= cb.podname %> |
    Then the step should succeed
    And the output should contain:
      | preScore: {} |
      | score: {}    |

  # @author knarra@redhat.com
  # @case_id OCP-31939
  @admin
  @destructive
  Scenario: Verify logLevel settings in kube-scheduler operator
    Given the CR "cluster" named "kubescheduler" is restored after scenario
    When I run the :patch admin command with:
      | resource      | kubescheduler                                                 |
      | resource_name | cluster                                                       |
      | p             | [{"op":"replace", "path":"/spec/logLevel", "value":TraceAll}] |
      | type          | json                                                          |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given I switch to cluster admin pseudo user
    And I use the "openshift-kube-scheduler" project
    Given a pod becomes ready with labels:
      | app=openshift-kube-scheduler |
    Given evaluation of `@pods[0].name` is stored in the :podname clipboard
    When I run the :get admin command with:
      | resource | pod/<%= cb.podname %> |
      | o        | yaml                  |
    Then the step should succeed
    And the output should contain:
      | - -v=10 |
    When I run the :patch admin command with:
      | resource      | kubescheduler                                              |
      | resource_name | cluster                                                    |
      | p             | [{"op":"replace", "path":"/spec/logLevel", "value":Trace}] |
      | type          | json                                                       |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given a pod becomes ready with labels:
      | app=openshift-kube-scheduler |
    Given evaluation of `@pods[0].name` is stored in the :podname clipboard
    When I run the :get admin command with:
      | resource | pod/<%= cb.podname %> |
      | o        | yaml                  |
    Then the step should succeed
    And the output should contain:
      | - -v=6 |
    When I run the :patch admin command with:
      | resource      | kubescheduler                                              |
      | resource_name | cluster                                                    |
      | p             | [{"op":"replace", "path":"/spec/logLevel", "value":Debug}] |
      | type          | json                                                       |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given a pod becomes ready with labels:
      | app=openshift-kube-scheduler |
    Given evaluation of `@pods[0].name` is stored in the :podname clipboard
    When I run the :get admin command with:
      | resource | pod/<%= cb.podname %> |
      | o        | yaml                  |
    Then the step should succeed
    And the output should contain:
      | - -v=4 |
