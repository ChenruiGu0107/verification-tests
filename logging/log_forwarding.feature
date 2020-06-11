@clusterlogging
Feature: log forwarding related tests

  # @author qitang@redhat.com
  @admin
  @destructive
  Scenario Outline: Forward logs to fluentd as unsecure
    Given the master version >= "4.3"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    And fluentd receiver is deployed as insecure in the "openshift-logging" project

    Given admin ensures "instance" log_forwarding is deleted from the "openshift-logging" project after scenario
    Given I obtain test data file "logging/logforwarding/fluentd/insecure/<status>/logforwarding.yaml"
    When I run the :create client command with:
      | f | logforwarding.yaml |
    Then the step should succeed
    Given I wait for the "instance" log_forwarding to appear
    Given I obtain test data file "logging/logforwarding/clusterlogging.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                      |
      | crd_yaml            | clusterlogging.yaml |
      | check_status        | false                                                                                     |
    Then the step should succeed
    Given I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And <%= daemon_set('fluentd').replica_counters[:desired] %> pods become ready with labels:
      | logging-infra=fluentd |

    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
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
    Examples:
      | status |
      | tp     | # @case_id OCP-25938
      | ga     | # @case_id OCP-29843

  # @author qitang@redhat.com
  @admin
  @destructive
  Scenario Outline: Forward logs to non-clusterlogging-managed elasticsearch as unsecure
    Given the master version >= "4.3"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given elasticsearch receiver is deployed as insecure
    Given admin ensures "instance" log_forwarding is deleted from the "openshift-logging" project after scenario
    Given I obtain test data file "logging/logforwarding/elasticsearch/insecure/<status>/logforwarding.yaml"
    When I run the :create client command with:
      | f | logforwarding.yaml |
    Then the step should succeed
    Given I wait for the "instance" log_forwarding to appear
    Given I obtain test data file "logging/logforwarding/clusterlogging.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                      |
      | crd_yaml            | clusterlogging.yaml |
      | check_status        | false                                                                                     |
    Then the step should succeed
    Given I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And <%= daemon_set('fluentd').replica_counters[:desired] %> pods become ready with labels:
      | logging-infra=fluentd |

    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    # check app logs
    When I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl | -s | -XGET | http://localhost:9200/*/_count?format=JSON | -H | Content-Type: application/json | -d | {"query": {"match": {"kubernetes.namespace_name": "<%= cb.proj.name %>"}}} |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:response])['count'] > 0

    # check journal logs
    When I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl | -s | -XGET | http://localhost:9200/*/_count?format=JSON | -H | Content-Type: application/json | -d | {"query": {"exists": {"field": "systemd"}}} |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:response])['count'] > 0

    # check logs in openshift* namespace
    When I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl | -s | -XGET | http://localhost:9200/*/_count?format=JSON | -H | Content-Type: application/json | -d | {"query": {"regexp": {"kubernetes.namespace_name": "openshift@"}}} |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:response])['count'] > 0

    # check audit logs
    When I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl | -s | -XGET | http://localhost:9200/*/_count?format=JSON | -H | Content-Type: application/json | -d | {"query": {"exists": {"field": "auditID"}}} |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:response])['count'] > 0
    """
    Examples:
      | status |
      | tp     | # @case_id OCP-26141
      | ga     | # @case_id OCP-29846

  # @author qitang@redhat.com
  @admin
  @destructive
  Scenario Outline: Forward logs to fluentd as secure
    Given the master version >= "4.3"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given fluentd receiver is deployed as secure in the "openshift-logging" project
    Given admin ensures "instance" log_forwarding is deleted from the "openshift-logging" project after scenario
    Given I obtain test data file "logging/logforwarding/fluentd/secure/<status>/logforwarding.yaml"
    When I run the :create client command with:
      | f | logforwarding.yaml |
    Then the step should succeed
    Given I wait for the "instance" log_forwarding to appear
    Given I obtain test data file "logging/logforwarding/clusterlogging.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                      |
      | crd_yaml            | clusterlogging.yaml |
      | check_status        | false                                                                                     |
    Then the step should succeed
    Given I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And <%= daemon_set('fluentd').replica_counters[:desired] %> pods become ready with labels:
      | logging-infra=fluentd |

    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
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
    Examples:
      | status |
      | tp     | # @case_id OCP-25939
      | ga     | # @case_id OCP-29844

  # @author qitang@redhat.com
  @admin
  @destructive
  Scenario Outline: Forward logs to non-clusterlogging-managed elasticsearch as secure
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
    Given I obtain test data file "logging/logforwarding/elasticsearch/secure/<status>/logforwarding.yaml"
    When I run the :create client command with:
      | f | logforwarding.yaml |
    Then the step should succeed
    Given I wait for the "instance" log_forwarding to appear
    Given I obtain test data file "logging/logforwarding/clusterlogging.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                      |
      | crd_yaml            | clusterlogging.yaml |
      | check_status        | false                                                                                     |
    Then the step should succeed
    Given I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And <%= daemon_set('fluentd').replica_counters[:desired] %> pods become ready with labels:
      | logging-infra=fluentd |

    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    # check app logs
    When I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl | -sk | -XGET | https://localhost:9200/*/_count?format=JSON | -H | Content-Type: application/json | -d | {"query": {"match": {"kubernetes.namespace_name": "<%= cb.proj.name %>"}}} |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:response])['count'] > 0

    # check journal logs
    When I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl | -sk | -XGET | https://localhost:9200/*/_count?format=JSON | -H | Content-Type: application/json | -d | {"query": {"exists": {"field": "systemd"}}} |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:response])['count'] > 0

    # check logs in openshift* namespace
    When I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl | -sk | -XGET | https://localhost:9200/*/_count?format=JSON | -H | Content-Type: application/json | -d | {"query": {"regexp": {"kubernetes.namespace_name": "openshift@"}}} |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:response])['count'] > 0

    # check audit logs
    When I execute on the "<%= cb.log_receiver.name %>" pod:
      | curl | -sk | -XGET | https://localhost:9200/*/_count?format=JSON | -H | Content-Type: application/json | -d | {"query": {"exists": {"field": "auditID"}}} |
    Then the step should succeed
    And the expression should be true> JSON.parse(@result[:response])['count'] > 0
    """
    Examples:
      | status |
      | tp     | # @case_id OCP-25990
      | ga     | # @case_id OCP-29845

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
    Given I obtain test data file "logging/logforwarding/forward_plugin/secure-forward-cm.yaml"
    Given I run the :create client command with:
      | f | secure-forward-cm.yaml |
    Then the step should succeed
    And I wait for the "secure-forward" config_map to appear

    Given I obtain test data file "logging/clusterlogging/example.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                |
      | crd_yaml            | example.yaml |
    Then the step should succeed

    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | */_count?pretty' -d '{"query": {"match": {"kubernetes.namespace_name": "<%= cb.proj.name %>"}}} |
      | op           | GET                                                                                             |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['count'] > 0
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | */_count?pretty'  -d '{"query": {"exists": {"field": "systemd"}}} |
      | op           | GET                                                               |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['count'] > 0
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | */_count?pretty'  -d '{"query": {"regexp": {"kubernetes.namespace_name": "openshift@"}}} |
      | op           | GET                                                                                      |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['count'] > 0
    """

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
    Given I obtain test data file "logging/logforwarding/rsyslog/insecure/<protocal>/syslog.conf"
    When I run the :create_configmap client command with:
      | name      | syslog                                                                                                        |
      | from_file | syslog.conf |
    Then the step should succeed
    And I wait for the "syslog" config_map to appear

    Given I obtain test data file "logging/clusterlogging/example.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                |
      | crd_yaml            | example.yaml |
    Then the step should succeed

    # create project to generate logs
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | */_count?pretty' -d '{"query": {"match": {"kubernetes.namespace_name": "<%= cb.proj.name %>"}}} |
      | op           | GET                                                                                             |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['count'] > 0
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | */_count?pretty'  -d '{"query": {"exists": {"field": "systemd"}}} |
      | op           | GET                                                               |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['count'] > 0
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | */_count?pretty'  -d '{"query": {"regexp": {"kubernetes.namespace_name": "openshift@"}}} |
      | op           | GET                                                                                      |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['count'] > 0
    """

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

  # @author qitang@redhat.com
  # @case_id OCP-29664
  @admin
  @destructive
  Scenario: Forward logs to mulitple external log aggregator
    Given I switch to the first user
    And I create a project with non-leading digit name
    And evaluation of `project` is stored in the :proj clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    Given fluentd receiver is deployed as secure in the "openshift-logging" project
    Given admin ensures "instance" log_forwarding is deleted from the "openshift-logging" project after scenario
    Given I obtain test data file "logging/logforwarding/multiple_receiver/logforwarding.yaml"
    When I run the :create client command with:
      | f | logforwarding.yaml |
    Then the step should succeed
    Given I wait for the "instance" log_forwarding to appear
    Given I obtain test data file "logging/logforwarding/clusterlogging_retentionpolicy.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                                      |
      | crd_yaml            | clusterlogging_retentionpolicy.yaml |
      | check_status        | true                                                                                                      |
    Then the step should succeed
    Given I wait for the "app" index to appear in the ES pod with labels "es-node-master=true"
    And I wait for the project "<%= cb.proj.name %>" logs to appear in the ES pod
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | infra*/_count?pretty  |
      | op           | GET                   |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['count'] = 0
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | audit*/_count?pretty  |
      | op           | GET                   |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['count'] = 0
    Given I wait up to 300 seconds for the steps to pass:
    """
    And I execute on the "<%= cb.log_receiver.name %>" pod:
      | ls | -l | /fluentd/log |
    Then the output should contain:
      | audit.log |
      | infra.log |
    And the output should not contain:
      | app.log |
    """
