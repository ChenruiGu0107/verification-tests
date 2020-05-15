@clusterlogging
@commonlogging
Feature: fluentd related tests
  # @author pruan@redhat.com
  # @case_id OCP-20242
  @admin
  @destructive
  Scenario: [intservice] [bz1399761] Logging fluentD daemon set should set quota for the pods
    Given a pod becomes ready with labels:
      | component=fluentd |
    And evaluation of `pod.container(user: user, name: 'fluentd').spec.memory_limit` is stored in the :fluentd_pod_mem_limit clipboard
    And evaluation of `daemon_set('fluentd').container_spec(user: user, name: 'fluentd').memory_limit` is stored in the :fluentd_container_mem_limit clipboard
    Then the expression should be true> cb.fluentd_container_mem_limit[1] == cb.fluentd_pod_mem_limit[1]

  # @author pruan@redhat.com
  # @case_id OCP-10995
  @admin
  @destructive
  Scenario: Check fluentd changes for common data model and index naming
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project` is stored in the :org_project clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/loggen/container_json_log_template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=centos-logtest,test=centos-logtest |
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    When I wait 600 seconds for the "project.<%= cb.org_project.name %>" index to appear in the ES pod with labels "es-node-master=true"
    And the expression should be true> cb.proj_index_regex = /project.#{cb.org_project.name}.#{cb.org_project.uid}.(\d{4}).(\d{2}).(\d{2})/
    And the expression should be true> cb.op_index_regex = /.operations.(\d{4}).(\d{2}).(\d{2})/
    Given I log the message> <%= cb.index_data['index'] %>
    And the expression should be true> cb.proj_index_regex.match(cb.index_data['index'])
    And I wait for the ".operations" index to appear in the ES pod with labels "es-node-master=true"
    Given I log the message> <%= cb.index_data['index'] %>
    And the expression should be true> cb.op_index_regex.match(cb.index_data['index'])

  # @author pruan@redhat.com
  @admin
  @destructive
  Scenario Outline: special message type testing
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/loggen/<file> |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    Then I wait up to 600 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | */_search?pretty' -d '{"query": {"match": {"kubernetes.namespace_name": "<%= cb.org_project %>"}}} |
      | op           | GET                                                                                                |
    Then the expression should be true> @result[:parsed]['hits']['hits'].last["_source"]["message"].include? <message>
    """
    Examples:
      | file                                     | message                                                  |
      | container_json_event_log_template.json   | "anlieventevent"                                         | # @case_id OCP-19431
      | container_json_unicode_log_template.json | "ㄅㄉˇˋㄓˊ˙ㄚㄞㄢㄦㄆ 中国 883.317µs ā á ǎ à ō ó ▅ ▆ ▇ █ 々" | # @case_id OCP-24563

  # @author qitang@redhat.com
  # @case_id OCP-21083
  @admin
  @destructive
  Scenario: the priority class are added in Logging collector
    Given the expression should be true> daemon_set('fluentd').template['spec']['priorityClassName'] == "cluster-logging"

  # @author qitang@redhat.com
  # @case_id OCP-22985
  @admin
  @destructive
  Scenario: Properly handle merge of JSON log messages - fluentd
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/loggen/container_json_log_template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=centos-logtest,test=centos-logtest |
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait 600 seconds for the "project.<%= cb.org_project %>" index to appear in the ES pod with labels "es-node-master=true"
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.org_project %>*/_search?pretty' -d'{"size": 2,"sort": [{"@timestamp": {"order":"desc"}}]} |
      | op           | GET                                                                                                      |
    Then the step should succeed
    And the output should contain:
      | "message" : "{\"message\": \"MERGE_JSON_LOG=true\", \"level\": \"debug\",\"Layer1\": \"layer1 0\",      |
      | \"layer2\": {\"name\":\"Layer2 1\", \"tips\":\"Decide by PRESERVE_JSON_LOG\"}, \"StringNumber\":\"10\", |
      | \"Number\": 10,\"foo.bar\":\"Dot Item\",\"{foobar}\":\"Brace Item\",                                    |
      | \"[foobar]\":\"Bracket Item\", \"foo:bar\":\"Colon Item\",\"foo bar\":\"Space Item\" }",                |
    Given I register clean-up steps:
    """
    When I run the :patch client command with:
      | resource      | clusterlogging                           |
      | resource_name | instance                                 |
      | p             | {"spec": {"managementState": "Managed"}} |
      | type          | merge                                    |
    Then the step should succeed
    """
    When I run the :patch client command with:
      | resource      | clusterlogging                             |
      | resource_name | instance                                   |
      | p             | {"spec": {"managementState": "Unmanaged"}} |
      | type          | merge                                      |
    Then the step should succeed

    # MERGE_JSON_LOG=true
    When I run the :set_env client command with:
      | resource | ds/fluentd          |
      | e        | MERGE_JSON_LOG=true |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    Given the expression should be true> daemon_set('fluentd').replica_counters(cached: false)[:desired] == daemon_set('fluentd').replica_counters(cached: false)[:updated_scheduled]
    And the expression should be true> daemon_set('fluentd').replica_counters(cached: false)[:desired] == daemon_set('fluentd').replica_counters(cached: false)[:available]
    """
    And I wait up to 180 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.org_project %>*/_search?pretty' -d'{"size": 2,"sort": [{"@timestamp": {"order":"desc"}}]} |
      | op           | GET                                                                                                      |
    Then the step should succeed
    And the output should contain:
      | "message" : "MERGE_JSON_LOG=true",         |
      | "Layer1" : "layer1 0",                     |
      |   "layer2" : {                             |
      |     "name" : "Layer2 1",                   |
      |     "tips" : "Decide by PRESERVE_JSON_LOG" |
      |   },                                       |
      |   "StringNumber" : "10",                   |
      |   "Number" : 10,                           |
      |   "foo.bar" : "Dot Item",                  |
      |   "{foobar}" : "Brace Item",               |
      |   "[foobar]" : "Bracket Item",             |
      |   "foo:bar" : "Colon Item",                |
      |   "foo bar" : "Space Item",                |
    """

    # MERGE_JSON_LOG=true CDM_UNDEFINED_TO_STRING=true
    When I run the :set_env client command with:
      | resource | ds/fluentd                   |
      | e        | CDM_UNDEFINED_TO_STRING=true |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    Given the expression should be true> daemon_set('fluentd').replica_counters(cached: false)[:desired] == daemon_set('fluentd').replica_counters(cached: false)[:updated_scheduled]
    And the expression should be true> daemon_set('fluentd').replica_counters(cached: false)[:desired] == daemon_set('fluentd').replica_counters(cached: false)[:available]
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.org_project %>* |
      | op           | DELETE                         |
    Then the step should succeed
    And the output should contain:
      | "acknowledged":true |
    Given I wait 600 seconds for the "project.<%= cb.org_project %>" index to appear in the ES pod with labels "es-node-master=true"
    And I wait up to 180 seconds for the steps to pass:
    """
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.org_project %>*/_search?pretty' -d'{"size": 2,"sort": [{"@timestamp": {"order":"desc"}}]} |
      | op           | GET                                                                                                      |
    Then the step should succeed
    And the output should contain:
      | "message" : "MERGE_JSON_LOG=true",                                                     |
      | "Layer1" : "layer1 0",                                                                 |
      | "layer2" : "{\\"name\\":\\"Layer2 1\\",\\"tips\\":\\"Decide by PRESERVE_JSON_LOG\\"}", |
      | "StringNumber" : "10",                                                                 |
      | "Number" : "10",                                                                       |
      | "foo.bar" : "Dot Item",                                                                |
      | "{foobar}" : "Brace Item",                                                             |
      | "[foobar]" : "Bracket Item",                                                           |
      | "foo:bar" : "Colon Item",                                                              |
      | "foo bar" : "Space Item",                                                              |
    """

    # MERGE_JSON_LOG=true CDM_UNDEFINED_TO_STRING=true CDM_UNDEFINED_DOT_REPLACE_CHAR=_
    When I run the :set_env client command with:
      | resource | ds/fluentd                       |
      | e        | CDM_UNDEFINED_DOT_REPLACE_CHAR=_ |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    Given the expression should be true> daemon_set('fluentd').replica_counters(cached: false)[:desired] == daemon_set('fluentd').replica_counters(cached: false)[:updated_scheduled]
    And the expression should be true> daemon_set('fluentd').replica_counters(cached: false)[:desired] == daemon_set('fluentd').replica_counters(cached: false)[:available]
    """

    And I wait up to 180 seconds for the steps to pass:
    """
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.org_project %>*/_search?pretty' -d'{"size": 2,"sort": [{"@timestamp": {"order":"desc"}}]} |
      | op           | GET                                                                                                      |
    Then the step should succeed
    And the output should contain:
      | "message" : "MERGE_JSON_LOG=true",                                             |
      | "Layer1" : "layer1 0",                                                         |
      | "layer2" : "{\"name\":\"Layer2 1\",\"tips\":\"Decide by PRESERVE_JSON_LOG\"}", |
      |   "StringNumber" : "10",                                                       |
      |   "Number" : "10",                                                             |
      |   "foo_bar" : "Dot Item",                                                      |
      |   "{foobar}" : "Brace Item",                                                   |
      |   "[foobar]" : "Bracket Item",                                                 |
      |   "foo:bar" : "Colon Item",                                                    |
      |   "foo bar" : "Space Item",                                                    |
    """

    # MERGE_JSON_LOG=true CDM_UNDEFINED_TO_STRING=true CDM_UNDEFINED_DOT_REPLACE_CHAR=_ CDM_UNDEFINED_MAX_NUM_FIELDS=5
    When I run the :set_env client command with:
      | resource | ds/fluentd                     |
      | e        | CDM_UNDEFINED_MAX_NUM_FIELDS=5 |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    Given the expression should be true> daemon_set('fluentd').replica_counters(cached: false)[:desired] == daemon_set('fluentd').replica_counters(cached: false)[:updated_scheduled]
    And the expression should be true> daemon_set('fluentd').replica_counters(cached: false)[:desired] == daemon_set('fluentd').replica_counters(cached: false)[:available]
    """

    And I wait up to 180 seconds for the steps to pass:
    """
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.org_project %>*/_search?pretty' -d'{"size": 2,"sort": [{"@timestamp": {"order":"desc"}}]} |
      | op           | GET                                                                                                      |
    Then the step should succeed
    And the output should contain:
      | "message" : "MERGE_JSON_LOG=true",                                                                                   |
      | "undefined" : "{\"Layer1\":\"layer1 0\",\"layer2\":{\"name\":\"Layer2 1\",\"tips\":\"Decide by PRESERVE_JSON_LOG\"}, |
      | \"StringNumber\":\"10\",\"Number\":10,\"foo.bar\":\"Dot Item\",\"{foobar}\":\"Brace Item\",                          |
      | \"[foobar]\":\"Bracket Item\",\"foo:bar\":\"Colon Item\",\"foo bar\":\"Space Item\"}",                               |
    """

  # @author qitang@redhat.com
  # @case_id OCP-30196
  @admin
  @destructive
  Scenario: The pod label and annotation in Elasticsearch
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/loggen/container_json_log_template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=centos-logtest,test=centos-logtest |
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    Given I wait for the project "<%= cb.proj.name %>" logs to appear in the ES pod
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | app-*/_search?pretty' -d '{"query": {"match": {"kubernetes.namespace_name": "<%= cb.proj.name %>"}}} |
      | op           | GET                                                                                                  |
    Then the step should succeed
    And the expression should be true> (@result[:parsed]['hits']['hits'].first['_source']['kubernetes']['flat_labels'] - ["run=centos-logtest", "test=centos-logtest"]).empty?
