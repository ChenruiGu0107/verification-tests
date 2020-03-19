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
