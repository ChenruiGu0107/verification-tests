@clusterlogging
Feature: cluster log forwarder testing

  # @author qitang@redhat.com
  # @case_id OCP-32365
  @admin
  @destructive
  Scenario: ClusterLogForwarder invalid CRs testing
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given evaluation of `["clf-missing-required-value.yaml", "clf-invalid-forward-type.yaml", "clf-invalid-name.yaml", "clf-url-checking.yaml"]` is stored in the :clf_yaml_files clipboard
    Given I repeat the following steps for each :clf_yaml in cb.clf_yaml_files:
    """
    Given I obtain test data file "logging/clusterlogforwarder/#{cb.clf_yaml}"
    When I run the :create client command with:
      | f | #{cb.clf_yaml} |
    Then the step should fail
    And the output should contain:
      | The ClusterLogForwarder "instance |
      | " is invalid                      |
    """

  # @author qitang@redhat.com
  # @case_id OCP-32127
  @admin
  @destructive
  Scenario: Couldn't add `outputs` named `default` in ClusterLogForwarder
    Given I switch to the first user
    And I have a project
    And evaluation of `project` is stored in the :fluentd_proj clipboard
    Given fluentd receiver is deployed as insecure in the "<%= cb.fluentd_proj.name %>" project

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I obtain test data file "logging/clusterlogging/example_indexmanagement.yaml"
    When I create clusterlogging instance with:
      | remove_logging_pods | true                         |
      | crd_yaml            | example_indexmanagement.yaml |
    Then the step should succeed

    Given admin ensures "instance" cluster_log_forwarder is deleted from the "openshift-logging" project after scenario
    Given I obtain test data file "logging/clusterlogforwarder/clf-invalid-output-name.yaml"
    When I process and create:
      | f | clf-invalid-output-name.yaml |
      | p | URL=udp://fluentdserver.<%= cb.fluentd_proj.name %>.svc:24224 |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
      Given the expression should be true> cluster_log_forwarder('instance').outputs_status(cached: false)["output_0_"][0]['message'] == "output name \"default\" is reserved"
    """

  # @author qitang@redhat.com
  # @case_id OCP-32629
  @admin
  @destructive
  Scenario: Only collect app logs on pre-defined namespaces
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I obtain test data file "logging/clusterlogforwarder/clf-forward-with-pre-defined-namespaces.yaml"
    And admin ensures "instance" cluster_log_forwarder is deleted from the "openshift-logging" project after scenario
    When I run the :create client command with:
      | f | clf-forward-with-pre-defined-namespaces.yaml |
    Then the step should succeed
    Given I obtain test data file "logging/clusterlogging/example_indexmanagement.yaml"
    When I create clusterlogging instance with:
      | remove_logging_pods | true                         |
      | crd_yaml            | example_indexmanagement.yaml |
    Then the step should succeed
    Given I switch to the first user
    And evaluation of `["logging-test-project4", "logging-test-project3", "logging-test-project2", "logging-test-project1"]` is stored in the :project_names clipboard
    And I obtain test data file "logging/loggen/container_json_log_template.json"
    Given I repeat the following steps for each :project_name in cb.project_names:
    """
    When I run the :new_project client command with:
      | project_name | #{cb.project_name} |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    """
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait up to 600 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | app*/_search?pretty&size=0' -d'{"aggs":{"distinct_namespace_name":{"terms":{"field":"kubernetes.namespace_name"}}}} |
      | op           | GET                                                                                                                 |
    Then the step should succeed
    And the output should contain:
      | logging-test-project1 |
      | logging-test-project2 |
    And the output should not contain:
      | logging-test-project3 |
      | logging-test-project4 |
    """

  # @author qitang@redhat.com
  # @case_id OCP-39124
  @admin
  @destructive
  Scenario: [BZ 1890072]ClusterLogForwarder: Forward logs to different outputs with same secret
    Given I switch to the first user
    And I have a project
    And evaluation of `project.name` is stored in the :servers_ns clipboard
    And I generate certs for the "servers" receiver in the "<%= cb.servers_ns %>" project
    When I run the :create_secret client command with:
      | name         | fluentdserver            |
      | secret_type  | generic                  |
      | from_file    | tls.key=logging-es.key   |
      | from_file    | tls.crt=logging-es.crt   |
      | from_file    | ca-bundle.crt=ca.crt     |
      | from_file    | ca.key=ca.key            |
      | from_literal | shared_key=fluentdserver |
    Then the step should succeed
    When I run the :create_secret client command with:
      | name        | elasticsearch-server                |
      | secret_type | generic                             |
      | from_file   | logging-es.key=logging-es.key       |
      | from_file   | logging-es.crt=logging-es.crt       |
      | from_file   | elasticsearch.key=elasticsearch.key |
      | from_file   | elasticsearch.crt=elasticsearch.crt |
      | from_file   | admin-ca=ca.crt                     |
    Then the step should succeed
    Given I create the serviceaccount "servers"
    And SCC "privileged" is added to the "system:serviceaccount:<%= cb.servers_ns %>:servers" service account
    Given evaluation of `["cm-elasticsearch.yaml", "cm-fluentd.yaml", "deploy-es-fluentd-in-same-pod.yaml"]` is stored in the :files clipboard
    And I repeat the following steps for each :file in cb.files:
    """
      Given I obtain test data file "logging/clusterlogforwarder/forward_with_same_secret/#{cb.file}"
      When I run the :create client command with:
        | f | #{cb.file} |
      Then the step should succeed
    """
    When I run the :expose client command with:
      | name          | servers    |
      | resource      | deployment |
      | resource_name | servers    |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | component=servers |

    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I create a pipeline secret with:
      | secret_name | pipelinesecret |
      | auth_type   | mTLS_share     |
      | shared_key  | fluentdserver  |
    Given admin ensures "instance" cluster_log_forwarder is deleted from the "openshift-logging" project after scenario
    And I obtain test data file "logging/clusterlogforwarder/forward_with_same_secret/clf.yaml"
    When I process and create:
      | f | clf.yaml                                                 |
      | p | FLUENTD_URL=tls://servers.<%= cb.servers_ns %>.svc:24224 |
      | p | ES_URL=tls://servers.<%= cb.servers_ns %>.svc:9200       |
    Then the step should succeed
    And I wait for the "instance" cluster_log_forwarder to appear

    Given I obtain test data file "logging/clusterlogging/fluentd_only.yaml"
    When I create clusterlogging instance with:
      | remove_logging_pods | true              |
      | crd_yaml            | fluentd_only.yaml |
    Then the step should succeed

    Given I use the "<%= cb.servers_ns %>" project
    And a pod becomes ready with labels:
      | component=servers |
    And evaluation of `pod.name` is stored in the :server_pod clipboard

    #check logs in elasticsearch server
    And I wait up to 300 seconds for the steps to pass:
    """
    # should not have app/infra logs in elasticsearch-server
    When I run the :exec admin command with:
      | pod              | <%= cb.server_pod %> |
      | c                | elasticsearch-server |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -sk -XGET "https://localhost:9200/*/_count?format=JSON" -H "Content-Type: application/json" -d '{"query": {"exists": {"field": "systemd"}}}' |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:stdout])['count'] == 0

    When I run the :exec admin command with:
      | pod              | <%= cb.server_pod %> |
      | c                | elasticsearch-server |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -sk -XGET "https://localhost:9200/*/_count?format=JSON" -H "Content-Type: application/json" -d '{"query": {"exists": {"field": "kubernetes.namespace_name"}}}' |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:stdout])['count'] == 0

    # check audit logs in elasticsearch-server
    When I run the :exec admin command with:
      | pod              | <%= cb.server_pod %> |
      | c                | elasticsearch-server |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -sk -XGET "https://localhost:9200/*/_count?format=JSON" -H "Content-Type: application/json" -d '{"query": {"exists": {"field": "auditID"}}}' |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:stdout])['count'] > 0
    """

    # check logs in fluentd server
    Given I wait up to 300 seconds for the steps to pass:
    """
      When I run the :exec admin command with:
        | pod              | <%= cb.server_pod %> |
        | c                | fluentdserver        |
        | oc_opts_end      |                      |
        | exec_command     | sh                   |
        | exec_command_arg | -c                   |
        | exec_command_arg | ls -l /fluentd/log   |
      Then the step should succeed
      Then the output should contain:
        | app.log             |
        | infra.log           |
        | infra-container.log |
      And the output should not contain:
        | audit.log           |
    """
