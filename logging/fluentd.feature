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
      | app_repo | httpd-example |
    Then the step should succeed
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
      | file | <file> |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    Then I wait 600 seconds for the "project.<%= cb.org_project %>" index to appear in the ES pod with labels "es-node-master=true"
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.org_project %>*/_search?pretty |
      | op           | GET                                           |
    Then the expression should be true> @result[:parsed]['hits']['hits'].last["_source"]["message"].include? <message>
    Examples:
      | file                                                                                                                       | message                                                 |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/loggen/container_json_event_log_template.json   | "anlieventevent"                                        | # @case_id OCP-19431
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/loggen/container_json_unicode_log_template.json | "ㄅㄉˇˋㄓˊ˙ㄚㄞㄢㄦㄆ 中国 883.317µs ā á ǎ à ō ó ▅ ▆ ▇ █ 々" | # @case_id OCP-24563

  # @author qitang@redhat.com
  # @case_id OCP-21083
  @admin
  @destructive
  Scenario: the priority class are added in Logging collector
    Given the expression should be true> daemon_set('fluentd').template['spec']['priorityClassName'] == "cluster-logging"

