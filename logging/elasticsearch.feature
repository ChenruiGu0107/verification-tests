@clusterlogging @commonlogging
Feature: elasticsearch related tests

  # @author pruan@redhat.com
  # @case_id OCP-15281
  @admin
  @destructive
  Scenario: max_local_storage_nodes default value should be 1 to prevent permitting multiple nodes to share the same data directory
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And evaluation of `YAML.load(config_map('elasticsearch').value_of('elasticsearch.yml'))` is stored in the :data clipboard
    And the expression should be true> cb.data.dig('node', 'max_local_storage_nodes') == 1
    And the expression should be true> cb.data.dig('gateway','recover_after_nodes') == cb.data.dig('discovery.zen','minimum_master_nodes')

  # @author pruan@redhat.com
  # @case_id OCP-16850
  @admin
  @destructive
  Scenario: Check the existence of index template named "viaq"
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And evaluation of `%w(project operations)` is stored in the :urls clipboard
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
      | app_repo | httpd-example |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And I wait for the "project.<%= cb.org_project.name %>" index to appear in the ES pod with labels "es-node-master=true"
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
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
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
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    When I wait for the ".searchguard" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['docs.count'] > "0"
    When I wait for the ".operations." index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['docs.count'] > "0"
