Feature: Testing Scheduler Operator related scenarios
	
  # @author knarra@redhat.com
  # @case_id OCP-12459
  @admin
  @destructive
  Scenario: Fixed predicates rules testing Hostname for 4.x
    Given the master version >= "4.1"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the "cluster" scheduler CR is restored after scenario
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                                          |
      | from_file | policy.cfg=<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/policy_hostname.json |
      | namespace | openshift-config                                                                          |
      Then the step should succeed

    When I run the :patch admin command with:
      | resource      | Scheduler                                       |
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
    Given I store the schedulable workers in the :nodes clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/pod_with_nodename.json" replacing paths:
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
    Given the "cluster" scheduler CR is restored after scenario

    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                                                          |
      | from_file | policy.cfg=<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/policy_servicespreadingpriority.json |
      | namespace | openshift-config                                                                                          |
    Then the step should succeed
    Given as admin I successfully merge patch resource "Scheduler/cluster" with:
      | {"spec":{"policy":{"name":"scheduler-policy"}}} |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given I have a project
    Given I store the schedulable workers in the :nodes clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/list_for_servicespreading.json |
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
    Given the "cluster" scheduler CR is restored after scenario

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
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "True"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                                       |
      | from_file | policy.cfg=<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/policy_empty.json |
      | namespace | openshift-config                                                                       |
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
    When I run the :new_app client command with:
      | docker_image | openshift/hello-openshift |
      | name         | openshift1                |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
	    | deploymentconfig= openshift1 |

  # @author knarra@redhat.com
  # @case_id OCP-12489
  @admin
  @destructive
  Scenario: Fixed priority rules testing - LeastRequestedPriority
    Given the master version >= "4.1"
    Given I store the schedulable workers in the :nodes clipboard
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the "cluster" scheduler CR is restored after scenario

    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                                                        |
      | from_file | policy.cfg=<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/policy_leastrequestedpriority.json |
      | namespace | openshift-config                                                                                        |
    Then the step should succeed

    When I run the :patch admin command with:
      | resource      | Scheduler                                       |
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
    # Mark one node as unschedulable
    Given node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/pod_ocp12489.yaml |
    Then the step should succeed
    Given the pod named "pod-request" status becomes :running within 60 seconds
    And evaluation of `pod.node_name` is stored in the :nodename clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/pod_ocp12489.yaml" replacing paths:
      | ["metadata"]["name"] | pod-request1 |
    Then the step should succeed
    And the pod named "pod-request1" becomes ready
    And the expression should be true> pod.node_name != cb.nodename

  # @author yinzhou@redhat.com
  @admin
  @destructive
  Scenario Outline: Schedule pods within the same service for 4.x
    Given the master version >= "4.1"
    Given admin ensures "my-scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the "cluster" scheduler CR is restored after scenario
    When I run the :create_configmap admin command with:
      | name      | my-scheduler-policy                                                             |
      | from_file | policy.cfg=<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/<filename> |
      | namespace | openshift-config                                                                |
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
    And the expression should be true> cb.nodes.delete(node)
    Given node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
    Then the step should succeed
    When I run the :oadm_uncordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    Given I store the schedulable workers in the :nodes clipboard
    And label "usertestregion=r1" is added to the "<%= cb.nodes[0].name %>" node
    And label "usertestregion=r2" is added to the "<%= cb.nodes[1].name %>" node
    And label "usertestzone=z21" is added to the "<%= cb.nodes[1].name %>" node
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | openshift/hello-openshift |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
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
    Given the master version >= "4.1"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the "cluster" scheduler CR is restored after scenario
    Given node schedulable status should be restored after scenario
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                                |
      | from_file | policy.cfg=<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/<filename> |
      | namespace | openshift-config                                                                |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | scheduler                                       |
      | resource_name | cluster                                         |
      | p             | {"spec":{"policy":{"name":"scheduler-policy"}}} |
      | type          | merge                                           |
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
    Given I store the schedulable workers in the :nodes clipboard
    And label "ocpaffrack=a111" is added to the "<%= cb.nodes[0].name %>" node
    And label "ocpaffregion=r1" is added to the "<%= cb.nodes[0].name %>" node
    And label "ocpaffzone=z11" is added to the "<%= cb.nodes[0].name %>" node
    And label "ocpaffrack=a211" is added to the "<%= cb.nodes[1].name %>" node
    And label "ocpaffregion=r2" is added to the "<%= cb.nodes[1].name %>" node
    And label "ocpaffzone=z21" is added to the "<%= cb.nodes[1].name %>" node
    When I run the :oadm_cordon_node admin command with:
      | node_name | <%= cb.nodes[2].name %> |
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | openshift/hello-openshift |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | deploymentconfig=hello-openshift |
    Then the expression should be true> pod.node_name == cb.nodes[0].name || cb.nodes[1].name
    Examples:
      | filename                          |
      | policy_aff_aff_antiaffi.json      | # @case_id OCP-11889
      | policy_aff_antiaffi_antiaffi.json | # @case_id OCP-12191

  # @case_id OCP-12523
  @admin
  @destructive
  Scenario: Tune the node priority by the weight attribute
    Given the master version >= "4.1"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given node schedulable status should be restored after scenario
    Given the "cluster" scheduler CR is restored after scenario
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                                                 |
      | from_file | policy.cfg=<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/policy_weightattribute.json |
      | namespace | openshift-config                                                                                 |
    Then the step should succeed

    Given as admin I successfully merge patch resource "Scheduler/cluster" with:
      | {"spec":{"policy":{"name":"scheduler-policy"}}} |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-scheduler").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-scheduler").condition(type: 'Available')['status'] == "True"
    """
    Given I store the schedulable workers in the :nodes clipboard
    When I run the :oadm_cordon_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    # Test for ServiceSpreadingPriority weight attribute
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :create_deployment client command with:
      | name  | hello                            |
      | image | openshift/hello-openshift:latest |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=hello |
    When I run the :set_resources client command with:
      | resource      | deployment |
      | resourcename  | hello      |
      | requests      | cpu=50m    |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=hello |
    When I run the :create_deployment client command with:
      | name  | hello1                           |
      | image | openshift/hello-openshift:latest |
    Then the step should succeed
    Given I successfully patch resource "deployment/hello1" with:
      | {"spec":{"replicas":2}} |
    And I wait until number of replicas match "2" for deployment "hello1"
    Given status becomes :running of 2 pods labeled:
      | app=hello1 |
    And evaluation of `@pods[1].node_name` is stored in the :nodename clipboard
    And evaluation of `@pods[2].node_name` is stored in the :podnodename clipboard
    Then the expression should be true> cb.podnodename != cb.nodename
    # Edit weight attribute for leastrequestpriority
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project
    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                                                    |
      | from_file | policy.cfg=<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/policy_weightattributeone.json |
      | namespace | openshift-config                                                                                    |
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
    Given I use the "<%= cb.nodes[2].name %>" node
    And evaluation of `cb.nodes[2].remaining_resources[:memory]` is stored in the :node_memory clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/pod_ocp12489.yaml" replacing paths:
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | <%= cb.node_memory %> |
    Then the step should succeed
    Given the pod named "pod-request" status becomes :running within 60 seconds
    And evaluation of `pod.node_name` is stored in the :nodename clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/pod_ocp12489.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-request5 |
      | ["spec"]["containers"][0]["resources"]["requests"]["memory"] | 200Mi        |
    Then the step should succeed
    And the pod named "pod-request5" becomes ready
    And the expression should be true> pod.node_name != cb.nodename
