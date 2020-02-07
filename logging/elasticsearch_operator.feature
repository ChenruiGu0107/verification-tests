@clusterlogging
Feature: elasticsearch operator related tests

  # @author qitang@redhat.com
  @admin
  @destructive
  Scenario Outline: Redundancy policy testing
    Given I delete the clusterlogging instance
    Given I register clean-up steps:
    """
      Given I delete the clusterlogging instance
    """
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/clusterlogging/<file> |
    Then the step should succeed
    Given I wait for the "elasticsearch" config_map to appear
    Then the expression should be true> elasticsearch('elasticsearch').redundancy_policy == <redundancy_policy>
    Given evaluation of `YAML.load(config_map('elasticsearch').value_of('index_settings'))` is stored in the :data clipboard
    And the expression should be true> cb.data == <index_settings>

    Examples:
      | file                    | index_settings                      | redundancy_policy    |
      | singleredundancy.yaml   | "PRIMARY_SHARDS=3 REPLICA_SHARDS=1" | "SingleRedundancy"   | # @case_id OCP-21929
      | fullredundancy.yaml     | "PRIMARY_SHARDS=3 REPLICA_SHARDS=2" | "FullRedundancy"     | # @case_id OCP-22007
      | zeroredundancy.yaml     | "PRIMARY_SHARDS=3 REPLICA_SHARDS=0" | "ZeroRedundancy"     | # @case_id OCP-22006
      | multipleredundancy.yaml | "PRIMARY_SHARDS=5 REPLICA_SHARDS=2" | "MultipleRedundancy" | # @case_id OCP-22005

  # @author qitang@redhat.com
  # @case_id OCP-24108
  @admin
  @destructive
  @commonlogging
  Scenario: Should expose es cluster health status in Elasticsearch CR.
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | _cluster/health?format=JSON |
      | op           | GET                         |
    Then the step should succeed
    And evaluation of `JSON.parse(@result[:response])` is stored in the :es_cluster_health_1 clipboard
    Given evaluation of `elasticsearch('elasticsearch').cluster_status` is stored in the :es_cr_status_1 clipboard
    Then the expression should be true> cb.es_cluster_health_1['active_primary_shards'] == cb.es_cr_status_1['activePrimaryShards']
    And the expression should be true> cb.es_cluster_health_1['active_shards'] == cb.es_cr_status_1['activeShards']
    And the expression should be true> cb.es_cluster_health_1['initializing_shards'] == cb.es_cr_status_1['initializingShards']
    And the expression should be true> cb.es_cluster_health_1['number_of_data_nodes'] == cb.es_cr_status_1['numDataNodes']
    And the expression should be true> cb.es_cluster_health_1['number_of_nodes'] == cb.es_cr_status_1['numNodes']
    And the expression should be true> cb.es_cluster_health_1['relocating_shards'] == cb.es_cr_status_1['relocatingShards']
    And the expression should be true> cb.es_cluster_health_1['number_of_pending_tasks'] == cb.es_cr_status_1['pendingTasks']
    And the expression should be true> cb.es_cluster_health_1['status'] == cb.es_cr_status_1['status']
    And the expression should be true> cb.es_cluster_health_1['unassigned_shards'] == cb.es_cr_status_1['unassignedShards']
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project` is stored in the :org_project clipboard
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And I wait 600 seconds for the "project.<%= cb.org_project.name %>" index to appear in the ES pod with labels "es-node-master=true"
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | _cluster/health?format=JSON |
      | op           | GET                         |
    Then the step should succeed
    And evaluation of `JSON.parse(@result[:response])` is stored in the :es_cluster_health_2 clipboard
    Given evaluation of `elasticsearch('elasticsearch').cluster_status` is stored in the :es_cr_status_2 clipboard
    Then the expression should be true> cb.es_cluster_health_2['active_primary_shards'] == cb.es_cr_status_2['activePrimaryShards']
    And the expression should be true> cb.es_cluster_health_2['active_shards'] == cb.es_cr_status_2['activeShards']
    And the expression should be true> cb.es_cluster_health_2['initializing_shards'] == cb.es_cr_status_2['initializingShards']
    And the expression should be true> cb.es_cluster_health_2['number_of_data_nodes'] == cb.es_cr_status_2['numDataNodes']
    And the expression should be true> cb.es_cluster_health_2['number_of_nodes'] == cb.es_cr_status_2['numNodes']
    And the expression should be true> cb.es_cluster_health_2['relocating_shards'] == cb.es_cr_status_2['relocatingShards']
    And the expression should be true> cb.es_cluster_health_2['number_of_pending_tasks'] == cb.es_cr_status_2['pendingTasks']
    And the expression should be true> cb.es_cluster_health_2['status'] == cb.es_cr_status_2['status']
    And the expression should be true> cb.es_cluster_health_2['unassigned_shards'] == cb.es_cr_status_2['unassignedShards']
    """
