@clusterlogging
@commonlogging
Feature: elasticsearch related tests

  # @author qitang@redhat.com
  # @case_id OCP-21390
  @admin
  @destructive
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
  Scenario: The default index.mode is shared_ops
    Given the master version < "4.5"
    And evaluation of `YAML.load(config_map('elasticsearch').value_of('elasticsearch.yml'))` is stored in the :data clipboard
    And the expression should be true> cb.data.dig('openshift.kibana.index.mode') == "shared_ops"

  # @author qitang@redhat.com
  # @case_id OCP-30205
  @admin
  @destructive
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
