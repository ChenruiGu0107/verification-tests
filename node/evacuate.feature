Feature: Evacuate
  # @author weinliu@redhat.com
  # @case_id OCP-11895
  @destructive
  @admin
  Scenario: Evacuate node with dry run option should only list but not actually do the remove
    Given I have a project
    #Patch to remove the annotations of "openshift.io/node-selector" for v3.9 and later
    When I run the :patch admin command with:
      | resource      | namespace                                                         |
      | resource_name | <%= project.name %>                                               |
      | p             | {"metadata": {"annotations": {"openshift.io/node-selector": ""}}} |
    Then the step should succeed
    And environment has at least 2 schedulable nodes
    Given I store the schedulable nodes in the :nodes clipboard
    And label "env=dev" is added to the "<%= cb.nodes[0].name %>" node
    And label "env=qe" is added to the "<%= cb.nodes[1].name %>" node
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/nodeselector/hello-pod-env-dev.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/nodeselector/hello-pod-env-qe.yaml |
    Then the step should succeed
    #oadm manage-node <nodes> \--evacuate \--pod-selector=[selector] --dry-run
    When I run the :oadm_manage_node_evacuate admin command with:
      | node_name    | <%= cb.nodes[0].name %>  |
      | evacuate     | true                     |
      | pod_selector | name=hello-pod-env-dev   |
      | dry_run      | true                     |
    Then the output should contain:
      | Listing matched pods |
      | hello-pod-env-dev    |
    # repeat steps above as per test case
    When I run the :oadm_manage_node_evacuate admin command with:
      | node_name    | <%= cb.nodes[0].name %> |
      | evacuate     | true                    |
      | pod_selector | name=hello-pod-env-dev  |
      | dry_run      | true                    |
    Then the output should contain:
      | Listing matched pods |
      | hello-pod-env-dev    |
    # oadm manage-node --selector="env=dev" \--evacuate \--dry-run
    When I run the :oadm_manage_node_evacuate admin command with:
      | selector | env=qe |
      | evacuate | true   |
      | dry_run  | true   |
    Then the output should contain:
      | Listing matched pods |
      | hello-pod-env-qe     |
    # repeat steps above as per test case
    When I run the :oadm_manage_node_evacuate admin command with:
      | selector | env=qe |
      | evacuate | true   |
      | dry_run  | true   |
    Then the output should contain:
      | Listing matched pods |
      | hello-pod-env-qe     |
    # oadm manage-node <nodes> \--list-pods
    When I run the :oadm_manage_node_evacuate admin command with:
      | node_name | <%= cb.nodes[0].name %> |
      | list_pods | true                    |
    Then the output should contain:
      |hello-pod-env-dev |
    When I run the :oadm_manage_node_evacuate admin command with:
      | node_name | <%= cb.nodes[1].name %> |
      | list_pods | true                    |
    Then the output should contain:
      | hello-pod-env-qe |
    Then status becomes :running of exactly 1 pods labeled:
      | name=hello-pod-env-dev |
    Then status becomes :running of exactly 1 pods labeled:
      | name=hello-pod-env-qe |

  # @author weinliu@redhat.com
  # @case_id OCP-11719
  @destructive
  @admin
  Scenario: Admin can list pods on specified nodes
  Given I have a project
  #Patch to remove the annotations of "openshift.io/node-selector" for v3.9 and later
  When I run the :patch admin command with:
    | resource      | namespace                                                         |
    | resource_name | <%= project.name %>                                               |
    | p             | {"metadata": {"annotations": {"openshift.io/node-selector": ""}}} |
  Then the step should succeed
  And environment has at least 2 schedulable nodes
  Given I store the schedulable nodes in the :nodes clipboard
  And label "env=dev" is added to the "<%= cb.nodes[0].name %>" node
  And label "env=qe" is added to the "<%= cb.nodes[1].name %>" node
  When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/nodeselector/hello-pod-env-dev.yaml |
  Then the step should succeed
  When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/nodeselector/hello-pod-env-dev2.yaml |
  Then the step should succeed
  When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/nodeselector/hello-pod-env-qe.yaml |
  Then the step should succeed
  # oadm manage-node <nodes> \--list-pods
  When I run the :oadm_manage_node_evacuate admin command with:
    | node_name | <%= cb.nodes[0].name %>  |
    | list_pods | true                     |
  Then the output should contain:
    | Listing matched pods |
    | hello-pod-env-dev    |
  #oadm manage-node node1 node2 node3 \--list-pods
  When I run the :oadm_manage_node_evacuate admin command with:
    | node_name | <%= cb.nodes[1].name %>  |
    | node_name | <%= cb.nodes[0].name %>  |
    | list_pods | true                     |
  Then the output should contain:
    | Listing matched pods |
    | hello-pod-env-dev    |
    | hello-pod-env-qe     |
  #oadm manage-node \--list-pods \--pod-selector='name=hello-openshift' \--selector='region=compute'
  When I run the :oadm_manage_node_evacuate admin command with:
    | pod_selector | name=hello-pod-env-dev |
    | selector     | env=dev                |
    | list_pods    | true                   |
  Then the output should contain:
    | Listing matched pods |
    | hello-pod-env-dev    |
  Then the output should not contain:
    | hello-pod-env-qe  |
  Then status becomes :running of exactly 1 pods labeled:
    | name=hello-pod-env-dev |
  Then status becomes :running of exactly 1 pods labeled:
    | name=hello-pod-env-dev2 |
  Then status becomes :running of exactly 1 pods labeled:
    | name=hello-pod-env-qe |
