Feature: NFD related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-25335
  @admin
  @destructive
  Scenario: Deploy Node Feature Discovery (NFD) operator from OperatorHub
    Given the first user is cluster-admin
    And I ensure "openshift-operators" project is deleted after scenario
    And evaluation of `project('openshift-operators')` is stored in the :project clipboard
    And evaluation of `cluster_version('version').version.split('-')[0].to_f` is stored in the :channel clipboard
    When I open admin console in a browser
    Then the step should succeed
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | nfd                    |
      | catalog_name     | qe-app-registry        |
      | target_namespace | <%= cb.project.name %> |
    Then the step should succeed
    And I perform the :set_custom_channel_and_subscribe web action with:
      | update_channel    | <%= cb.channel %> |
      | install_mode      | OwnNamespace      |
      | approval_strategy | Automatic         |
    Then the step should succeed
    And I use the "openshift-operators" project
    And a pod becomes ready with labels:
      | name=nfd-operator |
    And I run oc create over ERB test file: nfd/<%= cb.channel %>/nfd_master.yaml
    Then the step should succeed
    And all the pods in the project reach a successful state
    And I store all worker nodes to the :worker_nodes clipboard
    And I store the masters in the :master_nodes clipboard
    And <%= cb.master_nodes.count %> pods become ready with labels:
      | app=nfd-master |
    And <%= cb.master_nodes.count %> pods become ready with labels:
      | app=nfd-worker |
    # go through all nodes and check if there are labels starts with 'feature'
    And the expression should be true> cb.worker_nodes.select {|w| w.labels.select {|n| n.start_with? 'feature'}}.count > 0
