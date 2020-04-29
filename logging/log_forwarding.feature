@clusterlogging
Feature: log forwarding related tests

  # @author qitang@redhat.com
  # @case_id OCP-25938
  @admin
  @destructive
  Scenario: Forward logs to fluentd as unsecure
    Given the master version >= "4.3"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    And fluentd receiver is deployed as insecure in the "openshift-logging" project

    Given admin ensures "instance" log_forwarding is deleted from the "openshift-logging" project after scenario
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/logforwarding/fluentd/insecure/logforwarding-insecure.yaml |
    Then the step should succeed
    Given I wait for the "instance" log_forwarding to appear
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                      |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/logforwarding/clusterlogging.yaml |
      | check_status        | false                                                                                     |
    Then the step should succeed
    Given I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And <%= daemon_set('fluentd').replica_counters[:desired] %> pods become ready with labels:
      | logging-infra=fluentd |

    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/loggen/container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    And I execute on the "<%= cb.log_receiver.name %>" pod:
      | ls | -l | /fluentd/log |
    Then the output should contain:
      | app.log   |
      | audit.log |
      | infra.log |
    """

  # @author qitang@redhat.com
  # @case_id OCP-26141
  @admin
  @destructive
  Scenario: Forward logs to non-clusterlogging-managed elasticsearch as unsecure
    Given the master version >= "4.3"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given elasticsearch receiver is deployed as insecure
    Given admin ensures "instance" log_forwarding is deleted from the "openshift-logging" project after scenario
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/logforwarding/elasticsearch/insecure/logforwarding-elasticsearch-insecure.yaml |
    Then the step should succeed
    Given I wait for the "instance" log_forwarding to appear
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                      |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/logforwarding/clusterlogging.yaml |
      | check_status        | false                                                                                     |
    Then the step should succeed
    Given I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And <%= daemon_set('fluentd').replica_counters[:desired] %> pods become ready with labels:
      | logging-infra=fluentd |
    
    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/loggen/container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl | -s | -XGET | http://localhost:9200/_cat/indices?format=JSON |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:response]).find {|e| e['index'].start_with? '.operations'}['docs.count'].to_i > 0
    And the expression should be true> JSON.parse(@result[:response]).find {|e| e['index'].start_with? '.audit'}['docs.count'].to_i > 0
    And the expression should be true> JSON.parse(@result[:response]).find {|e| e['index'].start_with? "project.#{cb.proj.name}"}['docs.count'].to_i > 0
    """

  # @author qitang@redhat.com
  # @case_id OCP-25939
  @admin
  @destructive
  Scenario: Forward logs to fluentd as secure
    Given the master version >= "4.3"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given fluentd receiver is deployed as secure in the "openshift-logging" project
    Given admin ensures "instance" log_forwarding is deleted from the "openshift-logging" project after scenario
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/logforwarding/fluentd/secure/logforwarding-secure.yaml |
    Then the step should succeed
    Given I wait for the "instance" log_forwarding to appear
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                      |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/logforwarding/clusterlogging.yaml |
      | check_status        | false                                                                                     |
    Then the step should succeed
    Given I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And <%= daemon_set('fluentd').replica_counters[:desired] %> pods become ready with labels:
      | logging-infra=fluentd |
    
    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/loggen/container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    And I execute on the "<%= cb.log_receiver.name %>" pod:
      | ls | -l | /fluentd/log |
    Then the output should contain:
      | app.log   |
      | audit.log |
      | infra.log |
    """

  # @author qitang@redhat.com
  # @case_id OCP-25990
  @admin
  @destructive
  Scenario: Forward logs to non-clusterlogging-managed elasticsearch as secure
    Given the master version >= "4.3"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given elasticsearch receiver is deployed as secure
    Given I wait up to 180 seconds for the steps to pass:
    """
    And I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl                                                                                                      |
      | -XPOST                                                                                                    |
      | -ks                                                                                                       |
      | https://localhost:9200/_xpack/security/user/fluentd                                                       |
      | -H                                                                                                        |
      | Content-Type: application/json                                                                            |
      | -d                                                                                                        |
      | {"password":"changeme","full_name":"Fluentd","email":"fluentd@clusterlogging.com","roles":["super_user"]} |
    Then the step should succeed
    And the output should contain:
      | "created":true |
    """

    Given admin ensures "instance" log_forwarding is deleted from the "openshift-logging" project after scenario
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/logforwarding/elasticsearch/secure/logforwarding-elasticsearch.yaml |
    Then the step should succeed
    Given I wait for the "instance" log_forwarding to appear
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                      |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/logforwarding/clusterlogging.yaml |
      | check_status        | false                                                                                     |
    Then the step should succeed
    Given I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And <%= daemon_set('fluentd').replica_counters[:desired] %> pods become ready with labels:
      | logging-infra=fluentd |

    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/loggen/container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    And I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl | -sk | -XGET | https://localhost:9200/_cat/indices?format=JSON |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:response]).find {|e| e['index'].start_with? '.operations'}['docs.count'].to_i > 0
    And the expression should be true> JSON.parse(@result[:response]).find {|e| e['index'].start_with? '.audit'}['docs.count'].to_i > 0
    And the expression should be true> JSON.parse(@result[:response]).find {|e| e['index'].start_with? "project.#{cb.proj.name}"}['docs.count'].to_i > 0
    """

  # @author qitang@redhat.com
  # @case_id OCP-26622
  @admin
  @destructive
  Scenario: Forward logs without enabling logforwarding.
    Given the master version >= "4.3"
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project

    Given fluentd receiver is deployed as secure in the "openshift-logging" project

    Given admin ensures "secure-forward" config_map is deleted from the "openshift-logging" project after scenario
    Given admin ensures "secure-forward" secret is deleted from the "openshift-logging" project after scenario
    Given I run the :create_secret client command with:
      | name         | secure-forward           |
      | secret_type  | generic                  |
      | from_file    | ca-bundle.crt=ca.crt     |
    Then the step should succeed
    Given I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/logforwarding/forward_plugin/secure-forward-cm.yaml |
    Then the step should succeed
    And I wait for the "secure-forward" config_map to appear

    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/example.yaml |
    Then the step should succeed

    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/loggen/container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait for the "project.<%= cb.proj.name %>.<%= cb.proj.uid %>" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['docs.count'] > "0"
    Given I wait for the ".operation" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['docs.count'] > "0"

    Given I wait up to 300 seconds for the steps to pass:
    """
    And I execute on the "<%= cb.log_receiver.name %>" pod:
      | ls | -l | /fluentd/log |
    Then the output should contain:
      | app.log   |
      | infra.log |
    """

  # @author qitang@redhat.com
  @admin
  @destructive
  Scenario Outline: Forward logs to syslog - LEGACY_SECUREFORWARD
    Given the master version >= "4.3"
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project

    Given rsyslog receiver is deployed as insecure in the "openshift-logging" project

    #Given I obtain test data file "logging/logforwarding/rsyslog/insecure/<protocal>/syslog.conf"
    Given admin ensures "syslog" config_map is deleted from the "openshift-logging" project after scenario
    When I run the :create_configmap client command with:
      | name      | syslog                                                                                                        |
      | from_file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/logforwarding/rsyslog/insecure/<protocal>/syslog.conf |
    Then the step should succeed
    And I wait for the "syslog" config_map to appear

    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/example.yaml |
    Then the step should succeed

    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/loggen/container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait for the "project.<%= cb.proj.name %>.<%= cb.proj.uid %>" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['docs.count'] > "0"
    Given I wait for the ".operation" index to appear in the ES pod with labels "es-node-master=true"
    Then the expression should be true> cb.index_data['docs.count'] > "0"

    Given I wait up to 300 seconds for the steps to pass:
    """
    And I execute on the "<%= cb.log_receiver.name %>" pod:
      | ls | -l | /var/log/custom |
    Then the output should contain:
      | app-container.log   |
      | infra-container.log |
      | infra.log           |
    """

    Examples:
      | protocal |
      | tcp      | # @case_id OCP-28541
      | udp      | # @case_id OCP-27757
