Feature: Install and configuration related scenarios
  # @author juzhao@redhat.com
  # @case_id OCP-26041
  @admin
  Scenario: cookie_secure is true in grafana route
    Given the master version >= "4.3"
    Given I switch to the first user
    And the first user is cluster-admin
    And I use the "openshift-monitoring" project

    Given a pod becomes ready with labels:
      | app=grafana |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>          |
      | c                | grafana                  |
      | exec_command     | cat                      |
      | exec_command_arg | /etc/grafana/grafana.ini |
    Then the output should contain:
      | cookie_secure = true                        |

  # @author juzhao@redhat.com
  # @case_id OCP-23705
  @admin
  Scenario: non-monitoring ServiceMonitors are moved out of cluster-monitoring-operator
    Given the master version >= "4.2"
    Given I switch to the first user
    And the first user is cluster-admin
    And I use the "openshift-monitoring" project

    When I run the :get client command with:
      | resource | ServiceMonitor |
    Then the output should not contain:
      | cluster-version-operator  |
      | kube-apiserver            |
      | kube-controller-manager   |
      | kube-scheduler            |
      | openshift-apiserver       |

  # @author hongyli@redhat.com
  # @case_id OCP-28587
  @admin
  Scenario: Add node label to container_fs_usage_bytes
    Given the master version >= "4.1"
    And the first user is cluster-admin

    # get sa/prometheus-k8s token
    When I run the :serviceaccounts_get_token admin command with:
      | serviceaccount_name | prometheus-k8s       |
      | n                   | openshift-monitoring |
    Then the step should succeed
    And evaluation of `@result[:stdout]` is stored in the :sa_token clipboard

    # get prometheus pod
    And I use the "openshift-monitoring" project
    Given a pod becomes ready with labels:
      | statefulset.kubernetes.io/pod-name=prometheus-k8s-0 |
    Then evaluation of `pod.ip` is stored in the :prometheusk8s_pod_id clipboard

    # check container_fs_usage
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://<%= cb.prometheusk8s_pod_id %>:9091/api/v1/query?query=count%28container_fs_usage_bytes%29%20by%20%28node%29 |
    Then the step should succeed
    And the output should contain:
      | "node": |

  # @author hongyli@redhat.com
  # @case_id OCP-27998
  @admin
  Scenario: Duplicate sharing-config configmap into openshift-config-managed namespace
    Given the master version >= "4.4"
    And the first user is cluster-admin
    And I use the "openshift-monitoring" project
    And evaluation of `config_map('sharing-config').data['alertmanagerURL']` is stored in the :alertmanagerURL clipboard
    And evaluation of `config_map('sharing-config').data['grafanaURL']` is stored in the :grafanaURL clipboard
    And evaluation of `config_map('sharing-config').data['prometheusURL']` is stored in the :prometheusURL clipboard
    And evaluation of `config_map('sharing-config').data['thanosURL']` is stored in the :thanosURL clipboard
    And I use the "openshift-config-managed" project
    Then the expression should be true> cb.alertmanagerURL == config_map('monitoring-shared-config').data['alertmanagerPublicURL']
    Then the expression should be true> cb.grafanaURL == config_map('monitoring-shared-config').data['grafanaPublicURL']
    Then the expression should be true> cb.prometheusURL == config_map('monitoring-shared-config').data['prometheusPublicURL']
    Then the expression should be true> cb.thanosURL == config_map('monitoring-shared-config').data['thanosPublicURL']

  # @author hongyli@redhat.com
  # @case_id OCP-28951
  @admin
  Scenario: Secure cluster-monitoring-operator/prometheus-operator endpoints
    Given the master version >= "4.5"
    And the first user is cluster-admin
    When I use the "openshift-monitoring" project
    Then the expression should be true> service_monitor('cluster-monitoring-operator').service_monitor_endpoints_spec.first.scheme == 'https'
    Then the expression should be true> service_monitor('prometheus-operator').service_monitor_endpoints_spec.first.scheme == 'https'

    # get cluster-monitoring-operator endpoint
    When evaluation of `endpoints('cluster-monitoring-operator').subsets.first.addresses.first.ip.to_s` is stored in the :cmo_endpoint_ip clipboard
    And evaluation of `endpoints('cluster-monitoring-operator').subsets.first.ports.first.port.to_s` is stored in the :cmo_endpoint_port clipboard
    And evaluation of `cb.cmo_endpoint_ip + ':' +cb.cmo_endpoint_port` is stored in the :cmo_endpoint clipboard

    # get prometheus-operator endpoint
    And evaluation of `endpoints('prometheus-operator').subsets.first.addresses.first.ip.to_s` is stored in the :po_endpoint_ip clipboard
    And evaluation of `endpoints('prometheus-operator').subsets.first.ports.first.port.to_s` is stored in the :po_endpoint_port clipboard
    And evaluation of `cb.po_endpoint_ip + ':' +cb.po_endpoint_port` is stored in the :po_endpoint clipboard

    # Get metrics from cluster-monitoring-operator endpoint without Authorization Bearer token
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k https://<%= cb.cmo_endpoint %>/metrics |
    Then the step should succeed
    And the output should contain:
      | Unauthorized |

    # Get metrics from prometheus-operator endpoint without Authorization Bearer token
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k https://<%= cb.po_endpoint %>/metrics |
    Then the step should succeed
    And the output should contain:
      | Unauthorized |

    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    # Get metrics from cluster-monitoring-operator endpoint and check content
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://<%= cb.cmo_endpoint %>/metrics |
    Then the step should succeed
    And the output should contain:
      | cluster_monitoring_operator_reconcile_attempts_total |

    # Get metrics from prometheus-operator endpoint and check content
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://<%= cb.po_endpoint %>/metrics |
    Then the step should succeed
    And the output should contain:
      | prometheus_operator_watch_operations_total |