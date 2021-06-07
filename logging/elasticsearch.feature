@clusterlogging
Feature: elasticsearch related tests

  # @author qitang@redhat.com
  # @case_id OCP-21390
  @admin
  @destructive
  @commonlogging
  Scenario: [Bug 1568361] Elasticsearch log files are on persistent volume
    Given a pod becomes ready with labels:
      | es-node-master=true |
    And I execute on the pod:
      | ls | /elasticsearch/persistent/elasticsearch/logs |
    Then the step should succeed
    And the output should contain:
      | elasticsearch.log                        |
      | elasticsearch_deprecation.log            |
      | elasticsearch_index_indexing_slowlog.log |
      | elasticsearch_index_search_slowlog.log   |
    #And the expression should be true> pod.volume_claims.first.name == 'elasticsearch-elasticsearch-cdm-'

  # @author qitang@redhat.com
  @admin
  @destructive
  @commonlogging
  Scenario Outline: Make sure the security index that is created upon pod start
    When I wait for the "<index_name>" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['docs.count'] > "0"
    Examples:
      | index_name   |
      | .searchguard | # @case_id OCP-20694
      | .security    | # @case_id OCP-30199

  # @author qitang@redhat.com
  # @case_id OCP-21099
  @admin
  @destructive
  @commonlogging
  Scenario: Access Elasticsearch prometheus Endpoints via token
    Given I switch to the first user
    And the first user is cluster-admin
    Then I use the "openshift-logging" project
    Given evaluation of `service("elasticsearch-metrics").ip` is stored in the :service_ip clipboard
    And evaluation of `service("elasticsearch-metrics").port(name: 'elasticsearch')` is stored in the :service_port clipboard
    Given a pod becomes ready with labels:
      | cluster-name=elasticsearch,component=elasticsearch |
    And I execute on the pod:
      | bash | -c | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" -H "Content-type: application/json" https://<%= cb.service_ip %>:<%= cb.service_port %>/_prometheus/metrics |
    Then the step should succeed
    And the output should contain:
      | es_cluster_nodes_number          |
      | es_cluster_shards_active_percent |

  # @author qitang@redhat.com
  # @case_id OCP-21313
  @admin
  @destructive
  @commonlogging
  Scenario: The default index.mode is shared_ops
    Given the master version < "4.5"
    And evaluation of `YAML.load(config_map('elasticsearch').value_of('elasticsearch.yml'))` is stored in the :data clipboard
    And the expression should be true> cb.data.dig('openshift.kibana.index.mode') == "shared_ops"

  # @author qitang@redhat.com
  # @case_id OCP-30205
  @admin
  @destructive
  @commonlogging
  Scenario: [Bug 1548038] Add .all alias when index is created
    Given the master version >= "4.5"
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
    Given I wait for the "app" index to appear in the ES pod with labels "es-node-master=true"
    And I wait for the "infra" index to appear in the ES pod with labels "es-node-master=true"
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | */_alias?pretty |
      | op           | GET             |
    Then the step should succeed
    And evaluation of ` @result[:parsed].select { |k, v| v.dig('aliases', '.all').is_a? Hash and k.start_with? 'app' }` is stored in the :res_app clipboard
    And evaluation of ` @result[:parsed].select { |k, v| v.dig('aliases', '.all').is_a? Hash and k.start_with? 'infra' }` is stored in the :res_infra clipboard
    Then the expression should be true> cb.res_app.count > 0
    Then the expression should be true> cb.res_infra.count > 0

  # @author qitang@redhat.com
  # @case_id OCP-34364
  @admin
  @destructive
  Scenario: elasticsearch alerting rules test: ElasticsearchNodeDiskWatermarkReached
    Given default storageclass is stored in the :default_sc clipboard
    Given I obtain test data file "logging/clusterlogging/clusterlogging-storage-template.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                 |
      | crd_yaml            | clusterlogging-storage-template.yaml |
      | storage_class       | <%= cb.default_sc.name %>            |
      | storage_size        | 5Gi                                  |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | es-node-master=true |
    When I execute on the pod:
      | dd | if=/dev/urandom | of=/elasticsearch/persistent/file.txt | bs=1048576 | count=4500 |
    Then the step should succeed
    And I wait up to 360 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                                            |
      | query | ALERTS{alertname="ElasticsearchNodeDiskWatermarkReached"} |
    Then the step should succeed
    And the output should match:
      | "alertstate":"pending\|firing" |
    """

  # @author qitang@redhat.com
  @admin
  @destructive
  @commonlogging
  Scenario Outline: Elasticsearch alert rules validation testing
    Given evaluation of `<alert_names>` is stored in the :alerts clipboard
    Given 5 seconds have passed
    Given I repeat the following steps for each :alert in cb.alerts:
    """
    Given I use the "openshift-logging" project
    And evaluation of `prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: '#{cb.alert}').expr.split('>')[0]` is stored in the :expr clipboard
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query? |
      | query | #{cb.expr}     |
    Then the step should succeed
    And the expression should be true>  @result[:parsed]["data"]["result"].count > 0
    """

    Examples:
      | alert_names                                                                                      |
      | ["ElasticsearchJVMHeapUseHigh", "AggregatedLoggingSystemCPUHigh", "ElasticsearchProcessCPUHigh"] | # @case_id OCP-22314
      | ["ElasticsearchBulkRequestsRejectionJumps"]                                                      | # @case_id OCP-22311

  # @author qitang@redhat.com
  # @case_id OCP-35767
  @admin
  @destructive
  @commonlogging
  Scenario: elasticsearch alerting rules test: ElasticsearchWriteRequestsRejectionJumps
    Given I use the "openshift-logging" project
    And evaluation of `prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: 'ElasticsearchWriteRequestsRejectionJumps').expr.split('>')[0]` is stored in the :expr clipboard
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query? |
      | query | <%= cb.expr %> |
    Then the step should succeed
    And the expression should be true>  @result[:parsed]["data"]["result"].count > 0
    """

  # @author qitang@redhat.com
  # @case_id OCP-33698
  @admin
  @destructive
  @commonlogging
  Scenario: [BZ1865364]elasticsearch alerting rules test: Cluster low on disk space/High file descriptor usage.
    Given evaluation of `["ElasticsearchHighFileDescriptorUsage", "ElasticsearchDiskSpaceRunningLow"]` is stored in the :alerts clipboard
    And I repeat the following steps for each :alert in cb.alerts:
    """
    Given I use the "openshift-logging" project
    And evaluation of `prometheus_rule('elasticsearch-prometheus-rules').prometheus_rule_group_spec(name: "logging_elasticsearch.alerts").rule_spec(alert: '#{cb.alert}').expr.split('<')[0]` is stored in the :expr clipboard
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query? |
      | query | #{cb.expr}     |
    Then the step should succeed
    And the expression should be true>  @result[:parsed]["data"]["result"].count > 0
    """
