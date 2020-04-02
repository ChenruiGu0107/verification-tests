Feature: admin console api related

  # @author yapei@redhat.com
  # @case_id OCP-25816
  @admin
  Scenario: Expose console_url metrics in console-operator metric
    Given the master version >= "4.2"
    Given I open admin console in a browser
    And the first user is cluster-admin

    # get sa/prometheus-k8s token
    When I run the :serviceaccounts_get_token admin command with:
      | serviceaccount_name | prometheus-k8s |
      | n | openshift-monitoring |
    Then the step should succeed
    And evaluation of `@result[:stdout]` is stored in the :sa_token clipboard

    # get console route host and operator pod
    And I use the "openshift-console" project
    Given evaluation of `route('console').spec.host` is stored in the :console_route clipboard

    And I use the "openshift-console-operator" project
    Given a pod becomes ready with labels:
      | name=console-operator |
    Then evaluation of `pod.ip` is stored in the :console_operator_pod_id clipboard

    # check metrics exposed
    When I run the :exec admin command with:
      | n                | openshift-console-operator |
      | pod              | <%= pod.name %>            |
      | oc_opts_end      |                            |
      | exec_command     | sh                         |
      | exec_command_arg | -c                         |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://<%= cb.console_operator_pod_id %>:8443/metrics |
    Then the step should succeed
    And the output should match 1 times:
      | ^console_url |
    And the output should match 1 times:
      | ^console_url.*url.*https://<%= cb.console_route %>.*1 |

    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed
    When I perform the :query_metrics web action with:
      | metrics_name | console_url |
    Then the step should succeed
    When I perform the :check_metrics_query_result web action with:
      | metrics_name | console_url |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-27901
  @admin
  Scenario: Console backend should proxy requests for config maps for dashboard configuration
    Given the master version >= "4.4"

    # grant normal user auto-test-metrics-reader cluster role
    Given admin ensures "auto-test-metrics-reader" cluster_role is deleted after scenario
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/rbac/metrics-reader-cluster-role.yaml |
    Then the step should succeed
    Given cluster role "auto-test-metrics-reader" is added to the "first" user

    # normal user with metrics-reader role can view all Dashboards
    Given I open admin console in a browser
    When I perform the :click_secondary_menu web action with:
      | primary_menu   | Monitoring |
      | secondary_menu | Dashboards |
    Then the step should succeed
    When I run the :check_grafana_dashboard_body_loaded web action
    Then the step should succeed
    When I run the :check_dashboard_dropdown_items web action
    Then the step should succeed
