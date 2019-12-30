@clusterlogging
Feature: cluster-logging-operator related cases

  # @author qitang@redhat.com
  # @case_id OCP-21079
  @admin
  @destructive
  Scenario: The logging cluster operator shoud recreate the damonset
    Given I create clusterlogging instance with:
      | remove_logging_pods | true                                                                                                   |
      | crd_yaml            | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/clusterlogging/example.yaml |
      | log_collector       | fluentd                                                                                                |
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
