@clusterlogging
Feature: elasticsearch operator related tests

  # @author qitang@redhat.com
  @admin
  @destructive
  Scenario Outline: Redundancy policy testing
    Given I obtain test data file "logging/clusterlogging/<file>"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true   |
      | crd_yaml            | <file> |
      | check_status        | false  |
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
    Given the master version < "4.5"
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

  # @author qitang@redhat.com
  # @case_id OCP-21260
  @admin
  @destructive
  Scenario: The prometheus-rules can be created by elasticsearch operator
    Given I obtain test data file "logging/clusterlogging/example.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true         |
      | crd_yaml            | example.yaml |
    Then the step should succeed
    Given I wait for the "elasticsearch-prometheus-rules" prometheus_rule to appear
    And evaluation of `prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rules` is stored in the :es_alert_rules_1 clipboard

    Given evaluation of `cb.es_alert_rules_1.select {|e| e['alert'].start_with? 'ElasticsearchClusterNotHealthy'}` is stored in the :es_cluster_not_healthy_alerts clipboard
    And evaluation of `cb.es_alert_rules_1.select {|e| e['alert'].start_with? 'ElasticsearchNodeDiskWatermarkReached'}` is stored in the :es_node_disk_watermare_alerts clipboard
    Then the expression should be true> cb.es_cluster_not_healthy_alerts.find {|e| e['for'] == "2m"}["labels"]["severity"] == "critical"
    And the expression should be true> cb.es_cluster_not_healthy_alerts.find {|e| e['for'] == "20m"}["labels"]["severity"] == "warning"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchBulkRequestsRejectionJumps').severity == "warning"
    And the expression should be true> cb.es_node_disk_watermare_alerts.find {|e| e['annotations']['message'].start_with? 'Disk Low Watermark Reached'}['labels']['severity'] == "alert"
    And the expression should be true> cb.es_node_disk_watermare_alerts.find {|e| e['annotations']['message'].start_with? 'Disk High Watermark Reached'}['labels']['severity'] == "high"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchJVMHeapUseHigh').severity == "alert"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'AggregatedLoggingSystemCPUHigh').severity == "alert"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchProcessCPUHigh').severity == "alert"

    Given I run the :patch client command with:
      | resource      | prometheusrule |
      | resource_name | elasticsearch-prometheus-rules |
      | p             | {"spec": {"groups": [{"name": "logging_elasticsearch.alerts", "rules": [{"alert": "ElasticsearchClusterNotHealthy","expr": "sum by (cluster) (es_cluster_status == 2)", "for": "5m", "labels": {"severity": "critical"}}]}]}} |
      | type          | merge |
    Then the step should succeed
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchClusterNotHealthy').for == "5m"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rules.count == 1

    Given I wait up to 300 seconds for the steps to pass:
    """
    Given I check the "elasticsearch-prometheus-rules" prometheus rule in the "openshift-logging" project on the prometheus server
    And the output should not contain:
      | ElasticsearchNodeDiskWatermarkReached |
      | ElasticsearchBulkRequestsRejectionJumps |
      | ElasticsearchJVMHeapUseHigh |
      | AggregatedLoggingSystemCPUHigh |
      | ElasticsearchProcessCPUHigh |
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'ElasticsearchClusterNotHealthy'}['for'] == "5m"
    """

  # @author qitang@redhat.com
  # @case_id OCP-24134
  @admin
  @destructive
  Scenario: The shard number should be same with the node number
    Given the master version < "4.5"
    Given I obtain test data file "logging/clusterlogging/example.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true         |
      | crd_yaml            | example.yaml |
    Then the step should succeed
    Given evaluation of `cluster_logging('instance').logstore_node_count` is stored in the :es_node_count_1 clipboard
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    #A workaround to https://bugzilla.redhat.com/show_bug.cgi?id=1776594
    And I wait for the ".operations" index to appear in the ES pod with labels "es-node-master=true"
    Given evaluation of `%w(project .operations)` is stored in the :index_names clipboard
    Given I repeat the following steps for each :index_name in cb.index_names:
    """
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | #{cb.index_name}.* |
      | op           | DELETE             |
    Then the step should succeed
    """
    #Workaround end
    And I wait for the ".operations" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == cb.es_node_count_1
    When I get the ".kibana" logging index information from a pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == cb.es_node_count_1
    When I run the :patch client command with:
      | resource      | clusterlogging                                          |
      | resource_name | instance                                                |
      | p             | {"spec":{"logStore":{"elasticsearch":{"nodeCount":2}}}} |
      | type          | merge                                                   |
    Then the step should succeed
    And the expression should be true> cluster_logging('instance').logstore_node_count == 2
    Given I wait for the steps to pass:
    """
    And the expression should be true> elasticsearch('elasticsearch').nodes[0]['nodeCount'] == 2
    """
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid%>-2" deployment to appear
    Given evaluation of `YAML.load(config_map('elasticsearch').value_of('index_settings'))` is stored in the :data clipboard
    And the expression should be true> cb.data == "PRIMARY_SHARDS=2 REPLICA_SHARDS=0"

    Given I wait up to 300 seconds for the steps to pass:
    """
      Given the expression should be true> deployment('elasticsearch-cdm-<%= cb.es_genuuid%>-2').replica_counters(cached:false)[:desired] == deployment('elasticsearch-cdm-<%= cb.es_genuuid%>-2').replica_counters[:ready]
    """

    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project` is stored in the :org_project clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=centos-logtest,test=centos-logtest |
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And I wait for the "project.<%= cb.org_project.name %>" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == cluster_logging('instance').logstore_node_count
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | _cat/indices?format=JSON |
      | op           | GET                      |
    Then the step should succeed
    And evaluation of ` @result[:parsed].find {|e| e['index'].start_with? '.kibana'}` is stored in the :res_kibana clipboard
    And evaluation of ` @result[:parsed].find {|e| e['index'].start_with? '.operations'}` is stored in the :res_op clipboard
    Then the expression should be true> cb.res_kibana['pri'].to_i == cb.es_node_count_1 && cb.res_op['pri'].to_i == cb.es_node_count_1

  # @author qitang@redhat.com
  # @case_id OCP-30208
  @admin
  @destructive
  Scenario: The shard number should be equal to the node number
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project` is stored in the :org_project clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=centos-logtest,test=centos-logtest |
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    Given I obtain test data file "logging/clusterlogging/example_indexmanagement.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                         |
      | crd_yaml            | example_indexmanagement.yaml |
    Then the step should succeed
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    And I wait for the "app" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == 1
    And I wait for the "infra" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == 1
    When I get the ".kibana" logging index information from a pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == 1
    When I run the :patch client command with:
      | resource      | clusterlogging                                          |
      | resource_name | instance                                                |
      | p             | {"spec":{"logStore":{"elasticsearch":{"nodeCount":2}}}} |
      | type          | merge                                                   |
    Then the step should succeed
    And the expression should be true> cluster_logging('instance').logstore_node_count == 2
    Given I wait for the steps to pass:
    """
    And the expression should be true> elasticsearch('elasticsearch').nodes[0]['nodeCount'] == 2
    """
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid%>-2" deployment to appear
    Given evaluation of `YAML.load(config_map('elasticsearch').value_of('index_settings'))` is stored in the :data clipboard
    And the expression should be true> cb.data == "PRIMARY_SHARDS=2 REPLICA_SHARDS=0"

    Given I wait up to 300 seconds for the steps to pass:
    """
      Given the expression should be true> deployment('elasticsearch-cdm-<%= cb.es_genuuid%>-2').replica_counters(cached:false)[:desired] == deployment('elasticsearch-cdm-<%= cb.es_genuuid%>-2').replica_counters[:ready]
    """
    # the default rollover job runs in every 15 minutes, it's too long for the automation, so here delete the indices
    Given evaluation of `%w(app infra)` is stored in the :index_names clipboard
    Given I repeat the following steps for each :index_name in cb.index_names:
    """
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | #{cb.index_name}-* |
      | op           | DELETE             |
    Then the step should succeed
    """
    Given I wait for the "app" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == 2
    And I wait for the "infra" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == 2

  # @author qitang@redhat.com
  # @case_id OCP-30209
  @admin
  @destructive
  Scenario: Should expose ES cluster health status in Elasticsearch CR
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=centos-logtest,test=centos-logtest |
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    Given I obtain test data file "logging/clusterlogging/example_indexmanagement.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                         |
      | crd_yaml            | example_indexmanagement.yaml |
    Then the step should succeed
    And I wait for the project "<%= cb.proj.name %>" logs to appear in the ES pod
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | _cluster/health?format=JSON |
      | op           | GET                         |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['status'] == elasticsearch('elasticsearch').cluster_health
    And the expression should be true> @result[:parsed]['status'] == cluster_logging('instance').es_cluster_health(cached: false)
    # make the cluster unhealth
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | test-index-001 |
      | op           | PUT            |
    Then the step should succeed
    And the output should contain:
      | "acknowledged":true |
    # wait for the new index test-index-001 to appear
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | _cat/indices?format=JSON |
      | op           | GET                      |
    Then the step should succeed
    And the output should contain:
      | test-index-001 |
    """
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | _cluster/health?format=JSON |
      | op           | GET                         |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['status'] == elasticsearch('elasticsearch').cluster_health
    And the expression should be true> @result[:parsed]['status'] == cluster_logging('instance').es_cluster_health(cached: false)
    And the expression should be true> @result[:parsed]['active_primary_shards'] == elasticsearch('elasticsearch').active_primary_shards
    And the expression should be true> @result[:parsed]['unassigned_shards'] == elasticsearch('elasticsearch').unassigned_shards
    """

  # @author qitang@redhat.com
  # @case_id OCP-23116
  @admin
  @destructive
  Scenario: The EO should update the ES cluster status in the Elasticsearch CR timely.
    Given I obtain test data file "logging/clusterlogging/invalid_setting.yaml"
    When I create clusterlogging instance with:
      | remove_logging_pods | true                 |
      | crd_yaml            | invalid_setting.yaml |
      | check_status        | false                |
    Then the step should succeed
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given the expression should be true> cluster_logging('instance').es_cluster_conditions.first['message'].include? "Wrong RedundancyPolicy selected."
    And the expression should be true> elasticsearch('elasticsearch').cluster_conditions.first['message'].include? "Wrong RedundancyPolicy selected."
    And the expression should be true> elasticsearch('elasticsearch').cluster_conditions.first['reason'] == "Invalid Settings"
    And the expression should be true> elasticsearch('elasticsearch').cluster_conditions.first['type'] == "InvalidRedundancy"
    """
    When I run the :patch client command with:
      | resource      | clusterlogging                                                                |
      | resource_name | instance                                                                      |
      | p             | {"spec":{"logStore":{"elasticsearch":{"redundancyPolicy":"ZeroRedundancy"}}}} |
      | type          | merge                                                                         |
    Then the step should succeed
    And a pod becomes ready with labels:
      | es-node-master=true |
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given the expression should be true> cluster_logging('instance').es_cluster_conditions.nil?
    And the expression should be true> elasticsearch('elasticsearch').cluster_conditions.nil? || elasticsearch('elasticsearch').cluster_conditions.empty?
    """
    Given I delete the clusterlogging instance
    Given I obtain test data file "logging/clusterlogging/clusterlogging-storage-template.yaml"
    And I register clean-up steps:
    """
    Given I run the :delete client command with:
      | object_type | pvc               |
      | all         | true              |
      | n           | openshift-logging |
    Then the step should succeed
    """
    When I process and create:
      | f | clusterlogging-storage-template.yaml |
      | p | STORAGE_CLASS=test-es                |
      | p | PVC_SIZE=10Gi                        |
    Then the step should succeed
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given the expression should be true> cluster_logging('instance').es_node_conditions.to_s.include? "pod has unbound immediate PersistentVolumeClaims"
    And the expression should be true> elasticsearch('elasticsearch').nodes_conditions.first['message'].include? "pod has unbound immediate PersistentVolumeClaims"
    And the expression should be true> elasticsearch('elasticsearch').nodes_conditions.first['reason'] == "Unschedulable"
    And the expression should be true> elasticsearch('elasticsearch').nodes_conditions.first['type'] == "Unschedulable"
    """

  # @author qitang@redhat.com
  # @case_id OCP-32064
  @admin
  @destructive
  Scenario: New ES pod should reconnect the cluster successfully
    Given I obtain test data file "logging/clusterlogging/singleredundancy.yaml"
    When I create clusterlogging instance with:
      | remove_logging_pods | true                  |
      | crd_yaml            | singleredundancy.yaml |
    Then the step should succeed
    Given evaluation of `elasticsearch('elasticsearch').es_master_ready_pod_names` is stored in the :es_pods_1 clipboard
    And I repeat the following steps for each :es_pod in cb.es_pods_1:
    """
      Given the expression should be true> pod('#{cb.es_pod}').exists?
    """
    When I run the :delete client command with:
     | object_type       | pod                       |
     | object_name_or_id | <%= cb.es_pods_1.first %> |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= cb.es_pods_1.first %>" to disappear
    Given evaluation of `cluster_logging('instance').logstore_node_count.to_i` is stored in the :es_node_count clipboard
    And <%= cb.es_node_count %> pods become ready with labels:
      | cluster-name=elasticsearch |
    And I wait until ES cluster is ready
    Given I wait up to 600 seconds for the steps to pass:
    """
      Given evaluation of `elasticsearch('elasticsearch').es_master_ready_pod_names` is stored in the :es_pods_2 clipboard
      Then the expression should be true>  (cb.es_pods_1 - cb.es_pods_2).empty? == false
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | _cluster/health?format=JSON |
      | op           | GET                         |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['number_of_nodes'] == cb.es_node_count
    And I repeat the following steps for each :es_pod in cb.es_pods_2:
    """
      Given the expression should be true> pod('#{cb.es_pod}').exists?
    """

  # @author qitang@redhat.com
  # @case_id OCP-34294
  @admin
  @destructive
  Scenario: Should support dynamic redundancy policy change
    Given I obtain test data file "logging/clusterlogging/singleredundancy.yaml"
    When I create clusterlogging instance with:
      | remove_logging_pods | true                  |
      | crd_yaml            | singleredundancy.yaml |
    Then the step should succeed
    Given I wait for the "elasticsearch" config_map to appear
    Then the expression should be true> elasticsearch('elasticsearch').redundancy_policy == "SingleRedundancy"
    Given evaluation of `YAML.load(config_map('elasticsearch').value_of('index_settings'))` is stored in the :data clipboard
    And the expression should be true> cb.data == "PRIMARY_SHARDS=3 REPLICA_SHARDS=1"
    When I get the "infra-000001" logging index information from a pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == 3 && cb.index_data['rep'].to_i == 1
    Given I successfully merge patch resource "clusterlogging/instance" with:
      | {"spec": {"logStore": {"elasticsearch": {"redundancyPolicy": "ZeroRedundancy"}}}} |
    And I wait up to 180 seconds for the steps to pass:
    """
    Given the expression should be true> elasticsearch('elasticsearch').redundancy_policy == "ZeroRedundancy"
    Given evaluation of `YAML.load(config_map('elasticsearch').value_of('index_settings', cached: false))` is stored in the :data clipboard
    And the expression should be true> cb.data == "PRIMARY_SHARDS=3 REPLICA_SHARDS=0"
    When I get the "infra-000001" logging index information from a pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == 3 && cb.index_data['rep'].to_i == 0
    """

    Given I successfully merge patch resource "clusterlogging/instance" with:
      | {"spec": {"logStore": {"elasticsearch": {"redundancyPolicy": "FullRedundancy"}}}} |
    And I wait up to 180 seconds for the steps to pass:
    """
    Given the expression should be true> elasticsearch('elasticsearch').redundancy_policy == "FullRedundancy"
    Given evaluation of `YAML.load(config_map('elasticsearch').value_of('index_settings', cached: false))` is stored in the :data clipboard
    And the expression should be true> cb.data == "PRIMARY_SHARDS=3 REPLICA_SHARDS=2"
    When I get the "infra-000001" logging index information from a pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['pri'].to_i == 3 && cb.index_data['rep'].to_i == 2
    """

  # @author qitang@redhat.com
  # @case_id OCP-34988
  @admin
  @destructive
  Scenario: Elasticsearch-prometheus-rules checking.
    Given I obtain test data file "logging/clusterlogging/example_indexmanagement.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                         |
      | crd_yaml            | example_indexmanagement.yaml |
    Then the step should succeed
    Given I wait for the "elasticsearch-prometheus-rules" prometheus_rule to appear
    And evaluation of `prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rules` is stored in the :es_alert_rules_1 clipboard

    Given evaluation of `cb.es_alert_rules_1.select {|e| e['alert'].start_with? 'ElasticsearchClusterNotHealthy'}` is stored in the :es_cluster_not_healthy_alerts clipboard
    And evaluation of `cb.es_alert_rules_1.select {|e| e['alert'].start_with? 'ElasticsearchNodeDiskWatermarkReached'}` is stored in the :es_node_disk_watermare_alerts clipboard
    Then the expression should be true> cb.es_cluster_not_healthy_alerts.find {|e| e['for'] == "7m"}["labels"]["severity"] == "critical"
    And the expression should be true> cb.es_cluster_not_healthy_alerts.find {|e| e['for'] == "20m"}["labels"]["severity"] == "warning"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchWriteRequestsRejectionJumps').severity == "warning"
    And the expression should be true> cb.es_node_disk_watermare_alerts.find {|e| e['annotations']['message'].start_with? 'Disk Low Watermark Reached'}['labels']['severity'] == "info"
    And the expression should be true> cb.es_node_disk_watermare_alerts.find {|e| e['annotations']['message'].start_with? 'Disk High Watermark Reached'}['labels']['severity'] == "warning"
    And the expression should be true> cb.es_node_disk_watermare_alerts.find {|e| e['annotations']['message'].start_with? 'Disk Flood Stage Watermark Reached'}['labels']['severity'] == "critical"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchJVMHeapUseHigh').severity == "alert"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'AggregatedLoggingSystemCPUHigh').severity == "alert"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchProcessCPUHigh').severity == "alert"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchDiskSpaceRunningLow').severity == "critical"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchHighFileDescriptorUsage').severity == "warning"

    # set managementState to Unmanaged before making changes
    Given I successfully merge patch resource "elasticsearch/elasticsearch" with:
      | {"spec": {"managementState": "Unmanaged"}} |

    And I successfully merge patch resource "prometheusrule/elasticsearch-prometheus-rules" with:
      | {"spec": {"groups": [{"name": "logging_elasticsearch.alerts", "rules": [{"alert": "ElasticsearchClusterNotHealthy","expr": "sum by (cluster) (es_cluster_status == 2)", "for": "5m", "labels": {"severity": "critical"}}]}]}} |

    Then the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchClusterNotHealthy').for == "5m"
    And the expression should be true> prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rules.count == 1

    Given I wait up to 300 seconds for the steps to pass:
    """
    Given I check the "elasticsearch-prometheus-rules" prometheus rule in the "openshift-logging" project on the prometheus server
    And the output should not contain:
      | ElasticsearchNodeDiskWatermarkReached    |
      | ElasticsearchWriteRequestsRejectionJumps |
      | ElasticsearchJVMHeapUseHigh              |
      | AggregatedLoggingSystemCPUHigh           |
      | ElasticsearchProcessCPUHigh              |
      | ElasticsearchDiskSpaceRunningLow         |
      | ElasticsearchHighFileDescriptorUsage     |
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'ElasticsearchClusterNotHealthy'}['for'] == "5m"
    """

  # @author qitang@redhat.com
  # @case_id OCP-36102
  @admin
  @destructive
  @commonlogging
  Scenario: [BZ 1883357] Should show correct error message instead of `Internal Server Error`
    Given I switch to the first user
    Given I create a project with non-leading digit name
    Given evaluation of `project` is stored in the :proj clipboard
    Given I obtain test data file "logging/loggen/container_json_unicode_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_unicode_log_template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=centos-logtest,test=centos-logtest |

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait for the "app" index to appear in the ES pod with labels "es-node-master=true"
    And I wait for the project "<%= cb.proj.name %>" logs to appear in the ES pod

    Given I register clean-up steps:
    """
      Given as admin I successfully merge patch resource "oauth/cluster" with:
        | {"spec": {"tokenConfig": null}} |
    """
    Given as admin I successfully merge patch resource "oauth/cluster" with:
      | {"spec": {"tokenConfig": {"accessTokenMaxAgeSeconds": 180}}} |
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """

    Given I switch to the first user
    When I login to kibana logging web console
    Then the step should succeed
    When I perform the :create_index_pattern_in_kibana web action with:
      | index_pattern_name | app |
    Then the step should succeed
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I run the :go_to_kibana_discover_page web action
    Then the step should succeed
    """
    # wait for 3 minutes for the oauthaccesstokens.oauth.openshift.io to expire
    Given 180 seconds have passed
    When I run the :click_refresh_button_in_kibana web action
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given a pod becomes ready with labels:
      | es-node-master=true |
    And evaluation of `pod.name` is stored in the :es_pod clipboard
    When I run the :logs client command with:
      | resource_name | pod/<%= cb.es_pod %> |
      | c             | proxy                |
    Then the step should succeed
    And the output should contain:
      | invalid bearer token, token lookup failed |
    And the output should not contain:
      | Internal Server Error |
