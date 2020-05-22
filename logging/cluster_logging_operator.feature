@clusterlogging
Feature: cluster-logging-operator related cases

  # @author qitang@redhat.com
  # @case_id OCP-21079
  @admin
  @destructive
  Scenario: The logging cluster operator shoud recreate the damonset
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/example.yaml |
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
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                                |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/customresource-fluentd.yaml  |
      | check_status        | false                                                                                               |
    Then the step should succeed
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And I wait for the "elasticsearch" elasticsearch to appear up to 300 seconds
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid %>-1" deployment to appear
    And I wait for the "kibana" deployment to appear
    And I wait for the "fluentd" daemon_set to appear
    Then the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana').memory_limit_raw == "2Gi"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana').cpu_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana').memory_request_raw == "1Gi"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana').cpu_request_raw == "100m"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana-proxy').cpu_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana-proxy').memory_limit_raw == "200Mi"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana-proxy').memory_request_raw == "100Mi"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana-proxy').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(user: user, name: 'fluentd').cpu_limit_raw == nil
    And the expression should be true> daemon_set('fluentd').container_spec(user: user, name: 'fluentd').memory_limit_raw == "2Gi"
    And the expression should be true> daemon_set('fluentd').container_spec(user: user, name: 'fluentd').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(user: user, name: 'fluentd').memory_request_raw == "1Gi"
    And the expression should be true> cron_job('curator').container_spec(user: user, name: 'curator').cpu_limit_raw == nil
    And the expression should be true> cron_job('curator').container_spec(user: user, name: 'curator').memory_limit_raw == "200Mi"
    And the expression should be true> cron_job('curator').container_spec(user: user, name: 'curator').cpu_request_raw == "100m"
    And the expression should be true> cron_job('curator').container_spec(user: user, name: 'curator').memory_request_raw == "100Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'elasticsearch').memory_limit_raw == "8Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'elasticsearch').cpu_limit_raw == nil
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'elasticsearch').memory_request_raw == "1Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'elasticsearch').cpu_request_raw == "100m"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'proxy').memory_limit_raw == "64Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'proxy').cpu_limit_raw == nil
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'proxy').memory_request_raw == "64Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'proxy').cpu_request_raw == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_limit_cpu == nil
    And the expression should be true> elasticsearch('elasticsearch').resource_limit_memory == "8Gi"
    And the expression should be true> elasticsearch('elasticsearch').resource_request_cpu == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_request_memory == "1Gi"

  # @author qitang@redhat.com
  # @case_id OCP-22992
  @admin
  @destructive
  Scenario: The clusterlogging handle the nodeSelector
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                     |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/nodeSelector.yaml |
      | check_status        | false                                                                                    |
    Then the step should succeed
    And I wait for the "elasticsearch" elasticsearch to appear up to 300 seconds
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid %>-1" deployment to appear
    And I wait for the "kibana" deployment to appear
    And I wait for the "fluentd" daemon_set to appear
    Then the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").node_selector['es'] == 'deploy'
    And the expression should be true> daemon_set('fluentd').node_selector['fluentd'] == 'deploy'
    And the expression should be true> deployment('kibana').node_selector['kibana'] == 'deploy'
    And the expression should be true> cron_job('curator').node_selector['curator'] == 'deploy'
    When I run the :apply client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/nodeSelector_change.yaml |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
      """
      #And the expression should be true> elasticsearch('elasticsearch').node_selector['es'] == 'deploy1'
      And the expression should be true> daemon_set('fluentd').node_selector(user: user, cached: false, quiet: true)['fluentd'] == 'deploy1'
      And the expression should be true> deployment('kibana').node_selector(user: user, cached: false, quiet: true)['kibana'] == 'deploy1'
      And the expression should be true> cron_job('curator').node_selector(user: user, cached: false, quiet: true)['curator'] == 'deploy1'
      """
    Given I wait up to 300 seconds for the steps to pass:
      """
      And the expression should be true> deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').node_selector(user: user, cached: false, quiet: true)['es'] == 'deploy1'
      """

  # @author qitang@redhat.com
  # @case_id OCP-24209
  @admin
  @destructive
  Scenario: The operator append kubernetes.io/os: linux
    Given the master version >= "4.2"
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/example.yaml |
      | check_status        | false                                                                               |
    Then the step should succeed
    And I wait for the "elasticsearch" elasticsearch to appear up to 300 seconds
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid %>-1" deployment to appear
    And I wait for the "kibana" deployment to appear
    And I wait for the "fluentd" daemon_set to appear
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").node_selector['kubernetes.io/os'] == 'linux'
    And the expression should be true> daemon_set('fluentd').node_selector['kubernetes.io/os'] == 'linux'
    And the expression should be true> deployment('kibana').node_selector['kubernetes.io/os'] == 'linux'
    And the expression should be true> cron_job('curator').node_selector['kubernetes.io/os'] == 'linux'
    When I run the :apply client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/nodeSelector.yaml |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
      """
      #And the expression should be true> elasticsearch('elasticsearch').node_selector['es'] == 'deploy'
      And the expression should be true> daemon_set('fluentd').node_selector(user: user, cached: false, quiet: true)['fluentd'] == 'deploy'
      And the expression should be true> deployment('kibana').node_selector(user: user, cached: false, quiet: true)['kibana'] == 'deploy'
      And the expression should be true> cron_job('curator').node_selector(user: user, cached: false, quiet: true)['curator'] == 'deploy'
      And the expression should be true> daemon_set('fluentd').node_selector(user: user, cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      And the expression should be true> deployment('kibana').node_selector(user: user, cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      And the expression should be true> cron_job('curator').node_selector(user: user, cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      """
    Given I wait up to 300 seconds for the steps to pass:
      """
      And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").node_selector(user: user, cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      And the expression should be true> deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').node_selector(user: user, cached: false, quiet: true)['es'] == 'deploy'
      """
    When I run the :apply client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/nodeSelector_override.yaml |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
      """
      #And the expression should be true> elasticsearch('elasticsearch').node_selector['es'] == nil
      And the expression should be true> daemon_set('fluentd').node_selector(user: user, cached: false, quiet: true)['fluentd'] == nil
      And the expression should be true> deployment('kibana').node_selector(user: user, cached: false, quiet: true)['kibana'] == nil
      And the expression should be true> cron_job('curator').node_selector(user: user, cached: false, quiet: true)['curator'] == nil
      And the expression should be true> daemon_set('fluentd').node_selector(user: user, cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      And the expression should be true> deployment('kibana').node_selector(user: user, cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      And the expression should be true> cron_job('curator').node_selector(user: user, cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      #And the expression should be true> elasticsearch('elasticsearch').node_selector['kubernetes.io/os'] == 'foo'
      """
    Given I wait up to 300 seconds for the steps to pass:
      """
      And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").node_selector(user: user, cached: false, quiet: true)['kubernetes.io/os'] == 'linux'
      And the expression should be true> deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').node_selector(user: user, cached: false, quiet: false)['es'] == nil
      """
    And I wait until ES cluster is ready

  # @author qitang@redhat.com
  # @case_id OCP-21831
  @admin
  @destructive
  Scenario: Add Management Spec field to CRs.
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/example.yaml |
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
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/example.yaml |
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
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/example.yaml |
    Then the step should succeed
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And the expression should be true> deployment('kibana').tolerations == nil
    And the expression should be true> (deployment('elasticsearch-cdm-<%= cb.es_genuuid %>-1').tolerations - [{"effect"=>"NoSchedule", "key"=>"node.kubernetes.io/disk-pressure", "operator"=>"Exists"}]).empty?
    And the expression should be true> cron_job('curator').tolerations == nil
    And the expression should be true> (daemon_set('fluentd').tolerations - [{"effect"=>"NoSchedule", "key"=>"node-role.kubernetes.io/master", "operator"=>"Exists"}, {"effect"=>"NoSchedule", "key"=>"node.kubernetes.io/disk-pressure", "operator"=>"Exists"}]).empty?
    When I run the :apply client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/customresource-fluentd.yaml |
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
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                               |
      | crd_yaml            | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/customresource-fluentd.yaml |
      | check_status        | false                                                                                              |
    Then the step should succeed
    And I wait for the "fluentd" daemon_set to appear up to 300 seconds
    And I wait for the "elasticsearch" elasticsearch to appear up to 300 seconds
    Given evaluation of `elasticsearch('elasticsearch').nodes[0]['genUUID']` is stored in the :es_genuuid clipboard
    And I wait for the "elasticsearch-cdm-<%= cb.es_genuuid %>-1" deployment to appear
    And I wait for the "kibana" deployment to appear
    And I wait for the "fluentd" daemon_set to appear
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana').memory_request_raw == "1Gi"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana').cpu_request_raw == "100m"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana-proxy').memory_request_raw == "100Mi"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana-proxy').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(user: user, name: 'fluentd').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(user: user, name: 'fluentd').memory_request_raw == "1Gi"
    And the expression should be true> cron_job('curator').container_spec(user: user, name: 'curator').cpu_request_raw == "100m"
    And the expression should be true> cron_job('curator').container_spec(user: user, name: 'curator').memory_request_raw == "100Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'elasticsearch').memory_request_raw == "1Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'elasticsearch').cpu_request_raw == "100m"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'proxy').memory_request_raw == "64Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'proxy').cpu_request_raw == "100m"
    When I run the :apply client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging/clusterlogging/customresource-fluentd_change.yaml |
    Then the step should succeed

    And I wait up to 600 seconds for the steps to pass:
    """
    Then the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana', cached: false).memory_limit_raw == "2Gi"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana').cpu_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana').memory_request_raw == "2Gi"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana').cpu_request_raw == "100m"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana-proxy').cpu_limit_raw == nil
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana-proxy').memory_limit_raw == "200Mi"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana-proxy').memory_request_raw == "200Mi"
    And the expression should be true> deployment('kibana').container_spec(user: user, name: 'kibana-proxy').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(user: user, name: 'fluentd', cached: false).cpu_limit_raw == nil
    And the expression should be true> daemon_set('fluentd').container_spec(user: user, name: 'fluentd').memory_limit_raw == "2Gi"
    And the expression should be true> daemon_set('fluentd').container_spec(user: user, name: 'fluentd').cpu_request_raw == "100m"
    And the expression should be true> daemon_set('fluentd').container_spec(user: user, name: 'fluentd').memory_request_raw == "2Gi"
    And the expression should be true> cron_job('curator').container_spec(user: user, name: 'curator', cached: false).cpu_limit_raw == nil
    And the expression should be true> cron_job('curator').container_spec(user: user, name: 'curator').memory_limit_raw == "200Mi"
    And the expression should be true> cron_job('curator').container_spec(user: user, name: 'curator').cpu_request_raw == "100m"
    And the expression should be true> cron_job('curator').container_spec(user: user, name: 'curator').memory_request_raw == "200Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'elasticsearch', cached: false).memory_limit_raw == "8Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'elasticsearch').cpu_limit_raw == nil
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'elasticsearch').memory_request_raw == "2Gi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'elasticsearch').cpu_request_raw == "100m"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'proxy').memory_limit_raw == "64Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'proxy').cpu_limit_raw == nil
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'proxy').memory_request_raw == "64Mi"
    And the expression should be true> deployment("elasticsearch-cdm-<%= cb.es_genuuid %>-1").container_spec(user: user, name: 'proxy').cpu_request_raw == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_limit_cpu(cached: false) == nil
    And the expression should be true> elasticsearch('elasticsearch').resource_limit_memory(cached: false) == "8Gi"
    And the expression should be true> elasticsearch('elasticsearch').resource_request_cpu(cached: false) == "100m"
    And the expression should be true> elasticsearch('elasticsearch').resource_request_memory(cached: false) == "2Gi"
    """