@clusterlogging
Feature: cluster-logging-operator related cases

  # @author qitang@redhat.com
  # @case_id OCP-21079
  @admin
  @destructive
  Scenario: The logging cluster operator shoud recreate the damonset
    Given I obtain test data file "logging/clusterlogging/example.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true         |
      | crd_yaml            | example.yaml |
    Then the step should succeed
    And the expression should be true> cluster_logging('instance').management_state == "Managed"
    Given evaluation of `daemon_set('fluentd').creation_time_stamp` is stored in the :timestamp_1 clipboard
    When I run the :delete client command with:
      | object_type       | daemonset |
      | object_name_or_id | fluentd   |
    Then the step should succeed
    And I wait for the "fluentd" daemonset to appear
    #Given evaluation of `daemon_set('fluentd').raw_resource['metadata']['creationTimestamp']` is stored in the :timestamp_2 clipboard
    Given evaluation of `daemon_set('fluentd').creation_time_stamp` is stored in the :timestamp_2 clipboard
    Then the expression should be true> cb.timestamp_1 != cb.timestamp_2

  # @author qitang@redhat.com
  # @case_id OCP-21767
  @admin
  @destructive
  Scenario: Deploy logging via customized pod resource in clusterlogging
    Given I obtain test data file "logging/clusterlogging/customresource-fluentd.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                        |
      | crd_yaml            | customresource-fluentd.yaml |
      | check_status        | false                       |
    Then the step should succeed
    And I wait for the "elasticsearch" elasticsearch to appear up to 300 seconds
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid %>-1" deployment to appear
    And I wait for the "kibana" deployment to appear up to 300 seconds
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    Then the expression should be true> deployment('kibana').container_spec(name: 'kibana').memory_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana').cpu_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana').memory_request_raw == "1Gi"
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana').cpu_request_raw == "100m"
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana-proxy').cpu_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana-proxy').memory_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana-proxy').memory_request_raw == "100Mi"
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana-proxy').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(name: 'fluentd').cpu_limit_raw == nil
    And the expression should be true> daemon_set('fluentd').container_spec(name: 'fluentd').memory_limit_raw == nil
    And the expression should be true> daemon_set('fluentd').container_spec(name: 'fluentd').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(name: 'fluentd').memory_request_raw == "1Gi"
    And the expression should be true> cron_job('curator').container_spec(name: 'curator').cpu_limit_raw == nil
    And the expression should be true> cron_job('curator').container_spec(name: 'curator').memory_limit_raw == nil
    And the expression should be true> cron_job('curator').container_spec(name: 'curator').cpu_request_raw == "100m"
    And the expression should be true> cron_job('curator').container_spec(name: 'curator').memory_request_raw == "100Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'elasticsearch').memory_limit_raw == "1Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'elasticsearch').cpu_limit_raw == nil
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'elasticsearch').memory_request_raw == "1Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'elasticsearch').cpu_request_raw == "100m"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'proxy').memory_limit_raw == "64Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'proxy').cpu_limit_raw == nil
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'proxy').memory_request_raw == "64Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'proxy').cpu_request_raw == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_limit_cpu == nil
    And the expression should be true> elasticsearch('elasticsearch').resource_limit_memory == nil
    And the expression should be true> elasticsearch('elasticsearch').resource_request_cpu == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_request_memory == "1Gi"

  # @author qitang@redhat.com
  # @case_id OCP-22992
  @admin
  @destructive
  Scenario: The clusterlogging handle the nodeSelector
    Given I obtain test data file "logging/clusterlogging/nodeSelector.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true              |
      | crd_yaml            | nodeSelector.yaml |
      | check_status        | false             |
    Then the step should succeed
    And I wait for the "elasticsearch" elasticsearch to appear up to 300 seconds
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid %>-1" deployment to appear
    And I wait for the "kibana" deployment to appear up to 300 seconds
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    Then the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").node_selector['es'] == 'deploy'
    And the expression should be true> daemon_set('fluentd').node_selector['fluentd'] == 'deploy'
    And the expression should be true> deployment('kibana').node_selector['kibana'] == 'deploy'
    And the expression should be true> cron_job('curator').node_selector['curator'] == 'deploy'
    Given I wait up to 600 seconds for the steps to pass:
    """
    And the expression should be true> cluster_logging('instance').es_node_conditions.to_s.match? (/0\/\d+ nodes are available/)
    And the expression should be true> cluster_logging('instance').kibana_cluster_condition.to_s.match? (/0\/\d+ nodes are available/)
    And the expression should be true> elasticsearch('elasticsearch').nodes_conditions.to_s.match? (/0\/\d+ nodes are available/)
    """
    Given I obtain test data file "logging/clusterlogging/nodeSelector_change.yaml"
    When I run the :apply client command with:
      | f | nodeSelector_change.yaml |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
      """
      #And the expression should be true> elasticsearch('elasticsearch').node_selector['es'] == 'deploy1'
      And the expression should be true> daemon_set('fluentd').node_selector(cached: false, quiet: true)['fluentd'] == 'deploy1'
      And the expression should be true> deployment('kibana').node_selector(cached: false, quiet: true)['kibana'] == 'deploy1'
      And the expression should be true> cron_job('curator').node_selector(cached: false, quiet: true)['curator'] == 'deploy1'
      """
    Given I wait up to 600 seconds for the steps to pass:
      """
      And the expression should be true> deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').node_selector(cached: false, quiet: true)['es'] == 'deploy1'
      """

  # @author qitang@redhat.com
  # @case_id OCP-24209
  @admin
  @destructive
  Scenario: The operator append kubernetes.io/os: linux
    Given the master version >= "4.2"
    Given I obtain test data file "logging/clusterlogging/example.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true         |
      | crd_yaml            | example.yaml |
      | check_status        | false        |
    Then the step should succeed
    And I wait for the "elasticsearch" elasticsearch to appear up to 300 seconds
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid %>-1" deployment to appear
    And I wait for the "kibana" deployment to appear up to 300 seconds
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").node_selector['kubernetes.io/os'] == 'linux'
    And the expression should be true> daemon_set('fluentd').node_selector['kubernetes.io/os'] == 'linux'
    And the expression should be true> deployment('kibana').node_selector['kubernetes.io/os'] == 'linux'
    Given I obtain test data file "logging/clusterlogging/nodeSelector.yaml"
    When I run the :apply client command with:
      | f | nodeSelector.yaml |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
      """
      #And the expression should be true> elasticsearch('elasticsearch').node_selector['es'] == 'deploy'
      And the expression should be true> daemon_set('fluentd').node_selector(cached: false, quiet: true)['fluentd'] == 'deploy'
      And the expression should be true> deployment('kibana').node_selector(cached: false, quiet: true)['kibana'] == 'deploy'
      And the expression should be true> daemon_set('fluentd').node_selector(cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      And the expression should be true> deployment('kibana').node_selector(cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      """
    Given I wait up to 300 seconds for the steps to pass:
      """
      And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").node_selector(cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      And the expression should be true> deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').node_selector(cached: false, quiet: true)['es'] == 'deploy'
      """
    Given I obtain test data file "logging/clusterlogging/nodeSelector_override.yaml"
    When I run the :apply client command with:
      | f | nodeSelector_override.yaml |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
      """
      #And the expression should be true> elasticsearch('elasticsearch').node_selector['es'] == nil
      And the expression should be true> daemon_set('fluentd').node_selector(cached: false, quiet: true)['fluentd'] == nil
      And the expression should be true> deployment('kibana').node_selector(cached: false, quiet: true)['kibana'] == nil
      And the expression should be true> daemon_set('fluentd').node_selector(cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      And the expression should be true> deployment('kibana').node_selector(cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      #And the expression should be true> elasticsearch('elasticsearch').node_selector['kubernetes.io/os'] == 'foo'
      """
    Given I wait up to 300 seconds for the steps to pass:
      """
      And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").node_selector(cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      And the expression should be true> deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').node_selector(cached: false, quiet: false)['es'] == nil
      """
    And I wait until ES cluster is ready

  # @author qitang@redhat.com
  # @case_id OCP-21831
  @admin
  @destructive
  Scenario: Add Management Spec field to CRs.
    Given I obtain test data file "logging/clusterlogging/example.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true         |
      | crd_yaml            | example.yaml |
    Then the step should succeed
    And the expression should be true> cluster_logging('instance').management_state == "Managed"
    And the expression should be true> elasticsearch('elasticsearch').management_state == "Managed"
    Given evaluation of `cron_job('curator').schedule` is stored in the :curator_schedule_1 clipboard
    Then the expression should be true> cb.curator_schedule_1 == cluster_logging('instance').curation_schedule
    When I run the :patch client command with:
      | resource      | clusterlogging                                                    |
      | resource_name | instance                                                          |
      | p             | {"spec": {"curation": {"curator": {"schedule": "*/15 * * * *"}}}} |
      | type          | merge                                                             |
    Then the step should succeed
    And the expression should be true> cluster_logging('instance').curation_schedule == "*/15 * * * *"
    And I wait up to 180 seconds for the steps to pass:
    """
    Given the expression should be true> cron_job('curator').schedule(cached: false, quiet: true) == "*/15 * * * *"
    """
    When I run the :patch client command with:
      | resource      | cronjob                                 |
      | resource_name | curator                                 |
      | p             | {"spec": {"schedule": "*/20 * * * *" }} |
    Then the step should succeed
    Given 60 seconds have passed
    And the expression should be true> cron_job('curator').schedule(cached: false, quiet: true) == "*/15 * * * *"

    When I run the :patch client command with:
      | resource      | clusterlogging                             |
      | resource_name | instance                                   |
      | p             | {"spec": {"managementState": "Unmanaged"}} |
      | type          | merge                                      |
    Then the step should succeed
    And the expression should be true> cluster_logging('instance').management_state == "Unmanaged"
    When I run the :patch client command with:
      | resource      | clusterlogging                                                    |
      | resource_name | instance                                                          |
      | p             | {"spec": {"curation": {"curator": {"schedule": "*/25 * * * *"}}}} |
      | type          | merge                                                             |
    Then the step should succeed
    And the expression should be true> cluster_logging('instance').curation_schedule == "*/25 * * * *"
    Given 60 seconds have passed
    And the expression should be true> cron_job('curator').schedule(cached: false, quiet: true) == "*/15 * * * *"

    When I run the :patch client command with:
      | resource      | cronjob                                 |
      | resource_name | curator                                 |
      | p             | {"spec": {"schedule": "*/30 * * * *" }} |
    Then the step should succeed
    And the expression should be true> cron_job('curator').schedule(cached: false, quiet: true) == "*/30 * * * *"
    Given 60 seconds have passed
    And the expression should be true> cron_job('curator').schedule(cached: false, quiet: true) == "*/30 * * * *"

  # @author qitang@redhat.com
  # @case_id OCP-21736
  @admin
  @destructive
  @commonlogging
  Scenario: [BZ 1564944]The pod podAntiAffinity
    Given a pod becomes ready with labels:
      | cluster-name=elasticsearch,component=elasticsearch |
    And evaluation of `pod` is stored in the :es_pod clipboard
    Given a pod becomes ready with labels:
      | component=kibana,logging-infra=kibana |
    And evaluation of `pod` is stored in the :kibana_pod clipboard
    Given a pod becomes ready with labels:
      | logging-infra=fluentd |
    And evaluation of `pod` is stored in the :fluentd_pod clipboard
    Then the expression should be true> cb.es_pod.raw_resource['spec']['affinity']
    And the expression should be true> cb.kibana_pod.raw_resource['spec']['affinity']
    And the expression should be true> cb.fluentd_pod.raw_resource['spec']['affinity']

  # @author qitang@redhat.com
  # @case_id OCP-23742
  @admin
  @destructive
  Scenario: Fluentd alert rules check.
    Given the master version >= "4.2"
    Given I obtain test data file "logging/clusterlogging/example.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true         |
      | crd_yaml            | example.yaml |
    Then the step should succeed
    Given I wait for the "fluentd" prometheus_rule to appear up to 300 seconds

    Then the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: 'FluentdNodeDown').severity == "critical"
    And the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: 'FluentdQueueLengthBurst').severity == "warning"
    And the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: 'FluentdQueueLengthIncreasing').severity == "critical"
    And the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: 'FluentdErrorsHigh').severity == "critical"

    Given I wait up to 300 seconds for the steps to pass:
    """
    Given I check the "fluentd" prometheus rule in the "openshift-logging" project on the prometheus server
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['name'] == "logging_fluentd.alerts"
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'FluentdNodeDown'}['labels']['severity'] == "critical"
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'FluentdQueueLengthBurst'}['labels']['severity'] == "warning"
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'FluentdQueueLengthIncreasing'}['labels']['severity'] == "critical"
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'FluentdErrorsHigh'}['labels']['severity'] == "critical"
    """

    Given I run the :patch client command with:
      | resource      | prometheusrule |
      | resource_name | fluentd |
      | p             | {"spec": {"groups": [{"name": "logging_fluentd.alerts", "rules": [{"alert": "FluentdNodeDown","expr": "absent(up{job='fluentd'} == 1)", "labels": {"severity": "warning"}}]}]}} |
      | type          | merge |
    Then the step should succeed
    And the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: 'FluentdNodeDown').severity == "warning"
    And the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rules.count == 1

    Given I wait up to 300 seconds for the steps to pass:
    """
    Given I check the "fluentd" prometheus rule in the "openshift-logging" project on the prometheus server
    And the output should not contain:
      | FluentdQueueLengthBurst      |
      | FluentdQueueLengthIncreasing |
      | FluentdErrorsHigh            |
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'FluentdNodeDown'}['labels']['severity'] == "warning"
    """

  # @author qitang@redhat.com
  # @case_id OCP-24427
  @admin
  @destructive
  Scenario: The tolerations for cluster logging
    Given the master version >= "4.2"
    Given I obtain test data file "logging/clusterlogging/example.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true         |
      | crd_yaml            | example.yaml |
    Then the step should succeed
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    And the expression should be true> deployment('kibana').tolerations == nil
    And the expression should be true> (deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').tolerations - [{"effect"=>"NoSchedule", "key"=>"node.kubernetes.io/disk-pressure", "operator"=>"Exists"}]).empty?
    And the expression should be true> cron_job('curator').tolerations == nil
    And the expression should be true> (daemon_set('fluentd').tolerations - [{"effect"=>"NoSchedule", "key"=>"node-role.kubernetes.io/master", "operator"=>"Exists"}, {"effect"=>"NoSchedule", "key"=>"node.kubernetes.io/disk-pressure", "operator"=>"Exists"}]).empty?
    Given I obtain test data file "logging/clusterlogging/example_tolerations.yaml"
    When I run the :apply client command with:
      | f | example_tolerations.yaml |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    And the expression should be true> (deployment('kibana').tolerations(cached: false) - [{"effect"=>"NoExecute", "key"=>"logging", "operator"=>"Exists", "tolerationSeconds"=>6000}]).empty?
    And the expression should be true> (deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').tolerations(cached: false) - [{"effect"=>"NoSchedule", "key"=>"node.kubernetes.io/disk-pressure", "operator"=>"Exists"}, {"effect"=>"NoExecute", "key"=>"logging", "operator"=>"Exists", "tolerationSeconds"=>6000}]).empty?
    And the expression should be true> (cron_job('curator').tolerations(cached: false) - [{"effect"=>"NoExecute", "key"=>"logging", "operator"=>"Exists", "tolerationSeconds"=>6000}]).empty?
    And the expression should be true> (daemon_set('fluentd').tolerations(cached: false) - [{"effect"=>"NoExecute", "key"=>"logging", "operator"=>"Exists", "tolerationSeconds"=>6000}, {"effect"=>"NoSchedule", "key"=>"node-role.kubernetes.io/master", "operator"=>"Exists"}, {"effect"=>"NoSchedule", "key"=>"node.kubernetes.io/disk-pressure", "operator"=>"Exists"}]).empty?
    """

  # @author qitang@redhat.com
  # @case_id OCP-22993
  @admin
  @destructive
  Scenario: The logging are redeployed when resource changed
    Given I obtain test data file "logging/clusterlogging/customresource-fluentd.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                        |
      | crd_yaml            | customresource-fluentd.yaml |
      | check_status        | false                       |
    Then the step should succeed
    And I wait for the "elasticsearch" elasticsearch to appear up to 300 seconds
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid %>-1" deployment to appear
    And I wait for the "kibana" deployment to appear up to 300 seconds
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana').memory_request_raw == "1Gi"
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana').cpu_request_raw == "100m"
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana-proxy').memory_request_raw == "100Mi"
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana-proxy').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(name: 'fluentd').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(name: 'fluentd').memory_request_raw == "1Gi"
    And the expression should be true> cron_job('curator').container_spec(name: 'curator').cpu_request_raw == "100m"
    And the expression should be true> cron_job('curator').container_spec(name: 'curator').memory_request_raw == "100Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'elasticsearch').memory_request_raw == "1Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'elasticsearch').cpu_request_raw == "100m"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'proxy').memory_request_raw == "64Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'proxy').cpu_request_raw == "100m"
    Given I obtain test data file "logging/clusterlogging/customresource-fluentd_change.yaml"
    When I run the :apply client command with:
      | f | customresource-fluentd_change.yaml |
    Then the step should succeed

    Given I wait up to 600 seconds for the steps to pass:
    """
    And the expression should be true> deployment('kibana').container_spec(cached: false, name: 'kibana').memory_request_raw == "16Gi"
    And the expression should be true> deployment('kibana').container_spec(cached: false, name: 'kibana').cpu_request_raw == "100m"
    And the expression should be true> deployment('kibana').container_spec(cached: false, name: 'kibana-proxy').memory_request_raw == "200Mi"
    And the expression should be true> deployment('kibana').container_spec(cached: false, name: 'kibana-proxy').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(cached: false, name: 'fluentd').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(cached: false, name: 'fluentd').memory_request_raw == "16Gi"
    And the expression should be true> cron_job('curator').container_spec(cached: false, name: 'curator').cpu_request_raw == "100m"
    And the expression should be true> cron_job('curator').container_spec(cached: false, name: 'curator').memory_request_raw == "200Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(cached: false, name: 'elasticsearch').memory_request_raw == "16Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(cached: false, name: 'elasticsearch').cpu_request_raw == "100m"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(cached: false, name: 'proxy').memory_request_raw == "128Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(cached: false, name: 'proxy').cpu_request_raw == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_request_cpu(cached: false) == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_request_memory(cached: false) == "16Gi"
    """
    Given I wait up to 600 seconds for the steps to pass:
    """
    And the expression should be true> cluster_logging('instance').es_node_conditions.to_s.include? "Insufficient memory"
    And the expression should be true> cluster_logging('instance').kibana_cluster_condition.to_s.include? "Insufficient memory"
    And the expression should be true> elasticsearch('elasticsearch').nodes_conditions.to_s.include? "Insufficient memory"
    And the expression should be true> cluster_logging('instance').fluentd_cluster_condition.to_s.include? "Insufficient memory"
    """

  # @author qitang@redhat.com
  # @case_id OCP-21977
  @admin
  @destructive
  Scenario: Logging should work as usual when secrets deleted or regenerated.
    Given I obtain test data file "logging/clusterlogging/example.yaml"
    When I create clusterlogging instance with:
      | remove_logging_pods | true         |
      | crd_yaml            | example.yaml |
    Then the step should succeed
    Given evaluation of `secret('master-certs').raw_resource` is stored in the :master_certs_before clipboard
    And evaluation of `secret('elasticsearch').raw_resource` is stored in the :elasticsearch_before clipboard
    And evaluation of `secret('kibana').raw_resource` is stored in the :kibana_before clipboard
    And evaluation of `secret('fluentd').raw_resource` is stored in the :fluentd_before clipboard
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    When I run the :delete client command with:
      | object_type       | secret        |
      | object_name_or_id | master-certs  |
      | object_name_or_id | elasticsearch |
    Then the step should succeed
    # CLO should recreate the secrets without changes
    Given I wait for the "master-certs" secrets to appear
    Given I wait for the "elasticsearch" secrets to appear
    Then the expression should be true> cb.master_certs_before['data']['masterca'] ==  secret('master-certs').raw_value_of('masterca', cached: false)
    And the expression should be true> cb.master_certs_before['data']['masterkey'] ==  secret('master-certs').raw_value_of('masterkey')
    And the expression should be true> cb.elasticsearch_before['data']['logging-es.crt'] == secret('elasticsearch').raw_value_of('logging-es.crt', cached: false)
    And the expression should be true> cb.elasticsearch_before['data']['logging-es.key'] == secret('elasticsearch').raw_value_of('logging-es.key')
    And the expression should be true> cb.elasticsearch_before['data']['elasticsearch.key'] == secret('elasticsearch').raw_value_of('elasticsearch.key')

    Given I register clean-up steps:
    """
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    When I run the :delete client command with:
      | object_type        | deployments              |
      | object_name_or_id  | cluster-logging-operator |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=cluster-logging-operator |
    """
    When I run the :scale client command with:
      | resource | deployments              |
      | name     | cluster-logging-operator |
      | replicas | 0                        |
    Then the step should succeed
    Given all existing pods die with labels:
      | name=cluster-logging-operator |
    Then the step should succeed
    Given I ensure "master-certs" secret is deleted
    When I run the :scale client command with:
      | resource | deployments              |
      | name     | cluster-logging-operator |
      | replicas | 1                        |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=cluster-logging-operator |
    Given I wait for the "master-certs" secrets to appear up to 300 seconds
    # seems with the new structure of the secret/master-certs, the masterca and masterkey won't change
    Given I wait up to 300 seconds for the steps to pass:
    """
    # Given the expression should be true> cb.master_certs_before['data']['masterca'] !=  secret('master-certs').raw_value_of('masterca')
    # And the expression should be true> cb.master_certs_before['data']['masterkey'] !=  secret('master-certs').raw_value_of('masterkey')
    And the expression should be true> cb.elasticsearch_before['data']['logging-es.crt'] != secret('elasticsearch').raw_value_of('logging-es.crt', cached: false)
    And the expression should be true> cb.elasticsearch_before['data']['logging-es.key'] != secret('elasticsearch').raw_value_of('logging-es.key')
    And the expression should be true> cb.elasticsearch_before['data']['elasticsearch.key'] != secret('elasticsearch').raw_value_of('elasticsearch.key')
    And the expression should be true> cb.kibana_before['data']['cert'] != secret('kibana').raw_value_of('cert', cached: false)
    And the expression should be true> cb.kibana_before['data']['key'] != secret('kibana').raw_value_of('key')
    And the expression should be true> cb.kibana_before['data']['ca'] != secret('kibana').raw_value_of('ca')
    And the expression should be true> cb.fluentd_before['data']['tls.crt'] != secret('fluentd').raw_value_of('tls.crt', cached: false)
    And the expression should be true> cb.fluentd_before['data']['ca-bundle.crt'] != secret('fluentd').raw_value_of('ca-bundle.crt')
    And the expression should be true> cb.fluentd_before['data']['tls.key'] != secret('fluentd').raw_value_of('tls.key')
    """
    # wait for the EO to remove all ES pods
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given all existing pods die with labels:
      | es-node-master=true |
    """
    # wait for the EO to redeploy ES pods
    Given I wait up to 600 seconds for the steps to pass:
    """
    Given the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").replica_counters[:desired] == deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").replica_counters[:updated]
    And a pod becomes ready with labels:
      | es-node-master=true |
    And a pod becomes ready with labels:
      | component=kibana |
    """
    Given I switch to the first user
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    # to check the fluentd could connet to the ES
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    And I wait for the project "<%= cb.proj_name %>" logs to appear in the ES pod
    # to check the Kibana console is accessible
    Given I switch to the first user
    Given I login to kibana logging web console
    Then the step should succeed
    When I run the :check_kibana_status web action
    Then the step should succeed

  # @author gkarager@redhat.com
  # @case_id OCP-34128
  @admin
  @destructive
  Scenario: Fluentd alert rules check >= 4.6.
    Given the master version >= "4.6"
    Given I obtain test data file "logging/clusterlogging/example_indexmanagement.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                         |
      | crd_yaml            | example_indexmanagement.yaml |
    Then the step should succeed
    Given I wait for the "fluentd" prometheus_rule to appear up to 300 seconds

    Then the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: 'FluentdNodeDown').severity == "critical"
    And the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: 'FluentdQueueLengthIncreasing').severity == "error"
    And the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: 'FluentDHighErrorRate').severity == "warning"
    And the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: 'FluentDVeryHighErrorRate').severity == "critical"

    Given I wait up to 300 seconds for the steps to pass:
    """
    Given I check the "fluentd" prometheus rule in the "openshift-logging" project on the prometheus server
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['name'] == "logging_fluentd.alerts"
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'FluentdNodeDown'}['labels']['severity'] == "critical"
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'FluentdQueueLengthIncreasing'}['labels']['severity'] == "error"
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'FluentDHighErrorRate'}['labels']['severity'] == "warning"
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'FluentDVeryHighErrorRate'}['labels']['severity'] == "critical"
    """
    # set managementState to Unmanaged before making changes
    Given I successfully merge patch resource "clusterlogging/instance" with:
      | {"spec": {"managementState": "Unmanaged"}} |

    Given I run the :patch client command with:
      | resource      | prometheusrule                                                                                                                                                                  |
      | resource_name | fluentd                                                                                                                                                                         |
      | p             | {"spec": {"groups": [{"name": "logging_fluentd.alerts", "rules": [{"alert": "FluentdNodeDown","expr": "absent(up{job='fluentd'} == 1)", "labels": {"severity": "warning"}}]}]}} |
      | type          | merge                                                                                                                                                                           |
    Then the step should succeed
    And the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rule_spec(alert: 'FluentdNodeDown').severity == "warning"
    And the expression should be true> prometheus_rule('fluentd').prometheus_rule_group_spec(name: "logging_fluentd.alerts").rules.count == 1

    Given I wait up to 300 seconds for the steps to pass:
    """
    Given I check the "fluentd" prometheus rule in the "openshift-logging" project on the prometheus server
    And the output should not contain:
      | FluentdQueueLengthIncreasing |
      | FluentDHighErrorRate         |
      | FluentDVeryHighErrorRate     |
    And the expression should be true> YAML.load(@result[:response])['groups'][0]['rules'].find {|e| e['alert'].start_with? 'FluentdNodeDown'}['labels']['severity'] == "warning"
    """

  # @author gkarager@redhat.com
  # @case_id OCP-33981
  @admin
  @destructive
  Scenario: logStore stanza is not required to deploy fluentd standalone
    Given I obtain test data file "logging/clusterlogging/clusterlogging-fluentd-no-logStore.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                    |
      | crd_yaml            | clusterlogging-fluentd-no-logStore.yaml |
      | check_status        | false                                   |
    Then the step should succeed
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And <%= daemon_set('fluentd').replica_counters[:desired] %> pods become ready with labels:
      | logging-infra=fluentd |

  # @author qitang@redhat.com
  # @case_id OCP-41464
  @admin
  @destructive
  Scenario: Deploy logging with customized pod resource in clusterlogging(no curator)
    Given I obtain test data file "logging/clusterlogging/customresource-fluentd-im.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                           |
      | crd_yaml            | customresource-fluentd-im.yaml |
      | check_status        | false                          |
    Then the step should succeed
    And I wait for the "elasticsearch" elasticsearch to appear up to 300 seconds
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid %>-1" deployment to appear
    And I wait for the "kibana" deployment to appear up to 300 seconds
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    Then the expression should be true> deployment('kibana').container_spec(name: 'kibana').memory_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana').cpu_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana').memory_request_raw == "1Gi"
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana').cpu_request_raw == "100m"
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana-proxy').cpu_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana-proxy').memory_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana-proxy').memory_request_raw == "100Mi"
    And the expression should be true> deployment('kibana').container_spec(name: 'kibana-proxy').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(name: 'fluentd').cpu_limit_raw == nil
    And the expression should be true> daemon_set('fluentd').container_spec(name: 'fluentd').memory_limit_raw == nil
    And the expression should be true> daemon_set('fluentd').container_spec(name: 'fluentd').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(name: 'fluentd').memory_request_raw == "1Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'elasticsearch').memory_limit_raw == "1Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'elasticsearch').cpu_limit_raw == nil
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'elasticsearch').memory_request_raw == "1Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'elasticsearch').cpu_request_raw == "100m"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'proxy').memory_limit_raw == "64Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'proxy').cpu_limit_raw == nil
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'proxy').memory_request_raw == "64Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(name: 'proxy').cpu_request_raw == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_limit_cpu == nil
    And the expression should be true> elasticsearch('elasticsearch').resource_limit_memory == nil
    And the expression should be true> elasticsearch('elasticsearch').resource_request_cpu == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_request_memory == "1Gi"
    Given I obtain test data file "logging/clusterlogging/customresource-fluentd-im_change.yaml"
    When I run the :apply client command with:
      | f | customresource-fluentd-im_change.yaml |
    Then the step should succeed

    Given I wait up to 600 seconds for the steps to pass:
    """
    And the expression should be true> deployment('kibana').container_spec(cached: false, name: 'kibana').memory_request_raw == "16Gi"
    And the expression should be true> deployment('kibana').container_spec(cached: false, name: 'kibana').cpu_request_raw == "100m"
    And the expression should be true> deployment('kibana').container_spec(cached: false, name: 'kibana-proxy').memory_request_raw == "200Mi"
    And the expression should be true> deployment('kibana').container_spec(cached: false, name: 'kibana-proxy').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(cached: false, name: 'fluentd').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(cached: false, name: 'fluentd').memory_request_raw == "16Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(cached: false, name: 'elasticsearch').memory_request_raw == "16Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(cached: false, name: 'elasticsearch').cpu_request_raw == "100m"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(cached: false, name: 'proxy').memory_request_raw == "128Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(cached: false, name: 'proxy').cpu_request_raw == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_request_cpu(cached: false) == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_request_memory(cached: false) == "16Gi"
    """
    Given I wait up to 600 seconds for the steps to pass:
    """
    And the expression should be true> cluster_logging('instance').es_node_conditions.to_s.include? "Insufficient memory"
    And the expression should be true> cluster_logging('instance').kibana_cluster_condition.to_s.include? "Insufficient memory"
    And the expression should be true> elasticsearch('elasticsearch').nodes_conditions.to_s.include? "Insufficient memory"
    And the expression should be true> cluster_logging('instance').fluentd_cluster_condition.to_s.include? "Insufficient memory"
    """

  # @author qitang@redhat.com
  # @case_id OCP-41466
  @admin
  @destructive
  Scenario: The CLO should handle the nodeSelectors correctly(no curator)
    Given I obtain test data file "logging/clusterlogging/nodeSelector-im.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                 |
      | crd_yaml            | nodeSelector-im.yaml |
      | check_status        | false                |
    Then the step should succeed
    And I wait for the "elasticsearch" elasticsearch to appear up to 300 seconds
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid %>-1" deployment to appear
    And I wait for the "kibana" deployment to appear up to 300 seconds
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    Then the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").node_selector['es'] == 'deploy'
    And the expression should be true> daemon_set('fluentd').node_selector['fluentd'] == 'deploy'
    And the expression should be true> deployment('kibana').node_selector['kibana'] == 'deploy'
    And the expression should be true> cron_job('elasticsearch-im-app').node_selector['es'] == 'deploy'
    Given I wait up to 600 seconds for the steps to pass:
    """
    And the expression should be true> cluster_logging('instance').es_node_conditions.to_s.match? (/0\/\d+ nodes are available/)
    And the expression should be true> cluster_logging('instance').kibana_cluster_condition.to_s.match? (/0\/\d+ nodes are available/)
    And the expression should be true> elasticsearch('elasticsearch').nodes_conditions.to_s.match? (/0\/\d+ nodes are available/)
    """
    Given I obtain test data file "logging/clusterlogging/nodeSelector-im_change.yaml"
    When I run the :apply client command with:
      | f | nodeSelector-im_change.yaml |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
      """
      #And the expression should be true> elasticsearch('elasticsearch').node_selector['es'] == 'deploy1'
      And the expression should be true> daemon_set('fluentd').node_selector(cached: false, quiet: true)['fluentd'] == 'deploy1'
      And the expression should be true> deployment('kibana').node_selector(cached: false, quiet: true)['kibana'] == 'deploy1'
      And the expression should be true> cron_job('elasticsearch-im-app').node_selector(cached: false, quiet: true)['es'] == 'deploy1'
      """
    Given I wait up to 600 seconds for the steps to pass:
      """
      And the expression should be true> deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').node_selector(cached: false, quiet: true)['es'] == 'deploy1'
      """

  # @author qitang@redhat.com
  # @case_id OCP-41467
  @admin
  @destructive
  Scenario: Cluster logging should add/update tolerations for logging pods(no curator).
    Given the master version >= "4.7"
    Given I obtain test data file "logging/clusterlogging/example_indexmanagement.yaml"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                         |
      | crd_yaml            | example_indexmanagement.yaml |
    Then the step should succeed
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> cb.es_genuuid != nil
    """
    And the expression should be true> deployment('kibana').tolerations == nil
    And the expression should be true> (deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').tolerations - [{"effect"=>"NoSchedule", "key"=>"node.kubernetes.io/disk-pressure", "operator"=>"Exists"}]).empty?
    And the expression should be true> cron_job('elasticsearch-im-app').tolerations == nil
    And the expression should be true> (daemon_set('fluentd').tolerations - [{"effect"=>"NoSchedule", "key"=>"node-role.kubernetes.io/master", "operator"=>"Exists"}, {"effect"=>"NoSchedule", "key"=>"node.kubernetes.io/disk-pressure", "operator"=>"Exists"}]).empty?
    Given I obtain test data file "logging/clusterlogging/tolerations-im.yaml"
    When I run the :apply client command with:
      | f | tolerations-im.yaml |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    And the expression should be true> (deployment('kibana').tolerations(cached: false) - [{"effect"=>"NoExecute", "key"=>"logging", "operator"=>"Exists", "tolerationSeconds"=>6000}]).empty?
    And the expression should be true> (deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').tolerations(cached: false) - [{"effect"=>"NoSchedule", "key"=>"node.kubernetes.io/disk-pressure", "operator"=>"Exists"}, {"effect"=>"NoExecute", "key"=>"logging", "operator"=>"Exists", "tolerationSeconds"=>6000}]).empty?
    And the expression should be true> (cron_job('elasticsearch-im-app').tolerations(cached: false) - [{"effect"=>"NoExecute", "key"=>"logging", "operator"=>"Exists", "tolerationSeconds"=>6000}]).empty?
    And the expression should be true> (daemon_set('fluentd').tolerations(cached: false) - [{"effect"=>"NoExecute", "key"=>"logging", "operator"=>"Exists", "tolerationSeconds"=>6000}, {"effect"=>"NoSchedule", "key"=>"node-role.kubernetes.io/master", "operator"=>"Exists"}, {"effect"=>"NoSchedule", "key"=>"node.kubernetes.io/disk-pressure", "operator"=>"Exists"}]).empty?
    """
