Feature: Egress IP related features

  # @author bmeng@redhat.com
  # @case_id OCP-15467
  @admin
  Scenario: Pods will lose external access if the same egressIP is set to multiple netnamespaces and error logs in sdn
    Given the cluster is running on OpenStack
    And the env is using multitenant or networkpolicy network
    Given I select a random node's host
    And evaluation of `node.name` is stored in the :egress_node clipboard
    # add the egress ip to the hostsubnet
    And the valid egress IP is added to the "<%= cb.egress_node %>" node

    # create two projects with pod
    Given I have a project
    And evaluation of `project.name` is stored in the :project1 clipboard
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).ip` is stored in the :p1pod2ip clipboard

    Given I create a new project
    And evaluation of `project.name` is stored in the :project2 clipboard
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(-2).name` is stored in the :p2pod1 clipboard
    And evaluation of `pod(-1).ip` is stored in the :p2pod2ip clipboard

    # add the egress ip to the project
    When I run the :patch admin command with:
      | resource      | netnamespace |
      | resource_name | <%= cb.project1 %> |
      | p             | {"egressIPs":["<%= cb.valid_ip %>"]} |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | netnamespace |
      | resource_name | <%= cb.project2 %> |
      | p             | {"egressIPs":["<%= cb.valid_ip %>"]} |
    Then the step should succeed

    # check the network log about the error
    Given I get the networking components logs of the node since "1m" ago
    Then the output should match "Multiple namespaces.*claiming EgressIP <%= cb.valid_ip %>"

    # try to access cluster and external network on the pods in each project
    Given I use the "<%= cb.project1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello OpenShift"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | test-service.<%= cb.project1 %>.svc:27017 |
    Then the step should succeed
    And the output should contain "Hello OpenShift"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -sI | --connect-timeout | 5 | https://www.google.com/ |
    Then the step should fail
    And the output should not contain "200"
    Given I use the "<%= cb.project2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p2pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello OpenShift"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | test-service.<%= cb.project2 %>.svc:27017 |
    Then the step should succeed
    And the output should contain "Hello OpenShift"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | https://www.google.com/ |
    Then the step should fail
    And the output should not contain "200"

  # @author bmeng@redhat.com
  # @case_id OCP-15469
  @admin
  Scenario: Pods will lose external access if there is no node can host the egress IP which admin assigned to the netns
    Given the cluster is running on OpenStack
    And the env is using multitenant or networkpolicy network

    # create project with pod
    Given I have a project
    And evaluation of `project.name` is stored in the :project clipboard
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :pod1 clipboard
    And evaluation of `pod(1).ip` is stored in the :pod2ip clipboard

    # add the egress ip to the project which is not holding by any node
    Given I store a random unused IP address from the reserved range to the :valid_ip clipboard
    When I run the :patch admin command with:
      | resource      | netnamespace |
      | resource_name | <%= cb.project %> |
      | p             | {"egressIPs":["<%= cb.valid_ip %>"]} |
    Then the step should succeed

    # try to access external network
    When I execute on the "<%= cb.pod1 %>" pod:
      | curl | -sI | --connect-timeout | 5 | https://www.google.com/ |
    Then the step should fail
    And the output should not contain "200"
    # try to access cluster network
    When I execute on the "<%= cb.pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2ip %>:8888 |
    Then the step should succeed
    And the output should contain "Hello OpenShift"
    When I execute on the "<%= cb.pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | test-service.<%= cb.project %>.svc:27017 |
    Then the step should succeed
    And the output should contain "Hello OpenShift"
