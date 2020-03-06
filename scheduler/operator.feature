Feature: Testing Scheduler Operator related scenarios
	
  # @author knarra@redhat.com
  # @case_id OCP-12459
  @admin
  @destructive
  Scenario: Fixed predicates rules testing Hostname for 4.x
    Given the master version >= "4.1"
    Given admin ensures "scheduler-policy" configmap is deleted from the "openshift-config" project after scenario
    Given the "cluster" scheduler CR is restored after scenario
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/policy_hostname.json"
    Then the step should succeed

    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                       |
      | from_file | policy.cfg=<%= File.join(localhost.workdir, "policy_hostname.json") %> |
      | namespace | openshift-config                                                       |
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_nodename.json" replacing paths:
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
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/policy_servicespreadingpriority.json"
    Then the step should succeed

    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                                       |
      | from_file | policy.cfg=<%= File.join(localhost.workdir, "policy_servicespreadingpriority.json") %> |
      | namespace | openshift-config                                                                       |
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/list_for_servicespreading.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :get client command with:
      | resource      | pods |
      | o             | wide |
    Then the step should succeed
    And the output should contain:
      | <%= cb.nodes[0].name %>  |
      | <%= cb.nodes[1].name %>  |
      | <%= cb.nodes[2].name %>  |


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

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/policy_empty.json"
    Then the step should succeed

    When I run the :create_configmap admin command with:
      | name      | scheduler-policy                                                    |
      | from_file | policy.cfg=<%= File.join(localhost.workdir, "policy_empty.json") %> |
      | namespace | openshift-config                                                    |
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
