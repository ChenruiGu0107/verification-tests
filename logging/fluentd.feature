@clusterlogging
Feature: fluentd related tests
  # @author pruan@redhat.com
  # @case_id OCP-20242
  @admin
  @destructive
  @commonlogging
  Scenario: [intservice] [bz1399761] Logging fluentD daemon set should set quota for the pods
    Given a pod becomes ready with labels:
      | component=fluentd |
    And evaluation of `pod.container(user: user, name: 'fluentd').spec.memory_limit` is stored in the :fluentd_pod_mem_limit clipboard
    And evaluation of `daemon_set('fluentd').container_spec(user: user, name: 'fluentd').memory_limit` is stored in the :fluentd_container_mem_limit clipboard
    Then the expression should be true> cb.fluentd_container_mem_limit[1] == cb.fluentd_pod_mem_limit[1]

  # @author pruan@redhat.com
  @admin
  @destructive
  @commonlogging
  Scenario Outline: special message type testing
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project clipboard
    Given I obtain test data file "logging/loggen/<file>"
    When I run the :new_app client command with:
      | file | <file> |
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
      | container_json_unicode_log_template.json | "ㄅㄉˇˋㄓˊ˙ㄚㄞㄢㄦㄆ 中国 883.317µs ā á ǎ à ō ó ▅ ▆ ▇ █ 々" | # @case_id OCP-24563

  # @author qitang@redhat.com
  # @case_id OCP-21083
  @admin
  @destructive
  @commonlogging
  Scenario: the priority class are added in Logging collector
    Given the expression should be true> daemon_set('fluentd').template['spec']['priorityClassName'] == "cluster-logging"

  # @author qitang@redhat.com
  # @case_id OCP-22985
  @admin
  @destructive
  @commonlogging
  Scenario: Properly handle merge of JSON log messages - fluentd
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
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
  @commonlogging
  Scenario: The pod label and annotation in Elasticsearch
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
    Given I wait for the project "<%= cb.proj.name %>" logs to appear in the ES pod
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | app-*/_search?pretty' -d '{"query": {"match": {"kubernetes.namespace_name": "<%= cb.proj.name %>"}}} |
      | op           | GET                                                                                                  |
    Then the step should succeed
    And the expression should be true> (@result[:parsed]['hits']['hits'].first['_source']['kubernetes']['flat_labels'] - ["run=centos-logtest", "test=centos-logtest"]).empty?

  # @author qitang@redhat.com
  # @case_id OCP-24377
  @admin
  @destructive
  @commonlogging
  Scenario: Fluentd pod should reconnect to Elasticsearch.
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj_1 clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=centos-logtest,test=centos-logtest |
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    Given I wait for the project "<%= cb.proj_1.name %>" logs to appear in the ES pod
    When I run the :delete client command with:
      | object_type | pod                     |
      | l           | component=elasticsearch |
    Then the step should succeed
    Given I wait until ES cluster is ready
    # create a new project to generate some logs, and check if the fluentd could send logs to the new ES pod
    Given I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj_2 clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=centos-logtest,test=centos-logtest |
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And I wait for the project "<%= cb.proj_2.name %>" logs to appear in the ES pod
    Then the step should succeed

  # @author qitang@redhat.com
  @admin
  @destructive
  @commonlogging
  Scenario Outline: Fluentd alert rules validation testing
    Given evaluation of `prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: '<alert_name>').expr.split('>')[0].gsub("\n","")` is stored in the :expr clipboard
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query? |
      | query | <%= cb.expr %> |
    Then the step should succeed
    And the expression should be true>  @result[:parsed]["data"]["result"].count > 0
    """

    Examples:
      | alert_name                   |
      | FluentdQueueLengthBurst      | # @case_id OCP-23739
      | FluentdQueueLengthIncreasing | # @case_id OCP-23740
      | FluentDHighErrorRate         | # @case_id OCP-33871
