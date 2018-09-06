Feature: fluentd related tests
  # @author pruan@redhat.com
  # @case_id OCP-12868
  @admin
  @destructive
  Scenario: Check Fluentd should write times/timestamps in UTC when logdriver=journald
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project clipboard
    # need to add app so it will generate some data which will trigger the project index be pushed up to the es pod
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    Then the step should succeed
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12868/inventory |
    When I wait for the ".operation" index to appear in the ES pod with labels "component=es"
    Then I perform the HTTP request on the ES pod:
      | relative_url | <%= cb.index_data['index'] %>/_search?pretty&size=5 |
      | op           | GET                                                 |
    And evaluation of `Time.parse(@result.dig(:parsed, 'hits', 'hits')[0].dig('_source','@timestamp'))` is stored in the :query_result clipboard
    Then the expression should be true> cb.query_result.inspect.end_with? "0000" or cb.query_result.inspect.end_with? "UTC"
    # query the user project
    When I wait for the "project.<%= cb.org_project %>" index to appear in the ES pod
    Then I perform the HTTP request on the ES pod:
      | relative_url | <%= cb.index_data['index'] %>/_search?pretty&size=5 |
      | op           | GET                                                 |
    And evaluation of `Time.parse(@result.dig(:parsed, 'hits', 'hits')[0].dig('_source','@timestamp'))` is stored in the :query_result clipboard
    Then the expression should be true> cb.query_result.inspect.end_with? "0000" or cb.query_result.inspect.end_with? "UTC"

  # @author pruan@redhat.com
  # @case_id OCP-17424
  @admin
  @destructive
  Scenario: fluentd ops feature checking
    Given the master version >= "3.6"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17424/inventory |
    # check fluentd pod
    Given a pod becomes ready with labels:
      | component=fluentd |
    And I execute on the "<%= pod.name %>" pod:
      | env |
    Then the step should succeed
    And the output should contain "OPS_HOST=logging-es-ops"
    And I execute on the "<%= pod.name %>" pod:
      | ls | /etc/fluent/configs.d/filter-post-z-retag-two.conf |
    Then the step should succeed
    And the output should contain "/etc/fluent/configs.d/filter-post-z-retag-two.conf"
    And I get the ".operation" logging index information from a pod with labels "component=es-ops"
    Then the expression should be true> cb.index_data and cb.index_data.count > 0

  # @author pruan@redhat.com
  # @case_id OCP-10523
  @admin
  @destructive
  Scenario: Logging fluentD daemon set should set quota for the pods
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    Given a pod becomes ready with labels:
      | component=fluentd,logging-infra=fluentd |
    And evaluation of `pod.container(user: user, name: 'fluentd-elasticsearch').spec.memory_limit` is stored in the :fluentd_pod_mem_limit clipboard
    And evaluation of `daemon_set('logging-fluentd').container_spec(user: user, name: 'fluentd-elasticsearch').memory_limit` is stored in the :fluentd_container_mem_limit clipboard
    Then the expression should be true> cb.fluentd_container_mem_limit[1] == cb.fluentd_pod_mem_limit[1]

  # @author pruan@redhat.com
  # @case_id OCP-11847
  @admin
  @destructive
  Scenario: Check for packages inside fluentd pod to support journald log driver
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And a pod becomes ready with labels:
      |  component=fluentd |
    And I execute on the pod:
      | bash                                 |
      | -c                                   |
      | rpm -qa \| grep -e journal -e fluent |
    And the output should contain:
      | rubygem-systemd-journal                  |
      | rubygem-fluent-plugin-systemd            |
      | rubygem-fluent-plugin-rewrite-tag-filter |

  # @author pruan@redhat.com
  # @case_id OCP-10995
  @admin
  @destructive
  Scenario: Check fluentd changes for common data model and index naming
    Given I create a project with non-leading digit name
    And evaluation of `project` is stored in the :org_project clipboard
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    And logging service is installed in the system
    When I wait 900 seconds for the "project.<%= cb.org_project.name %>" index to appear in the ES pod with labels "component=es"
    And the expression should be true> cb.proj_index_regex = /project.#{cb.org_project.name}.#{cb.org_project.uid}.(\d{4}).(\d{2}).(\d{2})/
    And the expression should be true> cb.op_index_regex = /.operations.(\d{4}).(\d{2}).(\d{2})/
    Given I log the message> <%= cb.index_data['index'] %>
    And the expression should be true> cb.proj_index_regex.match(cb.index_data['index'])
    And I wait for the ".operations" index to appear in the ES pod
    Given I log the message> <%= cb.index_data['index'] %>
    And the expression should be true> cb.op_index_regex.match(cb.index_data['index'])

  # @author pruan@redhat.com
  # @case_id OCP-17248
  @admin
  @destructive
  Scenario: Invalid value for FILE_BUFFER_LIMIT
    Given the master version >= "3.4"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17248/inventory |
      | negative_test | true                                                                                                   |
    Given a pod is present with labels:
      | component=fluentd,logging-infra=fluentd |
    When I run the :logs client command with:
      | resource_name    | pods/<%= pod.name %>|
    Then the output should contain:
      | Invalid file buffer limit  |
      | Failed to convert to bytes |

  # @author pruan@redhat.com
  # @case_id OCP-17243
  @admin
  @destructive
  Scenario: FILE_BUFFER_LIMIT is less than BUFFER_SIZE_LIMIT
    Given the master version >= "3.8"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17243/inventory |
      | negative_test | true                                                                                                   |
    And I use the "<%= cb.target_proj %>" project
    Given a pod is present with labels:
      | component=fluentd,logging-infra=fluentd |
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %> |
    Then the output should contain:
      | ERROR:                                     |
      | TOTAL_BUFFER_SIZE_LIMIT                    |
      | is too small compared to BUFFER_SIZE_LIMIT |
    Given a pod is present with labels:
      | component=mux,deploymentconfig=logging-mux,logging-infra=mux,provider=openshift |
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %> |
    Then the output should contain:
      | ERROR:                                     |
      | TOTAL_BUFFER_SIZE_LIMIT                    |
      | is too small compared to BUFFER_SIZE_LIMIT |

  # @author pruan@redhat.com
  # @case_id OCP-17235
  @admin
  @destructive
  Scenario: FILE_BUFFER_LIMIT, BUFFER_SIZE_LIMIT and BUFFER_QUEUE_LIMIT use the default value
    Given the master version >= "3.8"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17235/inventory |
    Given a pod becomes ready with labels:
      | component=fluentd,logging-infra=fluentd |
    Then the expression should be true> pod.env_var('BUFFER_QUEUE_LIMIT') == "32"
    Then the expression should be true> pod.env_var('BUFFER_SIZE_LIMIT') == "8m"
    Then the expression should be true> pod.env_var('FILE_BUFFER_LIMIT') == "256Mi"
    Given a pod becomes ready with labels:
      | component=mux,deploymentconfig=logging-mux,logging-infra=mux,provider=openshift |
    Then the expression should be true> pod.env_var('BUFFER_QUEUE_LIMIT') == "32"
    Then the expression should be true> pod.env_var('BUFFER_SIZE_LIMIT') == "8m"
    Then the expression should be true> pod.env_var('FILE_BUFFER_LIMIT') == "2Gi"

  # @author pruan@redhat.com
  # @case_id OCP-17238
  @admin
  @destructive
  Scenario: FILE_BUFFER_LIMIT, BUFFER_QUEUE_LIMIT and  BUFFER_SIZE_LIMIT use customed value
    Given the master version >= "3.8"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17238/inventory |
    Given a pod becomes ready with labels:
      | component=fluentd,logging-infra=fluentd |
    Then the expression should be true> pod.env_var('BUFFER_QUEUE_LIMIT') == "64"
    Then the expression should be true> pod.env_var('BUFFER_SIZE_LIMIT') == "4m"
    Then the expression should be true> pod.env_var('FILE_BUFFER_LIMIT') == "1Gi"
    Given a pod becomes ready with labels:
      | component=mux,deploymentconfig=logging-mux,logging-infra=mux,provider=openshift |
    Then the expression should be true> pod.env_var('BUFFER_QUEUE_LIMIT') == "32"
    Then the expression should be true> pod.env_var('BUFFER_SIZE_LIMIT') == "8m"
    Then the expression should be true> pod.env_var('FILE_BUFFER_LIMIT') == "512Mi"

  # @author pruan@redhat.com
  # @case_id OCP-10104
  @admin
  @destructive
  Scenario: deploy logging with dynamic volume
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-10104/inventory |
    And I run the :volume client command with:
      | resource | dc                    |
      | selector | component=es          |
      | n        | <%= cb.target_proj %> |
    Then the output should contain:
      | pvc/logging-es-0         |
      | as elasticsearch-storage |

  # @author pruan@redhat.com
  # @case_id OCP-18504
  @admin
  @destructive
  Scenario: Check the default image prefix and version - logging
    Given the master version >= "3.4"
    Given I create a project with non-leading digit name
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-18504/inventory |
    And evaluation of `"registry.access.redhat.com/openshift3/"` is stored in the :expected_prefix clipboard
    And evaluation of `{"curator"=>"curator", "curator-ops"=>"curator", "es"=>"elasticsearch", "es"=>"elasticsearch", "kibana"=>"kibana", "kibana-ops"=>"kibana", "mux"=>"mux"}` is stored in the :rc_labels clipboard
    Given I repeat the following steps for each :label_hash in cb.rc_labels:
    """
    And a replicationController becomes ready with labels:
      | component=#{cb.label_hash.first} |
    And the expression should be true> rc.container_spec(name: cb.label_hash.last).image.start_with? cb.expected_prefix
    And the expression should be true> rc.container_spec(name: cb.label_hash.last).image.end_with? cb.master_version
    """
    # check fluentd's ds instead of pod
    And the expression should be true> daemon_set('logging-fluentd').container_spec(name: 'fluentd-elasticsearch').image.start_with? cb.expected_prefix
    And the expression should be true> daemon_set('logging-fluentd').container_spec(name: 'fluentd-elasticsearch').image.end_with? cb.master_version

  # @author pruan@redhat.com
  # @case_id OCP-16176
  @admin
  @destructive
  Scenario: Enable/disable docker event collection by playbook
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-16176/inventory |
    And the expression should be true> daemon_set('logging-fluentd').container_spec(name: 'fluentd-elasticsearch').env_var('AUDIT_CONTAINER_ENGINE') == 'true'
    And a pod becomes ready with labels:
      | component=fluentd |
    And the expression should be true> pod.env_var('AUDIT_CONTAINER_ENGINE') == 'true'

    # reinstall logging with docker event collection disabled
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-16176/inventory_disable_dockerevent |
    # need to refresh the cached data
    And the expression should be true> daemon_set.pods
    And the expression should be true> daemon_set('logging-fluentd').container_spec(name: 'fluentd-elasticsearch').env_var('AUDIT_CONTAINER_ENGINE').nil?
    And a pod becomes ready with labels:
      | component=fluentd |
    And the expression should be true> pod.env_var('AUDIT_CONTAINER_ENGINE').nil?

  # @author pruan@redhat.com
  # @case_id OCP-19207
  @admin
  @destructive
  Scenario: Turn off JSON payload by default
    Given the master version >= "3.9"
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project clipboard
    And cluster role "cluster-admin" is added to the "first" user
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-19207/inventory |
    When I run the :set_env client command with:
      | resource | ds/logging-fluentd   |
      | e        | MERGE_JSON_LOG=false |
    Then the step should succeed

    And I switch to the first user
    And I use the "<%= cb.org_project %>" project
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    And a pod becomes ready with labels:
      | name=hello-openshift |
    When I run the :debug client command with:
      | resource         | pod/<%= pod.name %>                                |
      | oc_opts_end      |                                                    |
      | exec_command     | echo                                               |
      | exec_command_arg | '{ "message": "OCP-19207", "level": "OCP-19207" }' |
    Then the step should succeed
    And I switch to cluster admin pseudo user
    And I use the "<%= cb.target_proj %>" project
    When I wait 900 seconds for the "project.<%= cb.org_project %>" index to appear in the ES pod with labels "component=es"
    And a pod becomes ready with labels:
      | component=fluentd |
    And I switch to the first user
    And I perform the HTTP request:
    """
      :url: https://es.<%= cb.subdomain %>/_search?output=JSON
      :method: post
      :payload: '{"query": { "match": {"message" : "OCP-19207" }}}'
      :headers:
        :Authorization: Bearer <%= user.cached_tokens.first %>
    """
    And the step should succeed
    And the expression should be true> @result[:parsed].dig('hits', 'total') > 0
    And the expression should be true> @result[:parsed]['hits']['hits'].first['_source']['level'] == 'info'
    And I perform the HTTP request:
    """
      :url: https://es.<%= cb.subdomain %>/_search?output=JSON
      :method: post
      :payload: '{"query": { "match": {"level" : "OCP-19207" }}}'
      :headers:
        :Authorization: Bearer <%= user.cached_tokens.first %>
    """
    And the step should succeed
    And the expression should be true> @result[:parsed].dig('hits', 'total') == 0

  # @author pruan@redhat.com
  # @case_id OCP-19431
  @admin
  @destructive
  Scenario: the string event are sent to ES
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-19431/inventory |
    # register the message
    And the first user is cluster-admin
    And I switch to the first user
    And I use the "default" project
    And a pod becomes ready with labels:
      | component=eventrouter |
    When I run the :debug client command with:
      | resource         | pod/<%= pod.name %>                              |
      | oc_opts_end      |                                                  |
      | exec_command     | echo                                             |
      | exec_command_arg | '{ "event": "anlieventevent", "verb": "ADDED" }' |
    Then the step should succeed
    And I wait up to 900 seconds for the steps to pass:
    """
    And I perform the HTTP request:
    <%= '"""' %>
      :url: https://es.<%= cb.subdomain %>/_search?output=JSON
      :method: post
      :payload: '{"query": { "match": {"event" : "anlieventevent" }}}'
      :headers:
        :Authorization: Bearer <%= user.cached_tokens.first %>
    <%= '"""' %>
    Then the expression should be true> @result[:parsed]['hits']['hits'].last["_source"]["event"].include? "anlieventevent"
    """
