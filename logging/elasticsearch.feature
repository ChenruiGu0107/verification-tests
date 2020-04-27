@clusterlogging
@commonlogging
Feature: elasticsearch related tests

  # @author pruan@redhat.com
  # @case_id OCP-15281
  @admin
  @destructive
  Scenario: max_local_storage_nodes default value should be 1 to prevent permitting multiple nodes to share the same data directory
    Given evaluation of `YAML.load(config_map('elasticsearch').value_of('elasticsearch.yml'))` is stored in the :data clipboard
    And the expression should be true> cb.data.dig('node', 'max_local_storage_nodes') == 1
    And the expression should be true> cb.data.dig('gateway','recover_after_nodes') == cb.data.dig('discovery.zen','minimum_master_nodes')

  # @author pruan@redhat.com
  # @case_id OCP-16850
  @admin
  @destructive
  Scenario: Check the existence of index template named "viaq"
    Given evaluation of `%w(project operations)` is stored in the :urls clipboard
    Given I repeat the following steps for each :url in cb.urls:
    """
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | _template/com.redhat.viaq-openshift-#{cb.url}.template.json |
      | op           | GET                                                         |
    Then the step should succeed
    """

  # @author pruan@redhat.com
  # @case_id OCP-19205
  @admin
  @destructive
  Scenario: Add .all alias when index is created
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project` is stored in the :org_project clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/testdata/logging/loggen/container_json_unicode_log_template.json |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    #A workaround to https://bugzilla.redhat.com/show_bug.cgi?id=1776594
    Given I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | .operations.* |
      | op           | DELETE        |
    Then the step should succeed
    Given I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.* |
      | op           | DELETE    |
    Then the step should succeed
    #Workaround end

    Given I wait for the "project.<%= cb.org_project.name %>" index to appear in the ES pod with labels "es-node-master=true"
    And I wait for the ".operations" index to appear in the ES pod with labels "es-node-master=true"
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | */_alias?pretty |
      | op           | GET             |
    Then the step should succeed
    And evaluation of ` @result[:parsed].select { |k, v| v.dig('aliases', '.all').is_a? Hash and k.start_with? 'project' }` is stored in the :res_proj clipboard
    And evaluation of ` @result[:parsed].select { |k, v| v.dig('aliases', '.all').is_a? Hash and k.start_with? '.operation' }` is stored in the :res_op clipboard
    Then the expression should be true> cb.res_proj.count > 0
    Then the expression should be true> cb.res_op.count > 0

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
  # @case_id OCP-20694
  @admin
  @destructive
  Scenario: Make sure the searchguard index that is created upon pod start
    When I wait for the ".searchguard" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['docs.count'] > "0"
    When I wait for the ".operations." index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['docs.count'] > "0"

  # @author qitang@redhat.com
  # @case_id OCP-21099
  @admin
  @destructive
  Scenario: Access Elasticsearch prometheus Endpoints via token
    Given I switch to the first user
    And the first user is cluster-admin
    Then I use the "openshift-logging" project
    Given evaluation of `service("elasticsearch-metrics").ip` is stored in the :service_ip clipboard
    Given a pod becomes ready with labels:
      | cluster-name=elasticsearch,component=elasticsearch |
    And I execute on the pod:
      | bash | -c | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" -H "Content-type: application/json" https://<%= cb.service_ip %>:60000/_prometheus/metrics |
    Then the step should succeed
    And the output should contain:
      | es_cluster_nodes_number                   |
      | es_cluster_shards_active_percent          |

  # @author qitang@redhat.com
  # @case_id OCP-21313
  @admin
  @destructive
  Scenario: The default index.mode is shared_ops
    And evaluation of `YAML.load(config_map('elasticsearch').value_of('elasticsearch.yml'))` is stored in the :data clipboard
    And the expression should be true> cb.data.dig('openshift.kibana.index.mode') == "shared_ops"
