Feature: Scheduler predicates and priority test suites
  # @author wjiang@redhat.com
  # @case_id OCP-12467
  @admin
  Scenario: [origin_runtime_646] Fixed predicates rules testing - MatchNodeSelector
    Given I have a project
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_nodeselector.json  |
    Then the step should succeed
    Given I run the :describe client command with:
      | resource  | pods            |
      | name      | nodeselect-pod  |
    Then the output should match:
      |  Status:\\s+Pending |
      | FailedScheduling.*(MatchNodeSeceltor\|node\(s\) didn't match node selector)|
    Given a node that can run pods in the "<%=project.name%>" project is selected
    Given label "OS=atomic" is added to the "<%=node.name%>" node
    Then the step should succeed
    Given the pod named "nodeselect-pod" becomes ready
    Then the expression should be true> pod.node_name == node.name


  # @author wjiang@redhat.com
  # @case_id OCP-12479
  @admin
  @destructive
  Scenario: [origin_runtime_646] Fixed predicates rules testing - PodFitsPorts
    Given I have a project
    Given a node that can run pods in the "<%=project.name%>" project is selected
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
    Given a node that can run pods in the "<%=project.name%>" project is selected
    When I run oc create as admin over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/multiple-schedulers/binding.json 
    And the step should succeed
    Given the pod named "custom-scheduler" becomes ready
    Then the expression should be true> pod.node_name == node.name
