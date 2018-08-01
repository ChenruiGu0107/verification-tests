Feature: elasticsearch related tests
  # @author chunchen@redhat.com
  # @case_id OCP-11186
  @admin
  @smoke
  @destructive
  Scenario: Scale up kibana and elasticsearch pods
    Given I have a project
    Given the master version < "3.5"
    And I store default router subdomain in the :subdomain clipboard
    And I store master major version in the :master_version clipboard
    When I run the :new_secret client command with:
      | secret_name     | logging-deployer  |
      | credential_file | nothing=/dev/null |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc509059/sa.yaml |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                                                       |
      | user_name | system:serviceaccount:<%= project.name %>:logging-deployer |
    Then the step should succeed
    Given cluster role "cluster-reader" is added to the "aggregated-logging-fluentd" service account
    When I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | privileged                                                           |
      | user_name | system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd |
    Then the step should succeed
    Given I register clean-up steps:
    """
    I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc       | privileged                                                           |
      | user_name | system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd |
    the step should succeed
    """
    When I create a new application with:
      | template | logging-deployer-template                                                                                                                                                                                                                                       |
      | param    | IMAGE_PREFIX=<%= product_docker_repo %>openshift3/,KIBANA_HOSTNAME=kibana.<%= cb.subdomain%>,PUBLIC_MASTER_URL=<%= env.api_endpoint_url %>,ES_INSTANCE_RAM=1024M,ES_CLUSTER_SIZE=1,IMAGE_VERSION=<%= cb.master_version%>,MASTER_URL=<%= env.api_endpoint_url %> |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource  | templates |
    Then the output should contain "logging-support-template"
    """
    And the first user is cluster-admin
    Given I register clean-up steps:
    """
    I switch to cluster admin pseudo user
    I use the "<%=project.name%>" project
    I run the :delete admin command with:
      | object_type       | oauthclients      |
      | object_name_or_id | kibana-proxy      |
      | n                 | <%=project.name%> |
    I wait for the resource "oauthclient" named "kibana-proxy" to disappear
    """
    When I create a new application with:
      | template | logging-support-template |
      | n        | <%= project.name %>      |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams                                                                     |
      | resource_name | logging-fluentd                                                                  |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | logging-fluentd:<%= cb.master_version%>                                      |
      | from       | <%= product_docker_repo %>openshift3/logging-fluentd:<%= cb.master_version%> |
      | insecure   | true                                                                         |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams                                                                     |
      | resource_name | logging-elasticsearch                                                            |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | logging-elasticsearch:<%= cb.master_version%>                                      |
      | from       | <%= product_docker_repo %>openshift3/logging-elasticsearch:<%= cb.master_version%> |
      | insecure   | true                                                                               |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams                                                                     |
      | resource_name | logging-auth-proxy                                                               |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | logging-auth-proxy:<%= cb.master_version%>                                      |
      | from       | <%= product_docker_repo %>openshift3/logging-auth-proxy:<%= cb.master_version%> |
      | insecure   | true                                                                            |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams                                                                     |
      | resource_name | logging-kibana                                                                   |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | logging-kibana:<%= cb.master_version%>                                      |
      | from       | <%= product_docker_repo %>openshift3/logging-kibana:<%= cb.master_version%> |
      | insecure   | true                                                                        |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project replicationcontrollers
    Then the output should contain:
      | logging-fluentd-1 |
      | logging-kibana-1  |
    """
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | logging-kibana-1       |
      | replicas | 2                      |
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | logging-fluentd-1      |
      | replicas | 1                      |
    And I wait until number of replicas match "1" for replicationController "logging-fluentd-1"
    And I wait until number of replicas match "2" for replicationController "logging-kibana-1"
    Given a pod becomes ready with labels:
      | component=es |
    And I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | pods/<%= pod.name %>|
    Then the output should match:
      | \[<%= project.name %>\.\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\.\d{4}\.\d{2}\.\d{2}\] |
    """

  # @author pruan@redhat.com
  # @case_id OCP-13700
  @admin
  @destructive
  Scenario: Make sure the searchguard index that is created upon pod start worked fine
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And a deploymentConfig becomes ready with labels:
      | component=es |
    And I wait up to 240 seconds for the steps to pass:
    """"
    When I get the ".searchguard.<%= dc.name %>" logging index information from a pod with labels "component=es"
    Then the expression should be true> cb.index_data['docs.count'] == "5"
    """
    And the expression should be true> convert_to_bytes(cb.index_data['store.size']) > 0
    # check operation and project.install-test.xxx index
    When I wait for the ".operations." index to appear in the ES pod
    Then the expression should be true> convert_to_bytes(cb.index_data['store.size']) > 10
    When I wait for the "project.install-test." index to appear in the ES pod
    Then the expression should be true> convert_to_bytes(cb.index_data['store.size']) > 10

  # @author pruan@redhat.com
  # @case_id OCP-16688
  @admin
  @destructive
  Scenario: The journald log can be retrived from elasticsearch
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And I run commands on the host:
      | logger --tag deadbeef[123] deadbeef-message-OCP16688 |
    Then the step should succeed
    ### hack alert with 3.9, I get inconsistent behavior such that the data is
    # not pushed w/o removing the  es-containers.log.pos journal.pos files
    And I run commands on the host:
      | rm -f /var/log/journal.pos         |
      | rm -f /var/log/es-containers-*.pos |
    Then the step should succeed
    And I wait up to 600 seconds for the steps to pass:
    """
    And I perform the HTTP request on the ES pod:
      | relative_url | _search?pretty&size=5&q=message:deadbeef-message-OCP16688 |
      | op           | GET                                                       |

    And the expression should be true> @result[:parsed]['hits']['hits'][0]['_source']['message'] == 'deadbeef-message-OCP16688'
    """
    And evaluation of `@result[:parsed]['hits']['hits'][0]['_source']` is stored in the :query_res clipboard
    Then the expression should be true> (["hostname", "@timestamp"] - cb.query_res.keys).empty?
    # check for SYSLOG, SYSLOG_IDENTIFIER
    Then the expression should be true> (["SYSLOG_FACILITY", "SYSLOG_IDENTIFIER", "SYSLOG_PID"] - cb.query_res['systemd']['u'].keys).empty?
    And the expression should be true> cb.query_res['systemd']['u']['SYSLOG_IDENTIFIER'] == 'deadbeef'
    And the expression should be true> cb.query_res['systemd']['u']['SYSLOG_PID'] == '123'

  # @author pruan@redhat.com
  # @case_id OCP-17307
  @admin
  @destructive
  Scenario: DC rollback behaviors are disabled for logging project DCs
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17307/inventory |
    And a deploymentConfig becomes ready with labels:
      | component=es |
    And the expression should be true> dc.revision_history_limit == 0

  # @author pruan@redhat.com
  # @case_id OCP-15281
  @admin
  @destructive
  Scenario: max_local_storage_nodes default value should be 1 to prevent permitting multiple nodes to share the same data directory
    Given the master version >= "3.6"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And evaluation of `YAML.load(config_map('logging-elasticsearch').value_of('elasticsearch.yml'))` is stored in the :data clipboard
    And the expression should be true> cb.data.dig('node', 'max_local_storage_nodes') == 1
    And the expression should be true> cb.data.dig('gateway','recover_after_nodes') == '${NODE_QUORUM}'

  # @author pruan@redhat.com
  # @case_id OCP-16850
  @admin
  @destructive
  Scenario: Check the existence of index template named "viaq"
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And I wait until the ES cluster is healthy
    And evaluation of `%w(project operations)` is stored in the :urls clipboard
    Given I repeat the following steps for each :url in cb.urls:
    """
    And I perform the HTTP request on the ES pod:
      | relative_url | _template/com.redhat.viaq-openshift-#{cb.url}.template.json |
      | op           | GET                                                         |
    Then the step should succeed
    """

  # @author pruan@redhat.com
  # @case_id OCP-18806
  @admin
  @destructive
  Scenario: Deploy logging with replicas Elasticsearch
    Given the master version >= "3.7"
    Given environment has at least 3 nodes
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-18806/inventory |
    And a pod becomes ready with labels:
      | component=es |
    And I wait up to 120 seconds for the steps to pass:
    """
    Then I perform the HTTP request on the ES pod:
      | relative_url | /project.install_test.*/_settings?output=JSON |
      | op           | GET                                           |
    Then the expression should be true> @result[:parsed].first[1].dig('settings', 'index', 'number_of_replicas') == "1"
    Then the expression should be true> @result[:parsed].first[1].dig('settings', 'index', 'number_of_shards') == "1"
    """

  # @author pruan@redhat.com
  # @case_id OCP-16898
  @admin
  @destructive
  Scenario: Use index names of project.project_name.project_uuid.xxx in Elasticsearch
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project_name clipboard
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    Then the step should succeed
    And logging service is installed in the system
    And a pod becomes ready with labels:
      | component=es |
    # index takes over 10 minutes to come up initially
    And I use the "<%= cb.org_project_name %>" project

    And I wait up to 900 seconds for the steps to pass:
    """
    And I execute on the pod:
      | bash                                                                    |
      | -c                                                                      |
      | ls /elasticsearch/persistent/logging-es/data/logging-es/nodes/0/indices |
    And the output should contain:
      | project.<%= project.name %>.<%= project.uid %>.<%= Time.now.strftime('%Y')%>.<%= Time.now.strftime('%m')%>.<%= Time.now.strftime('%d')%> |
    """

  # @author pruan@redhat.com
  # @case_id OCP-19205
  @admin
  @destructive
  Scenario: Add .all alias when index is created
    Given the master version >= "3.9"
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And I wait for the "project.install-test" index to appear in the ES pod with labels "component=es"
    And I wait for the ".operations" index to appear in the ES pod
    And a pod becomes ready with labels:
      | component=es |
    Then I perform the HTTP request on the ES pod:
      | relative_url | /*/_alias?output=JSON |
      | op           | GET                   |
    And evaluation of ` @result[:parsed].select { |k, v| v.dig('aliases', '.all').is_a? Hash and k.start_with? 'project' }` is stored in the :res_proj clipboard
    And evaluation of ` @result[:parsed].select { |k, v| v.dig('aliases', '.all').is_a? Hash and k.start_with? '.operation' }` is stored in the :res_op clipboard
    Then the expression should be true> cb.res_proj.count > 0
    Then the expression should be true> cb.res_op.count > 0

  # @author pruan@redhat.com
  # @case_id OCP-17529
  @admin
  @destructive
  Scenario: Expose Elasticsearch service
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17529/inventory |
    And I wait until the ES cluster is healthy
    Given I switch to the first user
    And the first user is cluster-admin
    And evaluation of `%w(es es-ops)` is stored in the :prefixes clipboard
    Given I repeat the following steps for each :prefix in cb.prefixes:
    """
    And I perform the HTTP request:
    <%= '"""' %>
      :url: https://#{cb.prefix}.<%= cb.subdomain %>/_count?output=JSON
      :method: get
      :headers:
        :Authorization: Bearer <%= user.cached_tokens.first %>
    <%= '"""' %>
    Then the step should succeed
    And the expression should be true> YAML.load(@result[:response])['count'] > 0
    """

  # @author pruan@redhat.com
  # @case_id OCP-11405
  @admin
  @destructive
  Scenario: Use index names of project.project_name.project_uuid.xxx in Elasticsearch
    Given I create a project with non-leading digit name
    Given the master version >= "3.4"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And a pod becomes ready with labels:
      | component=es |
    # index takes over 10 minutes to come up initially
    And I wait up to 900 seconds for the steps to pass:
    """
    And I execute on the pod:
      | bash                                                                    |
      | -c                                                                      |
      | ls /elasticsearch/persistent/logging-es/data/logging-es/nodes/0/indices |
    And the output should contain:
      | project.<%= project.name %>.<%= project.uid %> |
    """

  # @author pruan@redhat.com
  # @case_id OCP-11266
  @admin
  @destructive
  Scenario: Use index names of project_name.project_uuid.xxx in Elasticsearch
    Given the master version < "3.4"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And a pod becomes ready with labels:
      | component=es |
    # index takes over 10 minutes to come up initially
    And I wait up to 900 seconds for the steps to pass:
    """
    And I execute on the pod:
      | bash                                                                    |
      | -c                                                                      |
      | ls /elasticsearch/persistent/logging-es/data/logging-es/nodes/0/indices |
    And the output should contain:
      | <%= project.name %>.<%= project.uid %> |
    """

  # @author qitang@redhat.com
  # @case_id OCP-19201
  @admin
  @destructive
  Scenario: Elasticsearch log files are on persistent volume
    Given the master version >= "3.9"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-19201/inventory |
    Given a pod becomes ready with labels:
      | component=es,logging-infra=elasticsearch,provider=openshift |
    And I execute on the pod:
      | ls | /elasticsearch/persistent/logging-es/logs |
    Then the step should succeed
    And the output should contain:
      | logging-es.log                        |
      | logging-es_deprecation.log            |
      | logging-es_index_indexing_slowlog.log |
      | logging-es_index_search_slowlog.log   |
    And the expression should be true> pod.volume_claims.first.name == 'logging-es-0'
