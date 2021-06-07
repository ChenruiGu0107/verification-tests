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
      | cookie_secure = true |

  # @author hongyli@redhat.com
  # @case_id OCP-40320
  @admin
  Scenario: 4.8 and above cookie_secure is true in grafana route
    Given the master version >= "4.8"
    Given I switch to the first user
    And the first user is cluster-admin
    And I use the "openshift-monitoring" project

    Given a pod becomes ready with labels:
      | app.kubernetes.io/name=grafana |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>          |
      | c                | grafana                  |
      | exec_command     | cat                      |
      | exec_command_arg | /etc/grafana/grafana.ini |
    Then the output should contain:
      | cookie_secure = true |

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

    # check container_fs_usage
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query?query=count%28container_fs_usage_bytes%29%20by%20%28node%29 |
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
    And evaluation of `cb.po_endpoint_ip + ':8443'` is stored in the :po_endpoint clipboard

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

  # @author hongyli@redhat.com
  # @case_id OCP-29314
  @admin
  Scenario: telemetry whitelist metrics could be configured via configmap
    Given the master version >= "4.4"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    #Check metrics in telemetry-config configmap
    When evaluation of `YAML.load(config_map("telemetry-config").value_of("metrics.yaml"))["matches"]` is stored in the :metrics_cm clipboard
    #Check metrics in telemetry-client deploy
    And evaluation of `deployment('telemeter-client').containers.first['command'].map {|n| n[/\{(.*)\}/]}.compact!` is stored in the :metrics_deploy clipboard
    Then the expression should be true> cb.metrics_cm == cb.metrics_deploy

  # @author hongyli@redhat.com
  # @case_id OCP-26541
  @admin
  Scenario: Do not preserve unknown fields inside all Prometheus Operator related CRDs
    Given the master version >= "4.4"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    #oc get crd | grep monitoring | awk '{print $1}'
    When I run the :get client command with:
      | resource | crd |
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)monitoring.coreos.com(.*)/]}.compact!` is stored in the :crds_monitoring clipboard
    #check "oc get crd $i -oyaml | grep preserveUnknownFields" for all resources
    When I repeat the following steps for each :crd in cb.crds_monitoring:
    """
    When I get project crd named "#{cb.crd}" as YAML
    Then the output should not contain "preserveUnknownFields: true"
    """
    # explain all monitoring's crb
    When evaluation of `cb.crds_monitoring.map{|n| n.split(/\./)[0]}` is stored in the :crds_short clipboard
    And I repeat the following steps for each :crd_s in cb.crds_short:
    """
    When I run the :explain client command with:
      | resource | #{cb.crd_s} |
    Then the output should not contain "<empty>"
    """

  # @author hongyli@redhat.com
  # @case_id OCP-30088
  Scenario: User can not deploy ThanosRuler CRs in user namespaces
    Given the master version >= "4.5"
    #create project and deploy pod
    Given I create a project with non-leading digit name
    Then the step should succeed
    Given I obtain test data file "monitoring/thanos-ruler-ocp-30088.yaml"
    When I run the :apply client command with:
      | f         | thanos-ruler-ocp-30088.yaml |
      | overwrite | true                        |
    Then the step should fail
    And the output should contain:
      | Error from server (Forbidden): |

  # @author hongyli@redhat.com
  # @case_id OCP-24297
  @admin
  @destructive
  Scenario: Expose remote-write configuration via cluster-monitoring-operator ConfigMap
    Given the master version >= "4.2"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #create cluster-monitoring-config configmap
    Given I obtain test data file "monitoring/config_map_remote_write-ocp-24297.yaml"
    When I run the :apply client command with:
      | f         | config_map_remote_write-ocp-24297.yaml |
      | overwrite | true                                   |
    Then the step should succeed

    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    # query prometheus_remote_storage_shards
    And I wait up to 240 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query?query=prometheus_remote_storage_shards |
    Then the step should succeed
    And the output should contain:
      | http://localhost:1234/receive |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-29748
  @admin
  @destructive
  Scenario: [BZ 1821268] Thanos Ruler should send alerts to all Alertmanager pods
    #<=4.6
    Given the master version >= "4.5"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                           |
    Then the step should succeed
    Given I use the "openshift-user-workload-monitoring" project
    And I wait up to 300 seconds for the steps to pass:
    """
    When the pod named "prometheus-user-workload-1" status becomes :running
    And the pod named "thanos-ruler-user-workload-1" status becomes :running
    """
    #Deploy prometheus rules under user's namespace
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "monitoring/prometheus_rules-drill.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-drill.yaml |
      | overwrite | true                        |
    Then the step should succeed
    #Check the newly created alert are sent to pod alertmanager-main-0 for we can't check all the pods in a loop and wait time at the same time
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -s http://localhost:9093/api/v2/alerts |
    Then the step should succeed
    And the output should contain:
      | "alertname":"DrillAlert" |
    """
    # get alerts pods
    When I run the :get client command with:
      | resource | pod                  |
      | n        | openshift-monitoring |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)alertmanager-main(.*)/]}.compact!` is stored in the :alert_pods clipboard
    #Check the newly created alert are sent to all Alertmanager pods
    When I repeat the following steps for each :pod_name in cb.alert_pods:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | #{cb.pod_name}       |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -s http://localhost:9093/api/v2/alerts |
    Then the step should succeed
    And the output should contain:
      | "alertname":"DrillAlert" |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-37303
  @admin
  @destructive
  Scenario: 4.7 and above-Thanos Ruler should send alerts to all Alertmanager pods
    Given the master version >= "4.7"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed
    When evaluation of `infrastructure("cluster").infra_topology=="SingleReplica"?"0":"1"` is stored in the :prometheusPodNum clipboard
    Given I use the "openshift-user-workload-monitoring" project
    When the pod named "prometheus-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    And the pod named "thanos-ruler-user-workload-<%= cb.prometheusPodNum %>" status becomes :running

    #Deploy prometheus rules under user's namespace
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "monitoring/prometheus_rules-drill.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-drill.yaml |
      | overwrite | true                        |
    Then the step should succeed
    #Check the newly created alert are sent to pod alertmanager-main-0 for we can't check all the pods in a loop and wait time at the same time
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -s http://localhost:9093/api/v2/alerts |
    Then the step should succeed
    And the output should contain:
      | "alertname":"DrillAlert" |
    """
    # get alerts pods
    When I run the :get client command with:
      | resource | pod                  |
      | n        | openshift-monitoring |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)alertmanager-main(.*)/]}.compact!` is stored in the :alert_pods clipboard
    #Check the newly created alert are sent to all Alertmanager pods
    When I repeat the following steps for each :pod_name in cb.alert_pods:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | #{cb.pod_name}       |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -s http://localhost:9093/api/v2/alerts |
    Then the step should succeed
    And the output should contain:
      | "alertname":"DrillAlert" |
    """


  # @author hongyli@redhat.com
  # @case_id OCP-25860
  @admin
  @destructive
  Scenario: Set ignoreNamespaceSelectors field in cluster-monitoring-operator Custom Resource
    #<=4.6
    Given the master version >= "4.3"
    And I switch to cluster admin pseudo user
    And I use the "openshift-user-workload-monitoring" project
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                           |
    Then the step should succeed
    # check ignoreNamespaceSelectors is set
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | prometheus    |
      | resource_name | user-workload |
      | o             | yaml          |
    Then the output should contain:
      | ignoreNamespaceSelectors: true |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-37305
  @admin
  @destructive
  Scenario: 4.7 and above-Set ignoreNamespaceSelectors field in cluster-monitoring-operator Custom Resource
    Given the master version >= "4.7"
    And I switch to cluster admin pseudo user
    And I use the "openshift-user-workload-monitoring" project
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed
    # check ignoreNamespaceSelectors is set
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | prometheus    |
      | resource_name | user-workload |
      | o             | yaml          |
    Then the output should contain:
      | ignoreNamespaceSelectors: true |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-21576
  @admin
  @destructive
  Scenario: Disable Telemeter Client
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    #config monitoring to disable telemeter client
    Given I obtain test data file "monitoring/config_map-disable-ocp-21576.yaml"
    When I run the :apply client command with:
      | f         | config_map-disable-ocp-21576.yaml |
      | overwrite | true                              |
    Then the step should succeed
    #oc get pod | grep telemeter-client
    Then I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pod |
    And the output should not contain:
      | telemeter-client |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-22528
  @admin
  @destructive
  Scenario: Modify the retention time for Prometheus metrics data
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    Given I obtain test data file "monitoring/config_map-retention-ocp-22528.yaml"
    When I run the :apply client command with:
      | f         | config_map-retention-ocp-22528.yaml |
      | overwrite | true                                |
    Then the step should succeed
    #check retention time
    Then I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | prometheus |
      | resource_name | k8s        |
      | o             | yaml       |
    Then the expression should be true> YAML.load(@result[:stdout])["spec"]["retention"] == "3h"
    """
    When I run the :get client command with:
      | resource      | statefulset    |
      | resource_name | prometheus-k8s |
      | o             | yaml           |
    Then the output should contain:
      | storage.tsdb.retention.time=3h |

  # @author juzhao@redhat.com
  # @case_id OCP-28866
  @admin
  @destructive
  Scenario: Adding additional metadata to your time-series
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #create cluster-monitoring-config configmap
    Given I obtain test data file "monitoring/externalLabels.yaml"
    When I run the :apply client command with:
      | f         | externalLabels.yaml |
      | overwrite | true                |
    Then the step should succeed

    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    # query Watchdog alerts
    And I wait up to 240 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://alertmanager-main.openshift-monitoring.svc:9094/api/v2/alerts?filter={alertname="Watchdog"} |

    Then the step should succeed
    And the output should contain:
      | "region":"unknown"      |
      | "environment":"testing" |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-20448
  @admin
  Scenario: cluster monitoring Prometheus UI check
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    And evaluation of `route('prometheus-k8s').spec.host` is stored in the :prom_route clipboard
    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    #query an metric
    When I perform the HTTP request:
    """
    :url: https://<%= cb.prom_route %>/api/v1/query?query=alertmanager_alerts
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | "__name__":"alertmanager_alerts" |

    #check alerts page
    When I perform the HTTP request:
    """
    :url: https://<%= cb.prom_route %>/api/v1/rules?type=alert
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | Watchdog |

    #check targets page
    When I perform the HTTP request:
    """
    :url: https://<%= cb.prom_route %>/api/v1/targets?state=active
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | metrics |
      | up      |

  # @author hongyli@redhat.com
  # @case_id OCP-28957
  @admin
  @destructive
  Scenario: Alerting rules with the same name and different namespaces should not offend each other
    #<=4.6
    Given the master version >= "4.5"
    And the first user is cluster-admin

    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :project_name1 clipboard
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :project_name2 clipboard

    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                           |
    Then the step should succeed
    Given I use the "openshift-user-workload-monitoring" project
    And I wait up to 300 seconds for the steps to pass:
    """
    When the pod named "prometheus-user-workload-1" status becomes :running
    And the pod named "thanos-ruler-user-workload-1" status becomes :running
    """
    #Deploy prometheus rules under proj1
    When I use the "<%= cb.project_name1 %>" project
    Given I obtain test data file "monitoring/prometheus_rules-OCP-28957.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-OCP-28957.yaml |
      | overwrite | true                                  |
    Then the step should succeed
    #Deploy prometheus rules under proj2
    When I use the "<%= cb.project_name2 %>" project
    Given I obtain test data file "monitoring/prometheus_rules-OCP-28957.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-OCP-28957.yaml |
      | overwrite | true                                  |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | thanosruler                        |
      | resource_name | user-workload                      |
      | n             | openshift-user-workload-monitoring |
      | o             | yaml                               |
    Then the step should succeed
    And the output should contain:
      | enforcedNamespaceLabel: namespace |
    """
    When I use the "openshift-user-workload-monitoring" project
    And evaluation of `route('thanos-ruler').spec.host` is stored in the :thanos_ruler_route clipboard
    When I use the "openshift-monitoring" project
    And evaluation of `route('thanos-querier').spec.host` is stored in the :thanos_querier_route clipboard
    And evaluation of `route('alertmanager-main').spec.host` is stored in the :alertmanager_route clipboard
    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    #Check thanos querier from svc to wait for some time
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/query?query=ALERTS%7Balertname%3D%22Watchdog%22%7D |
    Then the step should succeed
    And the output should contain:
      | <%= cb.project_name1 %> |
      | <%= cb.project_name2 %> |
    """
    #check alertmanager
    When I perform the HTTP request:
    """
    :url: https://<%= cb.alertmanager_route %>/api/v2/alerts/groups?filter=alertname%3D%22Watchdog%22&
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | <%= cb.project_name1 %> |
      | <%= cb.project_name2 %> |

    #check thanos rule
    When I perform the HTTP request:
    """
    :url: https://<%= cb.thanos_ruler_route %>/alerts
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | alertname="Watchdog"    |
      | <%= cb.project_name1 %> |
      | <%= cb.project_name2 %> |
    ##check thanos alerts
    When I perform the HTTP request:
    """
    :url: https://<%= cb.thanos_ruler_route %>/rules
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | Watchdog                |
      | <%= cb.project_name1 %> |
      | <%= cb.project_name2 %> |

  # @author hongyli@redhat.com
  # @case_id OCP-37307
  @admin
  @destructive
  Scenario: 4.7 and above-Alerting rules with the same name and different namespaces should not offend each other
    Given the master version >= "4.7"
    And the first user is cluster-admin

    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :project_name1 clipboard
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :project_name2 clipboard

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed
    When evaluation of `infrastructure("cluster").infra_topology=="SingleReplica"?"0":"1"` is stored in the :prometheusPodNum clipboard
    Given I use the "openshift-user-workload-monitoring" project
    When the pod named "prometheus-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    And the pod named "thanos-ruler-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    
    #Deploy prometheus rules under proj1
    When I use the "<%= cb.project_name1 %>" project
    Given I obtain test data file "monitoring/prometheus_rules-OCP-28957.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-OCP-28957.yaml |
      | overwrite | true                                  |
    Then the step should succeed
    #Deploy prometheus rules under proj2
    When I use the "<%= cb.project_name2 %>" project
    Given I obtain test data file "monitoring/prometheus_rules-OCP-28957.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-OCP-28957.yaml |
      | overwrite | true                                  |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | thanosruler                        |
      | resource_name | user-workload                      |
      | n             | openshift-user-workload-monitoring |
      | o             | yaml                               |
    Then the step should succeed
    And the output should contain:
      | enforcedNamespaceLabel: namespace |
    """
    When I use the "openshift-user-workload-monitoring" project
    And evaluation of `route('thanos-ruler').spec.host` is stored in the :thanos_ruler_route clipboard
    When I use the "openshift-monitoring" project
    And evaluation of `route('thanos-querier').spec.host` is stored in the :thanos_querier_route clipboard
    And evaluation of `route('alertmanager-main').spec.host` is stored in the :alertmanager_route clipboard
    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard
    #Check thanos querier from svc to wait for some time
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/query?query=ALERTS%7Balertname%3D%22Watchdog%22%7D |
    Then the step should succeed
    And the output should contain:
      | <%= cb.project_name1 %> |
      | <%= cb.project_name2 %> |
    """
    #check alertmanager
    When I perform the HTTP request:
    """
    :url: https://<%= cb.alertmanager_route %>/api/v2/alerts/groups?filter=alertname%3D%22Watchdog%22&
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | <%= cb.project_name1 %> |
      | <%= cb.project_name2 %> |

    #check thanos rule
    When I perform the HTTP request:
    """
    :url: https://<%= cb.thanos_ruler_route %>/alerts
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | alertname="Watchdog"    |
      | <%= cb.project_name1 %> |
      | <%= cb.project_name2 %> |
    ##check thanos alerts
    When I perform the HTTP request:
    """
    :url: https://<%= cb.thanos_ruler_route %>/rules
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | Watchdog                |
      | <%= cb.project_name1 %> |
      | <%= cb.project_name2 %> |

  # @author hongyli@redhat.com
  # @case_id OCP-28961
  @admin
  @destructive
  Scenario: Deploy ThanosRuler in user-workload-monitoring
    #<=4.6
    Given the master version >= "4.5"
    And I switch to cluster admin pseudo user
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    And admin ensures "ocp-28961-proj" project is deleted after scenario

    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                           |
    Then the step should succeed
    #ThanosRuler related resouces are created
    When I use the "openshift-user-workload-monitoring" project
    And I wait up to 300 seconds for the steps to pass:
    """
    When the pod named "prometheus-user-workload-1" status becomes :running
    And the pod named "thanos-ruler-user-workload-1" status becomes :running
    """
    When I run the :get client command with:
      | resource | ThanosRuler |
    Then the step should succeed
    And the output should contain:
      | user-workload |
    When I run the :get client command with:
      | resource | configmaps |
    Then the step should succeed
    And the output should contain:
      | prometheus-user-workload-rulefiles   |
      | serving-certs-ca-bundle              |
      | thanos-ruler-trusted-ca-bundle       |
      | thanos-ruler-user-workload-rulefiles |
    When I run the :get client command with:
      | resource | services |
    Then the step should succeed
    And the output should contain:
      | prometheus-operated      |
      | prometheus-operator      |
      | prometheus-user-workload |
      | thanos-ruler             |
      | thanos-ruler-operated    |
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should contain:
      | prometheus-operated      |
      | prometheus-operator      |
      | prometheus-user-workload |
      | thanos-ruler             |
      | thanos-ruler-operated    |
    # check the prometheusrule/thanos-ruler is created, and these rules could be found on prometheus-k8s UI, not on thanos-ruler UI
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | prometheusrule |
      | resource_name | thanos-ruler   |
      | o             | yaml           |
    Then the step should succeed
    And the output should contain:
      | thanos-rule.rules               |
    """
    When evaluation of `route('thanos-ruler').spec.host` is stored in the :thanos_ruler_route clipboard
    When I use the "openshift-monitoring" project
    Then evaluation of `route('prometheus-k8s').spec.host` is stored in the :prom_route clipboard
    And evaluation of `route('thanos-querier').spec.host` is stored in the :thanos_querier_route clipboard
    # get sa/prometheus-k8s token
    And evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    #check rules could be found on prometheus-k8s UI, not on thanos-ruler UI
    When I perform the HTTP request:
      """
      :url: https://<%= cb.thanos_ruler_route %>/rules
      :method: get
      :headers:
        :Authorization: Bearer <%= cb.sa_token %>
      """
    Then the step should succeed
    And the output should not contain:
      | thanos-rule.rules |

    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/rules |
    Then the step should succeed
    And the output should contain:
      | thanos-rule.rules |
    """

    #Create one project and prometheus rules under it
    When I run the :new_project client command with:
      | project_name | ocp-28961-proj |
    Then the step should succeed
    Given I obtain test data file "monitoring/prometheus_rules.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules.yaml |
      | overwrite | true                  |
    Then the step should succeed
    Given I obtain test data file "monitoring/pod_wrong_image-ocp-28961.yaml"
    When I run the :apply client command with:
      | f         | pod_wrong_image-ocp-28961.yaml |
      | overwrite | true                           |
    Then the step should succeed
    #Check thanos querier from svc to wait for some time
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/query?query=ALERTS%7Balertname%3D%22KubePodNotReady%22%2Cnamespace%3D%22ocp-28961-proj%22%7D |
    Then the step should succeed
    And the output should contain:
      | KubePodNotReady |
    """
    #alerts can be found in thanos-ruler page
    When I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-ruler.openshift-user-workload-monitoring.svc:9091/alerts |
    Then the step should succeed
    And the output should contain:
      | KubePodNotReady |
      | Watchdog        |
      | TargetDown      |
    """
    #check rules could be found on thanos-ruler UI with specific project
    When I perform the HTTP request:
      """
      :url: https://<%= cb.thanos_ruler_route %>/rules
      :method: get
      :headers:
         :Authorization: Bearer <%= cb.sa_token %>
      """
    Then the step should succeed
    And the output should contain:
      | KubePodNotReady |
      | requests_total  |
      | ocp-28961-proj  |

  # @author hongyli@redhat.com
  # @case_id OCP-37308
  @admin
  @destructive
  Scenario: 4.7 and above-Deploy ThanosRuler in user-workload-monitoring
    Given the master version >= "4.7"
    And I switch to cluster admin pseudo user
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    And admin ensures "ocp-28961-proj" project is deleted after scenario

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed
    #ThanosRuler related resouces are created
    When evaluation of `infrastructure("cluster").infra_topology=="SingleReplica"?"0":"1"` is stored in the :prometheusPodNum clipboard
    Given I use the "openshift-user-workload-monitoring" project
    When the pod named "prometheus-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    And the pod named "thanos-ruler-user-workload-<%= cb.prometheusPodNum %>" status becomes :running

    When I run the :get client command with:
      | resource | ThanosRuler |
    Then the step should succeed
    And the output should contain:
      | user-workload |
    When I run the :get client command with:
      | resource | configmaps |
    Then the step should succeed
    And the output should contain:
      | prometheus-user-workload-rulefiles   |
      | serving-certs-ca-bundle              |
      | thanos-ruler-trusted-ca-bundle       |
      | thanos-ruler-user-workload-rulefiles |
    When I run the :get client command with:
      | resource | services |
    Then the step should succeed
    And the output should contain:
      | prometheus-operated      |
      | prometheus-operator      |
      | prometheus-user-workload |
      | thanos-ruler             |
      | thanos-ruler-operated    |
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should contain:
      | prometheus-operated      |
      | prometheus-operator      |
      | prometheus-user-workload |
      | thanos-ruler             |
      | thanos-ruler-operated    |
    # check the prometheusrule/thanos-ruler is created, and these rules could be found on prometheus-k8s UI, not on thanos-ruler UI
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | prometheusrule |
      | resource_name | thanos-ruler   |
      | o             | yaml           |
    Then the step should succeed
    And the output should contain:
      | ThanosNoRuleEvaluations |
    """
    When evaluation of `route('thanos-ruler').spec.host` is stored in the :thanos_ruler_route clipboard
    When I use the "openshift-monitoring" project
    Then evaluation of `route('prometheus-k8s').spec.host` is stored in the :prom_route clipboard
    And evaluation of `route('thanos-querier').spec.host` is stored in the :thanos_querier_route clipboard
    # get sa/prometheus-k8s token
    And evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    #check rules could be found on prometheus-k8s UI, not on thanos-ruler UI
    When I perform the HTTP request:
      """
      :url: https://<%= cb.thanos_ruler_route %>/rules
      :method: get
      :headers:
        :Authorization: Bearer <%= cb.sa_token %>
      """
    Then the step should succeed
    And the output should not contain:
      | ThanosNoRuleEvaluations |

    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/rules |
    Then the step should succeed
    And the output should contain:
      | ThanosNoRuleEvaluations |
    """

    #Create one project and prometheus rules under it
    When I run the :new_project client command with:
      | project_name | ocp-28961-proj |
    Then the step should succeed
    Given I obtain test data file "monitoring/prometheus_rules.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules.yaml |
      | overwrite | true                  |
    Then the step should succeed
    Given I obtain test data file "monitoring/pod_wrong_image-ocp-28961.yaml"
    When I run the :apply client command with:
      | f         | pod_wrong_image-ocp-28961.yaml |
      | overwrite | true                           |
    Then the step should succeed
    #Check thanos querier from svc to wait for some time
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/query?query=ALERTS%7Balertname%3D%22KubePodNotReady%22%2Cnamespace%3D%22ocp-28961-proj%22%7D |
    Then the step should succeed
    And the output should contain:
      | KubePodNotReady |
    """
    #alerts can be found in thanos-ruler page
    When I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-ruler.openshift-user-workload-monitoring.svc:9091/alerts |
    Then the step should succeed
    And the output should contain:
      | KubePodNotReady |
      | Watchdog        |
      | TargetDown      |
    """
    #check rules could be found on thanos-ruler UI with specific project
    When I perform the HTTP request:
      """
      :url: https://<%= cb.thanos_ruler_route %>/rules
      :method: get
      :headers:
         :Authorization: Bearer <%= cb.sa_token %>
      """
    Then the step should succeed
    And the output should contain:
      | KubePodNotReady |
      | requests_total  |
      | ocp-28961-proj  |

  # @author hongyli@redhat.com
  # @case_id OCP-25925
  @admin
  @destructive
  Scenario: Expose configuration to enable the service monitoring extension
    #<=4.6
    Given the master version >= "4.3"
    And I switch to cluster admin pseudo user
    Given admin ensures "ocp-25925-proj" project is deleted after scenario

    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                           |
    Then the step should succeed

    #Check resources are created under openshift-user-workload-monitoring namespaces
    When I use the "openshift-user-workload-monitoring" project
    And I wait up to 300 seconds for the steps to pass:
    """
    When the pod named "prometheus-user-workload-1" status becomes :running
    And the pod named "thanos-ruler-user-workload-1" status becomes :running
    """
    When I run the :get client command with:
      | resource | all                                |
      | n        | openshift-user-workload-monitoring |
    Then the step should succeed
    And the output should contain:
      | pod/prometheus-operator-                  |
      | pod/prometheus-user-workload-             |
      | service/prometheus-operated               |
      | service/prometheus-operator               |
      | service/prometheus-user-workload          |
      | deployment.apps/prometheus-operator       |
      | replicaset.apps/prometheus-operator       |
      | statefulset.apps/prometheus-user-workload |

    #Create one namespace, create resources in the namespace
    When I run the :new_project client command with:
      | project_name | ocp-25925-proj |
    Then the step should succeed
    Given I obtain test data file "monitoring/prometheus-example-app.yaml"
    When I run the :apply client command with:
      | f         | prometheus-example-app.yaml |
      | overwrite | true                        |
    Then the step should succeed
    When I run the :get client command with:
      | resource | pod            |
      | n        | ocp-25925-proj |
    Then the step should succeed
    Then the output should match 1 times:
      | prometheus |
    And the output should not contain:
      | alertmanager |

    When I use the "openshift-monitoring" project
    And evaluation of `route('thanos-querier').spec.host` is stored in the :thanos_querier_route clipboard
    # get sa/prometheus-k8s token
    And evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    #Check thanos querier from svc to wait for some time
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/query?query=version |
    Then the step should succeed
    And the output should contain:
      | prometheus-example-app |
      | ocp-25925-proj         |
    """

    When I run the :delete client command with:
      | object_type       | configmap                 |
      | object_name_or_id | cluster-monitoring-config |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | all                                |
      | n        | openshift-user-workload-monitoring |
    Then the step should succeed
    And the output should contain:
      | No resources found |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-37298
  @admin
  @destructive
  Scenario: 4.7 and above-Expose configuration to enable the service monitoring extension
    Given the master version >= "4.7"
    And I switch to cluster admin pseudo user
    Given admin ensures "ocp-25925-proj" project is deleted after scenario

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed

    #Check resources are created under openshift-user-workload-monitoring namespaces
    When evaluation of `infrastructure("cluster").infra_topology=="SingleReplica"?"0":"1"` is stored in the :prometheusPodNum clipboard
    Given I use the "openshift-user-workload-monitoring" project
    When the pod named "prometheus-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    And the pod named "thanos-ruler-user-workload-<%= cb.prometheusPodNum %>" status becomes :running

    When I run the :get client command with:
      | resource | all                                |
      | n        | openshift-user-workload-monitoring |
    Then the step should succeed
    And the output should contain:
      | pod/prometheus-operator-                  |
      | pod/prometheus-user-workload-             |
      | service/prometheus-operated               |
      | service/prometheus-operator               |
      | service/prometheus-user-workload          |
      | deployment.apps/prometheus-operator       |
      | replicaset.apps/prometheus-operator       |
      | statefulset.apps/prometheus-user-workload |
    #Create one namespace, create resources in the namespace
    When I run the :new_project client command with:
      | project_name | ocp-25925-proj |
    Then the step should succeed
    Given I obtain test data file "monitoring/prometheus-example-app.yaml"
    When I run the :apply client command with:
      | f         | prometheus-example-app.yaml |
      | overwrite | true                        |
    Then the step should succeed
    When I run the :get client command with:
      | resource | pod            |
      | n        | ocp-25925-proj |
    Then the step should succeed
    Then the output should match 1 times:
      | prometheus |
    And the output should not contain:
      | alertmanager |

    When I use the "openshift-monitoring" project
    And evaluation of `route('thanos-querier').spec.host` is stored in the :thanos_querier_route clipboard
    # get sa/prometheus-k8s token
    And evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    #Check thanos querier from svc to wait for some time
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/query?query=version |
    Then the step should succeed
    And the output should contain:
      | prometheus-example-app |
      | ocp-25925-proj         |
    """

    When I run the :delete client command with:
      | object_type       | configmap                 |
      | object_name_or_id | cluster-monitoring-config |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | all                                |
      | n        | openshift-user-workload-monitoring |
    Then the step should succeed
    And the output should contain:
      | No resources found |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-32058
  @admin
  Scenario: only allow 32 hexadecimal digits for the avatar hash
    Given the master version >= "4.4"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project

    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard
    And evaluation of `route('grafana').spec.host` is stored in the :grafana_route clipboard

    When I perform the HTTP request:
      """
      :url: https://<%= cb.grafana_route %>/avatar/%0a
      :method: get
      :headers:
         :Authorization: Bearer <%= cb.sa_token %>
      """
    Then the step should fail
    And the output should contain:
      | Avatar not found |

  # @author hongyli@redhat.com
  # @case_id OCP-31989
  @admin
  Scenario: Export Thanos Querier metrics and alerts
    Given the master version >= "4.6"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    #Check thanos-querier servicemonitor/prometheusrules
    Given I check that the "thanos-querier" service_monitor exists
    And I check that the "thanos-querier" prometheusrule exists
    #check thanos-querier endpoints scheme
    When I run the :get client command with:
      | resource      | ServiceMonitor |
      | resource_name | thanos-querier |
      | o             | yaml           |
    Then the step should succeed
    Then the expression should be true> YAML.load(@result[:stdout])["spec"]["endpoints"][0]["scheme"] == "https"
    #curl the thanos-querier target
    When evaluation of `endpoints('thanos-querier').subsets.first.addresses.first.ip.to_s` is stored in the :thanosquery_endpoint_ip clipboard
    And evaluation of `cb.thanosquery_endpoint_ip + ':9091'` is stored in the :thanosquery_endpoint clipboard
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                   |
      | pod              | prometheus-k8s-0                                       |
      | c                | prometheus                                             |
      | oc_opts_end      |                                                        |
      | exec_command     | sh                                                     |
      | exec_command_arg | -c                                                     |
      | exec_command_arg | curl -k https://<%= cb.thanosquery_endpoint %>/metrics |
    Then the step should succeed
    And the output should contain:
      | thanos_status |

  # @author hongyli@redhat.com
  # @case_id OCP-32324
  @admin
  @destructive
  Scenario: Replace atomic roll out of gRPC TLS secrets with an overlapping scheme
    Given the master version >= "4.6"
    And the first user is cluster-admin

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed
    #reset content of secret
    When I run the :delete client command with:
      | object_type       | secret               |
      | object_name_or_id | grpc-tls             |
      | n                 | openshift-monitoring |
    Then the step should succeed

    #Check resources are created under openshift-user-workload-monitoring namespaces
    When evaluation of `infrastructure("cluster").infra_topology=="SingleReplica"?"0":"1"` is stored in the :prometheusPodNum clipboard
    Given I use the "openshift-user-workload-monitoring" project
    When the pod named "prometheus-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    And the pod named "thanos-ruler-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    And I wait up to 360 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | all                                |
      | n        | openshift-user-workload-monitoring |
    Then the step should succeed
    And the output should contain:
      | pod/prometheus-operator-                  |
      | pod/prometheus-user-workload-             |
    """

    #Create one namespace, create resources in the namespace
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "monitoring/prometheus-example-app-grpc.yaml"
    When I run the :apply client command with:
      | f         | prometheus-example-app-grpc.yaml |
      | overwrite | true                             |
    Then the step should succeed
    When I run the :get client command with:
      | resource | pod                 |
      | n        | <%= cb.proj_name %> |
    Then the step should succeed
    Then the output should match 1 times:
      | prometheus-example-app |

    When I use the "openshift-monitoring" project
    # get sa/prometheus-k8s token
    And evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    #trigger grpc-tls rotation by adding annotation
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | secret               |
      | resource_name | grpc-tls             |
      | n             | openshift-monitoring |
      | o             | yaml                 |
    Then the step should succeed
    """
    And I save the output to file> grpc-tls.yaml

    When evaluation of `"metadata:\n  annotations:\n    monitoring.openshift.io/grpc-tls-forced-rotate: \"true\""` is stored in the :str_annotaion clipboard
    And I replace lines in "grpc-tls.yaml":
      | metadata: | <%= cb.str_annotaion %> |
    When I run the :apply client command with:
      | f         | grpc-tls.yaml |
      | overwrite | true          |
    Then the step should succeed

    #check thanos querier can access prometheus in stack
    And I wait up to 300 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                 |
      | pod              | alertmanager-main-0                                                                                                                  |
      | c                | alertmanager                                                                                                                         |
      | oc_opts_end      |                                                                                                                                      |
      | exec_command     | sh                                                                                                                                   |
      | exec_command_arg | -c                                                                                                                                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/query?query=ALERTS |
    Then the step should succeed
    And the output should contain:
      | Watchdog |
    """
    #check thanos querier can access prometheus in UWM
    And I wait up to 360 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                  |
      | pod              | alertmanager-main-0                                                                                                                   |
      | c                | alertmanager                                                                                                                          |
      | oc_opts_end      |                                                                                                                                       |
      | exec_command     | sh                                                                                                                                    |
      | exec_command_arg | -c                                                                                                                                    |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/query?query=version |
    Then the step should succeed
    And the output should contain:
      | prometheus-example-app |
      | <%= cb.proj_name %>    |
    """
    #check thanos querier can access thanos ruler
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                    |
      | pod              | alertmanager-main-0                                                                                                     |
      | c                | alertmanager                                                                                                            |
      | oc_opts_end      |                                                                                                                         |
      | exec_command     | sh                                                                                                                      |
      | exec_command_arg | -c                                                                                                                      |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/rules |
    Then the step should succeed
    And the output should contain:
      | VersionAlert |
    """
    #check annotatin is deleted after rotation
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | secret               |
      | resource_name | grpc-tls             |
      | n             | openshift-monitoring |
    Then the step should succeed
    Then the output should not contain:
      | monitoring.openshift.io/grpc-tls-forced-rotate: "true" |
    """
    #check correct thanos exists
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | secret               |
      | n        | openshift-monitoring |
    Then the step should succeed
    Then the output should match 1 times:
      | prometheus-k8s-grpc-tls |
      | thanos-querier-grpc     |
    When I run the :get client command with:
      | resource | secret                             |
      | n        | openshift-user-workload-monitoring |
    Then the step should succeed
    Then the output should match 1 times:
      | prometheus-user-workload-grpc-tls |
      | thanos-ruler-grpc-tls             |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-33446
  @admin
  Scenario: Node CPU stats should be accurate
    Given the master version >= "4.3"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    And evaluation of `route('prometheus-k8s').spec.host` is stored in the :prom_route clipboard
    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    Given I store the ready and schedulable workers in the :nodes clipboard
    #query an metric
    When I perform the HTTP request:
    """
    :url: https://<%= cb.prom_route %>/api/v1/query?query=100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle",instance="<%= cb.nodes[0].name %>"}[30s])) * 100)
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    When evaluation of `@result[:parsed]["data"]["result"][0]["value"][1]` is stored in the :metric_cpu_usage clipboard

    When I run the :oadm_top_node admin command with:
      | node_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s+/)}[1][2].chop` is stored in the :top_cpu_usage clipboard

    And evaluation of `cb.top_cpu_usage.to_f-cb.metric_cpu_usage.to_f` is stored in the :metric_cpu_usage_diff clipboard
    Then the expression should be true> cb.metric_cpu_usage_diff <= 9 && cb.metric_cpu_usage_diff >= -9

  # @author hongyli@redhat.com
  # @case_id OCP-33244
  @admin
  @flaky
  Scenario: [BZ 1846805] kubelet_running_pod_count shouldn't take into account completed pods
    Given the master version >= "4.6"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    And evaluation of `route('prometheus-k8s').spec.host` is stored in the :prom_route clipboard
    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard
    When I run the :get admin command with:
      | resource       | pod                                             |
      | all_namespaces | true                                            |
      | template       | {{range .items}}{{.status.phase}}{{";"}}{{end}} |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/;/)` is stored in the :output_pods clipboard
    And evaluation of `cb.output_pods.map{|n| n.match(/.*Running.*/)}.compact!.map{|n| n.to_a}.length` is stored in the :running_pods clipboard
    #query an metric
    When I perform the HTTP request:
    """
    :url: https://<%= cb.prom_route %>/api/v1/query?query=kubelet_running_pods
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And evaluation of `@result[:parsed]["data"]["result"].map{|n| n["value"][1].to_i}.sum` is stored in the :metric_running_pods clipboard
    Then the expression should be true> cb.running_pods == cb.metric_running_pods

  # @author hongyli@redhat.com
  # @case_id OCP-33141
  @admin
  @destructive
  Scenario: Apply limits of ingested samples
    Given the master version >= "4.6"
    And I switch to cluster admin pseudo user
    Given admin ensures "user-workload-monitoring-config" configmap is deleted from the "openshift-user-workload-monitoring" project after scenario
    And admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed

    #set enforcedSampleLimit
    Given I obtain test data file "monitoring/config_map_user-workload-monitoring-config.yaml"
    When I run the :apply client command with:
      | f         | config_map_user-workload-monitoring-config.yaml |
      | overwrite | true                                            |
    Then the step should succeed

    Given I use the "openshift-user-workload-monitoring" project
    And I wait for the "user-workload" prometheus to appear up to 120 seconds
    And I wait up to 120 seconds for the steps to pass:
    """
    Then the expression should be true> prometheus.enforced_sample_limit(cached: false) == 1
    """

  # @case_id OCP-32623
  @admin
  @destructive
  Scenario: expose thanos-querier rules endpoint
    Given the master version >= "4.6"
    And the first user is cluster-admin

    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    Given I use the "openshift-monitoring" project
    And evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                    |
      | pod              | alertmanager-main-0                                                                                                     |
      | c                | alertmanager                                                                                                            |
      | oc_opts_end      |                                                                                                                         |
      | exec_command     | sh                                                                                                                      |
      | exec_command_arg | -c                                                                                                                      |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/rules |
    Then the step should succeed
    And the output should contain:
      | ThanosQueryRangeLatencyHigh |

    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed

    #Create one project and prometheus rules under it
    Given I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "monitoring/prometheus_rules.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules.yaml |
      | overwrite | true                  |
    Then the step should succeed

    When I run the :oadm_policy_add_role_to_user admin command with:
      | role_name | monitoring-rules-view              |
      | user_name | <%= user(1, switch: false).name %> |
      | n         | <%= cb.proj_name %>                |
    Then the step should succeed

    Given I switch to the second user
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                               |
      | pod              | prometheus-k8s-0                                                                                                                                                   |
      | c                | prometheus                                                                                                                                                         |
      | oc_opts_end      |                                                                                                                                                                    |
      | exec_command     | sh                                                                                                                                                                 |
      | exec_command_arg | -c                                                                                                                                                                 |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" https://thanos-querier.openshift-monitoring.svc:9093/api/v1/rules?namespace=<%= cb.proj_name %> |
    Then the step should succeed
    And the output should contain:
      | requests_total |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-29837
  @admin
  @destructive
  Scenario: Implement and deploy monitoring-edit role
    Given the master version >= "4.5"
    And the first user is cluster-admin

    Given I check that the "monitoring-edit" cluster_role exists

    #Create one project with PrometheusRule/ServiceMonitor/PodMonitor
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :proj_name clipboard

    Given I obtain test data file "monitoring/pod_servicemonitor_rule-ocp-29837.yaml"
    When I run the :apply client command with:
      | f         | pod_servicemonitor_rule-ocp-29837.yaml |
      | overwrite | true                                   |
    Then the step should succeed

    When I run the :oadm_policy_add_role_to_user admin command with:
      | role_name | monitoring-edit                    |
      | user_name | <%= user(1, switch: false).name %> |
      | n         | <%= cb.proj_name %>                |
    Then the step should succeed

    Given I switch to the second user
    When I run the :get client command with:
      | resource       | PrometheusRule |
      | all_namespaces | true           |
    Then the output should contain:
      | Error from server (Forbidden) |

    When I run the :get client command with:
      | resource | PrometheusRule      |
      | n        | <%= cb.proj_name %> |
    Then the output should contain:
      | story-rules |

    And I obtain test data file "monitoring/pod_servicemonitor_rule-ocp-29837_new.yaml"
    Given I replace lines in "pod_servicemonitor_rule-ocp-29837_new.yaml":
      | replaceme-proj | <%= cb.proj_name %> |
    When I run the :apply client command with:
      | f         | pod_servicemonitor_rule-ocp-29837_new.yaml |
      | overwrite | true                                       |
    Then the step should succeed

    When I run the :get client command with:
      | resource | PrometheusRule      |
      | n        | <%= cb.proj_name %> |
    Then the output should contain:
      | story-rules |
      | drill.rules |
    When I run the :get client command with:
      | resource | ServiceMonitor      |
      | n        | <%= cb.proj_name %> |
    Then the output should contain:
      | new-servicemonitor         |
      | prometheus-example-monitor |
    When I run the :get client command with:
      | resource | PodMonitor          |
      | n        | <%= cb.proj_name %> |
    Then the output should contain:
      | example        |
      | new-podmonitor |

    When I run the :get client command with:
      | resource      | PrometheusRule      |
      | resource_name | drill.rules         |
      | n             | <%= cb.proj_name %> |
      | o             | yaml                |
    Then the step should succeed
    And I save the output to file> drill-rules-ocp-29837.yaml
    When I run the :apply client command with:
      | f         | drill-rules-ocp-29837.yaml |
      | overwrite | true                       |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type       | PrometheusRule      |
      | object_name_or_id | drill.rules         |
      | n                 | <%= cb.proj_name %> |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | ServiceMonitor      |
      | object_name_or_id | new-servicemonitor  |
      | n                 | <%= cb.proj_name %> |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | PodMonitor          |
      | object_name_or_id | new-podmonitor      |
      | n                 | <%= cb.proj_name %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource | PrometheusRule      |
      | n        | <%= cb.proj_name %> |
    Then the output should not contain:
      | drill.rules |
    When I run the :get client command with:
      | resource | ServiceMonitor      |
      | n        | <%= cb.proj_name %> |
    Then the output should not contain:
      | new-servicemonitor         |
    When I run the :get client command with:
      | resource | PodMonitor          |
      | n        | <%= cb.proj_name %> |
    Then the output should not contain:
      | new-podmonitor |

  # @author hongyli@redhat.com
  # @case_id OCP-33059
  @admin
  Scenario: Manage CRDs independently from prometheus-operator in CMO
    Given the master version >= "4.6"
    And I switch to cluster admin pseudo user
    # oc get ClusterRole/prometheus-operator -oyaml
    When I run the :get client command with:
      | resource      | ClusterRole         |
      | resource_name | prometheus-operator |
      | o             | yaml                |
    Then the step should succeed
    And the output should not contain:
      | apiextensions.k8s.io   |
      | .monitoring.coreos.com |

  # @author hongyli@redhat.com
  # @case_id OCP-33426
  @admin
  Scenario: Tighten permissions related to CRD create/update
    #<=4.5
    Given the master version >= "4.3"
    # oc get ClusterRole/prometheus-operator -oyaml
    When I run the :get admin command with:
      | resource      | ClusterRole         |
      | resource_name | prometheus-operator |
      | o             | yaml                |
    Then the step should succeed
    And the output should contain:
      | customresourcedefinitions             |
      | alertmanagers.monitoring.coreos.com   |
      | podmonitors.monitoring.coreos.com     |
      | prometheuses.monitoring.coreos.com    |
      | prometheusrules.monitoring.coreos.com |
      | servicemonitors.monitoring.coreos.com |

  # @author hongyli@redhat.com
  # @case_id OCP-31684
  @admin
  Scenario: Add validation webhook for prometheus rules
    Given the master version >= "4.6"
    And I switch to cluster admin pseudo user
    And admin ensures "ocp-31684-proj" project is deleted after scenario
    Given I check that the "prometheusrules.openshift.io" validating_webhook_configuration exists

    When I run the :new_project client command with:
      | project_name | ocp-31684-proj |
    Then the step should succeed
    Given I obtain test data file "monitoring/prometheus_rule_invalid.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rule_invalid.yaml |
      | overwrite | true                         |
    Then the step should fail
    And the output should contain:
      | The PrometheusRule "story-rules" is invalid: spec.groups.rules.expr: Required value |
    # oc -n ocp-31684-proj get PrometheusRule story-rules
    And the prometheusrules named "story-rules" does not exist in the "ocp-31684-proj" project

  # @author hongyli@redhat.com
  # @case_id OCP-32216
  @admin
  @destructive
  Scenario: Allow setting the log level for Prometheus, Prometheus Operator and Thanos Ruler
    Given the master version >= "4.6"
    And I switch to cluster admin pseudo user
    Given admin ensures "user-workload-monitoring-config" configmap is deleted from the "openshift-user-workload-monitoring" project after scenario
    And admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed

    Given I use the "openshift-user-workload-monitoring" project
    And I wait for the "prometheus-user-workload-0" pod to appear up to 180 seconds
    And I wait for the "prometheus-user-workload" service to appear up to 120 seconds
    And I wait for the "thanos-ruler" route to appear up to 180 seconds
    And I wait for the "user-workload" prometheus to appear up to 120 seconds
    And I wait for the "user-workload" thanos_ruler to appear up to 120 seconds

    #set log level
    Given I obtain test data file "monitoring/config_map_user-workload-monitoring-config.yaml"
    When I run the :apply client command with:
      | f         | config_map_user-workload-monitoring-config.yaml |
      | overwrite | true                                            |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    Then the expression should be true> thanos_ruler("user-workload").log_level(cached: false) == "debug"
    And the expression should be true> prometheus("user-workload").log_level(cached: false) == "warn"
    And the expression should be true> deployment("prometheus-operator").containers_spec(cached: false).first.args.include?("--log-level=error")
    """

  # @author hongyli@redhat.com
  # @case_id OCP-29824
  @admin
  @destructive
  Scenario: Implement and deploy monitoring-rules-edit role
    Given the master version >= "4.5"
    And the first user is cluster-admin

    Given I check that the "monitoring-rules-edit" cluster_role exists

    #Create one project with PrometheusRule
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "monitoring/prometheus_rules.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules.yaml |
      | overwrite | true                  |
    Then the step should succeed

    When I run the :oadm_policy_add_role_to_user admin command with:
      | role_name | monitoring-rules-edit              |
      | user_name | <%= user(1, switch: false).name %> |
      | n         | <%= cb.proj_name %>                |
    Then the step should succeed

    Given I switch to the second user
    When I run the :get client command with:
      | resource       | PrometheusRule |
      | all_namespaces | true           |
    Then the output should contain:
      | Error from server (Forbidden) |

    When I run the :get client command with:
      | resource | PrometheusRule      |
      | n        | <%= cb.proj_name %> |
    Then the output should contain:
      | story-rules |

    And I obtain test data file "monitoring/prometheus_rules-watchdog.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-watchdog.yaml |
      | overwrite | true                           |
      | n         | <%= cb.proj_name %>            |
    Then the step should succeed

    When I run the :get client command with:
      | resource | PrometheusRule      |
      | n        | <%= cb.proj_name %> |
    Then the output should contain:
      | watchdog.rules |

    When I run the :delete client command with:
      | object_type       | PrometheusRule      |
      | object_name_or_id | watchdog.rules      |
      | n                 | <%= cb.proj_name %> |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-29823
  @admin
  @destructive
  Scenario: Implement and deploy monitoring-rules-view role
    Given the master version >= "4.5"
    And the first user is cluster-admin

    When I run the :get client command with:
      | resource | clusterrole |
    Then the output should contain:
      | monitoring-rules-view |

    #Create one project with PrometheusRule
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed
    Given I obtain test data file "monitoring/prometheus_rules.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules.yaml |
      | overwrite | true                  |
    Then the step should succeed

    When I run the :oadm_policy_add_role_to_user admin command with:
      | role_name | monitoring-rules-view              |
      | user_name | <%= user(1, switch: false).name %> |
      | n         | <%= cb.proj_name %>                |
    Then the step should succeed

    Given I switch to the second user
    When I run the :get client command with:
      | resource       | PrometheusRule |
      | all_namespaces | true           |
    Then the output should contain:
      | Error from server (Forbidden) |

    When I run the :get client command with:
      | resource | PrometheusRule      |
      | n        | <%= cb.proj_name %> |
    Then the output should contain:
      | story-rules |

    When I run the :delete client command with:
      | object_type       | PrometheusRule      |
      | object_name_or_id | story-rules         |
      | n                 | <%= cb.proj_name %> |
    Then the output should contain:
      | Error from server (Forbidden) |

  # @author hongyli@redhat.com
  # @case_id OCP-35061
  @admin
  @destructive
  Scenario:  Disable grafana telemetry
    Given the master version >= "4.5"
    Given the first user is cluster-admin

    Given I use the "openshift-monitoring" project
    And a pod becomes ready with labels:
      | app=grafana |
    When I run the :exec admin command with:
      | n                | openshift-monitoring         |
      | pod              | <%= pod.name %>              |
      | c                | grafana                      |
      | oc_opts_end      |                              |
      | exec_command     | sh                           |
      | exec_command_arg | -c                           |
      | exec_command_arg | cat /etc/grafana/grafana.ini |
    Then the step should succeed
    And the output should contain:
      | reporting_enabled = false |

  # @author hongyli@redhat.com
  # @case_id OCP-21874
  @admin
  @destructive
  Scenario: custom metrics API is usable
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    Given I ensure "prometheus-adapter" deployment is deleted from the "default" project after scenario
    And I ensure "adapter-config" configmap is deleted from the "default" project after scenario
    And I ensure "prometheus-adapter" service is deleted from the "default" project after scenario
    And I ensure "v1beta1.custom.metrics.k8s.io" apiservice is deleted after scenario

    Given I obtain test data file "monitoring/custome_metric-deploy.yaml"
    When I run the :apply client command with:
      | f         | custome_metric-deploy.yaml |
      | overwrite | true                       |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | --raw=/apis/custom.metrics.k8s.io/v1beta1 |
    Then the output should contain:
      | "groupVersion":"custom.metrics.k8s.io/v1beta1" |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-26042
  @admin
  @destructive
  Scenario: Account for multi tenant clusters by adding enforcedNamespaceLabel
    #case only apply to 4.3 and 4.4
    Given the master version >= "4.3"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                           |
    Then the step should succeed
    #Check enforcedNamespaceLabel
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | prometheus                         |
      | resource_name | user-workload                      |
      | o             | yaml                               |
      | n             | openshift-user-workload-monitoring |
    Then the output should contain:
      | enforcedNamespaceLabel: namespace |
    """
    #create project and deploy pod
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed

    Given I obtain test data file "monitoring/prometheus_rules_OCP-26042.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules_OCP-26042.yaml |
      | overwrite | true                            |
    Then the step should succeed

    Given I use the "openshift-user-workload-monitoring" project
    And evaluation of `secret(service_account('prometheus-user-workload').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-user-workload-monitoring                                                              |
      | pod              | prometheus-user-workload-0                                                                      |
      | c                | prometheus                                                                                      |
      | oc_opts_end      |                                                                                                 |
      | exec_command     | cat                                                                                             |
      | exec_command_arg | /etc/prometheus/rules/prometheus-user-workload-rulefiles-0/<%= cb.proj_name %>-story-rules.yaml |
    Then the step should succeed
    And the output should contain:
      | CCOTargetNamespaceMissing |
    """

    # query Watchdog alerts
    And I wait up to 240 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://alertmanager-main.openshift-monitoring.svc:9094/api/v2/alerts?filter={alertname="Watchdog"} |

    Then the step should succeed
    And the output should contain:
      | <%= cb.proj_name %> |
    """
    #Check thanos querier from svc to wait for some time
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | alertmanager-main-0  |
      | c                | alertmanager         |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/query?query=ALERTS%7Balertname%3D%22Watchdog%22%7D |
    Then the step should succeed
    And the output should contain:
      | <%= cb.proj_name %> |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-26063
  @admin
  @destructive
  Scenario: Add security / multi-tenancy to the Thanos querier API
    #<=4.6
    Given the master version >= "4.3"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                           |
    Then the step should succeed
    Given I use the "openshift-user-workload-monitoring" project
    And I wait up to 300 seconds for the steps to pass:
    """
    When the pod named "prometheus-user-workload-1" status becomes :running
    And the pod named "thanos-ruler-user-workload-1" status becomes :running
    """
    #create project and deploy pod
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed

    Given I obtain test data file "monitoring/prometheus-example-app-record.yaml"
    When I run the :apply client command with:
      | f         | prometheus-example-app-record.yaml |
      | overwrite | true                               |
    Then the step should succeed

    Given I switch to the second user

    #assign view access
    When I run the :oadm_policy_add_role_to_user admin command with:
      | role_name | view                               |
      | user_name | <%= user(1, switch: false).name %> |
      | n         | <%= cb.proj_name %>                |
    Then the step should succeed
    #with view access
    And I wait up to 240 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                                               |
      | pod              | prometheus-k8s-0                                                                                                                                                                   |
      | c                | prometheus                                                                                                                                                                         |
      | oc_opts_end      |                                                                                                                                                                                    |
      | exec_command     | sh                                                                                                                                                                                 |
      | exec_command_arg | -c                                                                                                                                                                                 |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" 'https://thanos-querier.openshift-monitoring.svc:9092/api/v1/query?query=version&namespace=<%= cb.proj_name %>' |
    Then the step should succeed
    And the output should contain:
      | prometheus-example-app |
    """
    #without namespace
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                 |
      | pod              | prometheus-k8s-0                                                                                                                                     |
      | c                | prometheus                                                                                                                                           |
      | oc_opts_end      |                                                                                                                                                      |
      | exec_command     | sh                                                                                                                                                   |
      | exec_command_arg | -c                                                                                                                                                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" 'https://thanos-querier.openshift-monitoring.svc:9092/api/v1/query?query=version' |
    Then the step should succeed
    And the output should contain:
      | Bad Request. The request or configuration is malformed |
    #with wrong namespace
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                               |
      | pod              | prometheus-k8s-0                                                                                                                                                   |
      | c                | prometheus                                                                                                                                                         |
      | oc_opts_end      |                                                                                                                                                                    |
      | exec_command     | sh                                                                                                                                                                 |
      | exec_command_arg | -c                                                                                                                                                                 |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" 'https://thanos-querier.openshift-monitoring.svc:9092/api/v1/query?query=version&namespace=ns1' |
    Then the step should succeed
    And the output should contain:
      | Forbidden |

  # @author hongyli@redhat.com
  # @case_id OCP-37299
  @admin
  @destructive
  Scenario: 4.7 and above-Add security / multi-tenancy to the Thanos querier API
    Given the master version >= "4.7"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed
    When evaluation of `infrastructure("cluster").infra_topology=="SingleReplica"?"0":"1"` is stored in the :prometheusPodNum clipboard
    Given I use the "openshift-user-workload-monitoring" project
    When the pod named "prometheus-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    And the pod named "thanos-ruler-user-workload-<%= cb.prometheusPodNum %>" status becomes :running

    #create project and deploy pod
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed

    Given I obtain test data file "monitoring/prometheus-example-app-record.yaml"
    When I run the :apply client command with:
      | f         | prometheus-example-app-record.yaml |
      | overwrite | true                               |
    Then the step should succeed

    Given I switch to the second user

    #assign view access
    When I run the :oadm_policy_add_role_to_user admin command with:
      | role_name | view                               |
      | user_name | <%= user(1, switch: false).name %> |
      | n         | <%= cb.proj_name %>                |
    Then the step should succeed
    #with view access
    And I wait up to 240 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                                               |
      | pod              | prometheus-k8s-0                                                                                                                                                                   |
      | c                | prometheus                                                                                                                                                                         |
      | oc_opts_end      |                                                                                                                                                                                    |
      | exec_command     | sh                                                                                                                                                                                 |
      | exec_command_arg | -c                                                                                                                                                                                 |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" 'https://thanos-querier.openshift-monitoring.svc:9092/api/v1/query?query=version&namespace=<%= cb.proj_name %>' |
    Then the step should succeed
    And the output should contain:
      | prometheus-example-app |
    """
    #without namespace
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                 |
      | pod              | prometheus-k8s-0                                                                                                                                     |
      | c                | prometheus                                                                                                                                           |
      | oc_opts_end      |                                                                                                                                                      |
      | exec_command     | sh                                                                                                                                                   |
      | exec_command_arg | -c                                                                                                                                                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" 'https://thanos-querier.openshift-monitoring.svc:9092/api/v1/query?query=version' |
    Then the step should succeed
    And the output should contain:
      | Bad Request. The request or configuration is malformed |
    #with wrong namespace
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                               |
      | pod              | prometheus-k8s-0                                                                                                                                                   |
      | c                | prometheus                                                                                                                                                         |
      | oc_opts_end      |                                                                                                                                                                    |
      | exec_command     | sh                                                                                                                                                                 |
      | exec_command_arg | -c                                                                                                                                                                 |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" 'https://thanos-querier.openshift-monitoring.svc:9092/api/v1/query?query=version&namespace=ns1' |
    Then the step should succeed
    And the output should contain:
      | Forbidden |

  # @author hongyli@redhat.com
  # @case_id OCP-25864
  @admin
  @destructive
  Scenario: Configure deny list for all openshift-* namespaces
    #<=4.6
    Given the master version >= "4.3"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                           |
    Then the step should succeed

    Given I use the "openshift-user-workload-monitoring" project
    And I wait up to 300 seconds for the steps to pass:
    """
    When the pod named "prometheus-user-workload-1" status becomes :running
    And the pod named "thanos-ruler-user-workload-1" status becomes :running
    """
    And evaluation of `deployment('prometheus-operator').container_spec(name: 'prometheus-operator').args.map{|n| n[/deny-namespaces=(.*)/]}.compact![0].split('=')[1].split(',')` is stored in the :deny_namespaces clipboard

    When I run the :get client command with:
      | resource | ns |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)openshift(.*)/]}.compact!` is stored in the :openshift_namespaces clipboard

    When I repeat the following steps for each :deny_namespace in cb.deny_namespaces:
    """
    When I run the :get client command with:
      | resource      | ns                   |
      | resource_name | #{cb.deny_namespace} |
      | o             | yaml                 |
    Then the step should succeed
    Then the output should contain:
      | openshift.io/cluster-monitoring: "true" |
    """
    And evaluation of `cb.openshift_namespaces-cb.deny_namespaces` is stored in the :unmonitoring_namespaces clipboard
    When I repeat the following steps for each :unmonitoring_namespace in cb.unmonitoring_namespaces:
    """
    When I run the :get client command with:
      | resource      | ns                           |
      | resource_name | #{cb.unmonitoring_namespace} |
      | o             | yaml                         |
    Then the step should succeed
    Then the output should not contain:
      | openshift.io/cluster-monitoring: "true" |
    """

    #create project and deploy pod
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed

    Given I obtain test data file "monitoring/prometheus-example-app-record.yaml"
    When I run the :apply client command with:
      | f         | prometheus-example-app-record.yaml |
      | overwrite | true                               |
    Then the step should succeed
    #oc -n openshift-user-workload-monitoring exec  -c  prometheus prometheus-user-workload-0 -- cat /etc/prometheus/config_out/prometheus.env.yaml
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-user-workload-monitoring                 |
      | pod              | prometheus-user-workload-0                         |
      | c                | prometheus                                         |
      | oc_opts_end      |                                                    |
      | exec_command     | sh                                                 |
      | exec_command_arg | -c                                                 |
      | exec_command_arg | cat /etc/prometheus/config_out/prometheus.env.yaml |
    Then the step should succeed
    And the output should contain:
      | prometheus-example-monitor |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-37300
  @admin
  @destructive
  Scenario: 4.7 and above-Configure deny list for all openshift-* namespaces
    Given the master version >= "4.7"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed

    When evaluation of `infrastructure("cluster").infra_topology=="SingleReplica"?"0":"1"` is stored in the :prometheusPodNum clipboard
    Given I use the "openshift-user-workload-monitoring" project
    When the pod named "prometheus-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    And the pod named "thanos-ruler-user-workload-<%= cb.prometheusPodNum %>" status becomes :running

    And evaluation of `deployment('prometheus-operator').container_spec(name: 'prometheus-operator').args.map{|n| n[/deny-namespaces=(.*)/]}.compact![0].split('=')[1].split(',')` is stored in the :deny_namespaces clipboard

    When I run the :get client command with:
      | resource | ns |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)openshift(.*)/]}.compact!` is stored in the :openshift_namespaces clipboard

    When I repeat the following steps for each :deny_namespace in cb.deny_namespaces:
    """
    When I run the :get client command with:
      | resource      | ns                   |
      | resource_name | #{cb.deny_namespace} |
      | o             | yaml                 |
    Then the step should succeed
    Then the output should contain:
      | openshift.io/cluster-monitoring: "true" |
    """
    And evaluation of `cb.openshift_namespaces-cb.deny_namespaces` is stored in the :unmonitoring_namespaces clipboard
    When I repeat the following steps for each :unmonitoring_namespace in cb.unmonitoring_namespaces:
    """
    When I run the :get client command with:
      | resource      | ns                           |
      | resource_name | #{cb.unmonitoring_namespace} |
      | o             | yaml                         |
    Then the step should succeed
    Then the output should not contain:
      | openshift.io/cluster-monitoring: "true" |
    """

    #create project and deploy pod
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed

    Given I obtain test data file "monitoring/prometheus-example-app-record.yaml"
    When I run the :apply client command with:
      | f         | prometheus-example-app-record.yaml |
      | overwrite | true                               |
    Then the step should succeed
    #oc -n openshift-user-workload-monitoring exec  -c  prometheus prometheus-user-workload-0 -- cat /etc/prometheus/config_out/prometheus.env.yaml
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-user-workload-monitoring                 |
      | pod              | prometheus-user-workload-0                         |
      | c                | prometheus                                         |
      | oc_opts_end      |                                                    |
      | exec_command     | sh                                                 |
      | exec_command_arg | -c                                                 |
      | exec_command_arg | cat /etc/prometheus/config_out/prometheus.env.yaml |
    Then the step should succeed
    And the output should contain:
      | prometheus-example-monitor |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-22010
  @admin
  @destructive
  Scenario: Horizontal scale pods on any metrics that the cluster monitoring stack collects
    Given the master version >= "4.1"
    And the first user is cluster-admin

    #create project and deploy pod
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed

    Given I obtain test data file "monitoring/hpa.yaml"
    When I run the :apply client command with:
      | f         | hpa.yaml |
      | overwrite | true     |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=hpa-example |

    Given evaluation of `endpoints('hpa-example').subsets.first.addresses.first.ip.to_s` is stored in the :hpa_service_ip clipboard

    When I run the :exec admin command with:
      | n                | <%= cb.proj_name %>                            |
      | pod              | <%= pod.name %>                                |
      | oc_opts_end      |                                                |
      | exec_command     | sh                                             |
      | exec_command_arg | -c                                             |
      | exec_command_arg | wget -O - http://<%= cb.hpa_service_ip %>:8080 |
    Then the step should succeed
    And the output should contain:
      | Hello, world! |

    When I run the :autoscale client command with:
      | name        | deployment/hpa-example |
      | min         | 1                      |
      | max         | 10                     |
      | cpu-percent | 50                     |
    Then the step should succeed
    And I wait up to 360 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | hpa         |
      | resource_name | hpa-example |
    Then the step should succeed
    And the output should contain:
      | 0%/50% |
    """
    When I run the :run client command with:
      | name             | vegeta                                                                                               |
      | image            | quay.io/openshifttest/vegeta                                                                                    |
      | oc_opt_end       |                                                                                                      |
      | exec_command     | sh                                                                                                   |
      | exec_command_arg | -c                                                                                                   |
      | exec_command_arg | echo 'GET http://<%= cb.hpa_service_ip %>:8080' \|vegeta attack -rate=1000 \|vegeta report -every 5s |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
    Then expression should be true> hpa('hpa-example').current_replicas(cached: false) >= 2
    """

  # @author hongyli@redhat.com
  # @case_id OCP-22526
  @admin
  @destructive
  Scenario: Attach PVs for cluster monitoring
    Given the master version >= "4.1"
    And the first user is cluster-admin
    Given I obtain test data file "monitoring/config_map_pv.yaml"

    When I run the :get client command with:
      | resource | sc |
    Then the step should succeed
    And the output should contain:
      | default |

    When I run the :apply client command with:
      | f         | config_map_pv.yaml |
      | overwrite | true               |
    Then the step should succeed

    And I wait up to 240 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | n          | openshift-monitoring |
      | resource   | pvc                  |
      | no_headers | true                 |
    Then the step should succeed
    And the output should contain:
      | alertmanager   |
      | prometheus-k8s |
    """

    And I wait up to 300 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | n             | openshift-monitoring |
      | resource      | statefulset          |
      | resource_name | alertmanager-main    |
      | o             | yaml                 |
    Then the step should succeed
    And the output should contain:
      | monitorpvc |
      | 1Gi        |
    When I run the :get client command with:
      | n             | openshift-monitoring |
      | resource      | statefulset          |
      | resource_name | prometheus-k8s       |
      | o             | yaml                 |
    Then the step should succeed
    And the output should contain:
      | monitorpvc |
      | 2Gi        |
    """

    # get sa/prometheus-k8s token
    When I run the :serviceaccounts_get_token admin command with:
      | serviceaccount_name | prometheus-k8s       |
      | n                   | openshift-monitoring |
    Then the step should succeed
    And evaluation of `@result[:stdout]` is stored in the :sa_token clipboard
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query?query=kube_pod_spec_volumes_persistentvolumeclaims_info |
    Then the step should succeed
    And the output should contain:
      | monitorpvc |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-25288
  @admin
  @destructive
  Scenario: Allow making tolerations configurable for monitoring components
    Given the master version >= "4.5"
    And the first user is cluster-admin
    And I use the "openshift-monitoring" project
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    Given I store the masters in the :masters clipboard
    When I repeat the following steps for each :master in cb.masters:
    """
    Given the "#{cb.master.name}" node labels are restored after scenario
    Then label "monitoring=deploy" is added to the "#{cb.master.name}" node
    """
    # get monitoring pods
    When I run the :get client command with:
      | n          | openshift-monitoring |
      | resource   | pod                  |
      | no_headers | true                 |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}` is stored in the :monitoring_pods_b clipboard
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)cluster-monitoring-operator(.*)/]}.compact!` is stored in the :cmo_pods_b clipboard
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)node-exporter(.*)/]}.compact!` is stored in the :ne_pods_b clipboard
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)alertmanager-main(.*)/]}.compact!` is stored in the :prom_pods_b clipboard
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)prometheus-k8s(.*)/]}.compact!` is stored in the :alert_pods_b clipboard
    And evaluation of `cb.monitoring_pods_b-cb.cmo_pods_b-cb.ne_pods_b-cb.prom_pods_b-cb.alert_pods_b` is stored in the :other_pods_b clipboard

    Given I obtain test data file "monitoring/toleration.yaml"
    When I run the :apply client command with:
      | f         | toleration.yaml |
      | overwrite | true            |
    Then the step should succeed

    When I repeat the following steps for each :pod_b in cb.other_pods_b:
    """
    Then I wait for the resource "pod" named "#{cb.pod_b}" to disappear within 240 seconds
    And the step should succeed
    """
    # get monitoring pods
    When I run the :get client command with:
      | n          | openshift-monitoring |
      | resource   | pod                  |
      | no_headers | true                 |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}` is stored in the :monitoring_pods_a clipboard
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)cluster-monitoring-operator(.*)/]}.compact!` is stored in the :cmo_pods_a clipboard
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)node-exporter(.*)/]}.compact!` is stored in the :ne_pods_a clipboard
    And evaluation of `cb.monitoring_pods_a-cb.cmo_pods_a-cb.ne_pods_a` is stored in the :other_pods_a clipboard

    And I wait up to 120 seconds for the steps to pass:
    """
    And the expression should be true> pod('prometheus-k8s-0').tolerations(cached: false).to_s.include?"node-role.kubernetes.io/master"
    And the expression should be true> pod('alertmanager-main-0').tolerations(cached: false).to_s.include?"node-role.kubernetes.io/master"
    And the expression should be true> pod('prometheus-k8s-0').nodeselector(cached: false).to_s.include?'{"monitoring"=>"deploy"}'
    And the expression should be true> pod('alertmanager-main-0').nodeselector(cached: false).to_s.include?'{"monitoring"=>"deploy"}'
    """
    When I repeat the following steps for each :pod_a in cb.other_pods_a:
    """
    Given the pod named "#{cb.pod_a}" status becomes :running within 240 seconds
    And the expression should be true> pod('#{cb.pod_a}').tolerations(cached: false).to_s.include?"node-role.kubernetes.io/master"
    And the expression should be true> pod('#{cb.pod_a}').nodeselector(cached: false).to_s.include?'{"monitoring"=>"deploy"}'
    """

  # @author hongyli@redhat.com
  # @case_id OCP-35518
  @admin
  Scenario: Default openshift install should not requests too many CPU resources to install all components
    Given the master version >= "4.3"
    And the first user is cluster-admin
    And I use the "openshift-monitoring" project

    # get monitoring pods
    When I run the :get client command with:
      | n          | openshift-monitoring |
      | resource   | pod                  |
      | no_headers | true                 |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}` is stored in the :monitoring_pods clipboard

    When I repeat the following steps for each :pod_name in cb.monitoring_pods:
    """
    When I check containers cpu request for pod named "#{cb.pod_name}" under limit:
      | prometheus    | 71 |
      | default_limit | 11 |
    Then the step should succeed
    """

  # @author hongyli@redhat.com
  # @case_id OCP-22178
  @admin
  Scenario: Deploy prometheus operator by marketplace
    Given the master version >= "4.1"
    And the first user is cluster-admin

    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :proj_name clipboard

    When I run the :get client command with:
      | n        | openshift-marketplace |
      | resource | packagemanifests      |
    Then the step should succeed
    Then the output should contain:
      | prometheus |

    And I obtain test data file "monitoring/operator_group.yaml"
    Given I replace lines in "operator_group.yaml":
      | replaceme-proj | <%= cb.proj_name %> |
    When I run the :apply client command with:
      | f         | operator_group.yaml |
      | overwrite | true                |
    Then the step should succeed

    And I obtain test data file "monitoring/operator_subscription_prometheus.yaml"
    When I run the :apply client command with:
      | f         | operator_subscription_prometheus.yaml |
      | overwrite | true                                  |
    Then the step should succeed

    Given I wait for the "prometheus" subscriptions to become ready up to 240 seconds
    And evaluation of `subscription("prometheus").current_csv` is stored in the :current_csv clipboard
    Given admin ensures "<%= cb.current_csv %>" clusterserviceversions is deleted after scenario
    And admin wait for the "<%= cb.current_csv %>" clusterserviceversions to become ready up to 300 seconds
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    Then the output should contain:
      | prometheus-operator |
      | Running             |

    And I obtain test data file "monitoring/operator_prometheus_example.yaml"
    Given I replace lines in "operator_prometheus_example.yaml":
      | replaceme-proj | <%= cb.proj_name %> |
    When I run the :apply client command with:
      | f         | operator_prometheus_example.yaml |
      | overwrite | true                             |
    Then the step should succeed

    And I obtain test data file "monitoring/operator_prometheus_rule.yaml"
    When I run the :apply client command with:
      | f         | operator_prometheus_rule.yaml |
      | overwrite | true                          |
    Then the step should succeed

    And I obtain test data file "monitoring/operator_service_monitor.yaml"
    When I run the :apply client command with:
      | f         | operator_service_monitor.yaml |
      | overwrite | true                          |
    Then the step should succeed

    And I obtain test data file "monitoring/operator_pod_monitor.yaml"
    When I run the :apply client command with:
      | f         | operator_pod_monitor.yaml |
      | overwrite | true                      |
    Then the step should succeed

    Given I wait for the "prometheus-example-0" pod to appear up to 120 seconds
    And I check that the "prometheus-example-rules" prometheusrule exists
    And I check that the "example" service_monitor exists
    And I check that the "example" pod_monitor exists

  # @author hongyli@redhat.com
  # @case_id OCP-28081
  @admin
  @destructive
  Scenario: Shouldn't have error if PVCs are created earlier than prometheus
    Given the master version >= "4.4"
    And I switch to cluster admin pseudo user
    And I register clean-up steps:
    """
    When I run the :scale admin command with:
      | resource | deployment                |
      | name     | cluster-version-operator  |
      | replicas | 1                         |
      | n        | openshift-cluster-version |
    Then the step should succeed
    """
    When I run the :get client command with:
      | resource | sc |
    Then the step should succeed
    And the output should contain:
      | default |

    Given I use the "openshift-cluster-version" project
    When I run the :scale client command with:
      | n        | openshift-cluster-version |
      | resource | deploy                    |
      | name     | cluster-version-operator  |
      | replicas | 0                         |
    Then the step should succeed
    And I wait until number of replicas match "0" for deployment "cluster-version-operator"

    Given I use the "openshift-monitoring" project
    When I run the :scale client command with:
      | resource | deploy                      |
      | name     | cluster-monitoring-operator |
      | replicas | 0                           |
    Then the step should succeed
    And I wait until number of replicas match "0" for deployment "cluster-monitoring-operator"

    Given I ensure "k8s" prometheus is deleted
    Given I obtain test data file "monitoring/config_map_pv.yaml"
    When I run the :apply client command with:
      | f         | config_map_pv.yaml |
      | overwrite | true               |
    Then the step should succeed

    When I run the :scale client command with:
      | n        | openshift-cluster-version |
      | resource | deploy                    |
      | name     | cluster-version-operator  |
      | replicas | 1                         |
    Then the step should succeed
    Given I use the "openshift-cluster-version" project
    And I wait until number of replicas match "1" for deployment "cluster-version-operator"

    Given I use the "openshift-monitoring" project
    Given I wait for the "prometheus-k8s-0" pod to appear up to 180 seconds
    # get cmo pod
    Given a pod becomes ready with labels:
      | app=cluster-monitoring-operator |
    Then I run the :logs client command with:
      | resource_name | <%= pod.name %>             |
      | c             | cluster-monitoring-operator |
      | n             | openshift-monitoring        |
    And the output should not contain:
      | sync "openshift-monitoring/cluster-monitoring-config" failed: |
      | running task Updating Prometheus-k8s failed:                  |
      | reconciling Prometheus object failed:                         |
      | creating Prometheus object failed:                            |
      | Prometheus.monitoring.coreos.com "k8s" is invalid:            |

  # @author hongyli@redhat.com
  # @case_id OCP-20428
  @admin
  Scenario: cluster monitoring alertmanager UI check
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    And evaluation of `route('alertmanager-main').spec.host` is stored in the :alert_route clipboard
    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    #check default page is graph and displays correctly
    When I perform the HTTP request:
    """
    :url: https://<%= cb.alert_route %>/
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | Alertmanager |

    #query an alert
    When I perform the HTTP request:
    """
    :url: https://<%= cb.alert_route %>/api/v2/alerts/groups?filter=alertname="Watchdog"&silenced=false&inhibited=false&active=true
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | "alertname":"Watchdog" |

    #check status
    When I perform the HTTP request:
    """
    :url: https://<%= cb.alert_route %>/api/v2/status
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | cluster       |
      | config        |
      | pagerduty_url |

  # @author hongyli@redhat.com
  # @case_id OCP-20456
  @admin
  Scenario: cluster monitoring grafana UI check
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    And evaluation of `route('grafana').spec.host` is stored in the :grafana_route clipboard
    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    #check default page is graph and displays correctly
    When I perform the HTTP request:
    """
    :url: https://<%= cb.grafana_route %>/
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | Grafana |

    #check default dashboard
    When I perform the HTTP request:
    """
    :url: https://<%= cb.grafana_route %>/api/health
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | "database": "ok" |

  # @author hongyli@redhat.com
  # @case_id OCP-35969
  @admin
  @destructive
  Scenario: node-exporter should not have error logs with NFS PV
    Given the master version >= "4.5"
    And the first user is cluster-admin

    Given I register clean-up steps:
    """
    When I run the :delete client command with:
      | object_type       | securitycontextconstraints |
      | object_name_or_id | nfs-provisioner            |
    Then the step should succeed
    """
    And admin ensures "nfs-provisioner-runner" cluster_role is deleted after scenario
    And admin ensures "system:openshift:scc:nfs-provisioner" cluster_role is deleted after scenario
    And admin ensures "run-nfs-provisioner" clusterrolebinding is deleted after scenario

    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :proj_name clipboard

    And admin ensures "nfs-sc" storageclass is deleted after scenario
    And I register clean-up steps:
    """
    When I run the :delete client command with:
      | object_type | pvc                  |
      | all         |                      |
      | n           | openshift-monitoring |
    Then the step should succeed
    """
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    Given I store the ready and schedulable workers in the :nodes clipboard
    When I repeat the following steps for each :node in cb.nodes:
    """
    Given I use the "#{cb.node.name}" node
    Given I run commands on the host:
      | mkdir -p /srv/                       |
      | chcon -Rt svirt_sandbox_file_t /srv/ |
    Then the step should succeed
    """
    Given I use the "<%= cb.proj_name %>" project
    When I run the :apply client command with:
      | f         | https://raw.githubusercontent.com/openshift/external-storage/master/nfs/deploy/kubernetes/deployment.yaml |
      | overwrite | true                                                                                                      |
    Then the step should succeed
    When I run the :apply client command with:
      | f         | https://raw.githubusercontent.com/openshift/external-storage/master/nfs/deploy/kubernetes/scc.yaml |
      | overwrite | true                                                                                               |
    Then the step should succeed

    When I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | nfs-provisioner                                           |
      | user_name | system:serviceaccount:<%= cb.proj_name %>:nfs-provisioner |
    Then the step should succeed

    #Copy from https://raw.githubusercontent.com/openshift/external-storage/master/nfs/deploy/kubernetes/rbac.yaml
    And I obtain test data file "monitoring/nfs_rbac.yaml"
    And I replace lines in "nfs_rbac.yaml":
      | default | <%= cb.proj_name %> |
    When I run the :apply client command with:
      | f         | nfs_rbac.yaml |
      | overwrite | true          |
    Then the step should succeed

    When I run the :get client command with:
      | resource      | deployment      |
      | resource_name | nfs-provisioner |
      | o             | yaml            |
    Then the step should succeed
    And I save the output to file> nfs-prov-deploy.yaml
    And I replace lines in "nfs-prov-deploy.yaml":
      | image: quay.io/kubernetes_incubator/nfs-provisioner:latest | image: quay.io/kubernetes_incubator/nfs-provisioner:v2.2.2 |
    When I run the :apply client command with:
      | f         | nfs-prov-deploy.yaml |
      | overwrite | true                 |
    Then the step should succeed

    Given I obtain test data file "monitoring/nfs_sc.yaml"
    When I run the :apply client command with:
      | f         | nfs_sc.yaml |
      | overwrite | true        |
    Then the step should succeed

    When I run the :get client command with:
      | resource | sc |
    Then the step should succeed
    And the output should contain:
      | nfs-sc |

    Given I obtain test data file "monitoring/nfs_config_map_pv.yaml"
    When I run the :apply client command with:
      | f         | nfs_config_map_pv.yaml |
      | overwrite | true                   |
    Then the step should succeed

    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | n          | openshift-monitoring |
      | resource   | pvc                  |
      | no_headers | true                 |
    Then the step should succeed
    And the output should contain:
      | alertmanager   |
      | prometheus-k8s |
    """
    Given I use the "openshift-monitoring" project
    Given I wait for the "prometheus-k8s-0" pod to appear up to 120 seconds
    And the pod named "prometheus-k8s-0" status becomes :running
    # get node exporter pods
    When I run the :get client command with:
      | resource | pod                  |
      | n        | openshift-monitoring |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)node-exporter(.*)/]}.compact!` is stored in the :ne_pods clipboard

    When I repeat the following steps for each :pod in cb.ne_pods:
    """
    When I run the :logs client command with:
      | resource_name | #{cb.pod}     |
      | c             | node-exporter |
    And the output should not contain:
      | invalid NFS per-operations stats |
    """

  # @author hongyli@redhat.com
  # @case_id OCP-37663
  @admin
  Scenario: Export Thanos Sidecar metrics and alerts
    Given the master version >= "4.7"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed

    When I use the "openshift-monitoring" project
    Then the expression should be true> service_monitor('thanos-sidecar').service_monitor_endpoints_spec.first.scheme == 'https'
    # get thanos sidecar endpoint
    When evaluation of `endpoints('prometheus-k8s-thanos-sidecar').subsets.first.addresses.first.ip.to_s` is stored in the :thanos_sidecar_endpoint_ip clipboard
    And evaluation of `endpoints('prometheus-k8s-thanos-sidecar').subsets.first.ports.first.port.to_s` is stored in the :thanos_sidecar_endpoint_port clipboard
    And evaluation of `cb.thanos_sidecar_endpoint_ip + ':' + cb.thanos_sidecar_endpoint_port` is stored in the :thanos_sidecar_endpoint clipboard

    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard

    When I use the "openshift-user-workload-monitoring" project
    And I wait up to 180 seconds for the steps to pass:
    """
    Then the expression should be true> service_monitor('thanos-sidecar').service_monitor_endpoints_spec.first.scheme == 'https'
    """
    # get umw thanos sidecar endpoint
    And evaluation of `endpoints('prometheus-user-workload-thanos-sidecar').subsets.first.addresses.first.ip.to_s` is stored in the :umw_thanos_sidecar_endpoint_ip clipboard
    And evaluation of `endpoints('prometheus-user-workload-thanos-sidecar').subsets.first.ports.first.port.to_s` is stored in the :umw_thanos_sidecar_endpoint_port clipboard
    And evaluation of `cb.umw_thanos_sidecar_endpoint_ip + ':' + cb.umw_thanos_sidecar_endpoint_port` is stored in the :umw_thanos_sidecar_endpoint clipboard

    # Get metrics from cluster-monitoring-operator endpoint and check content
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://<%= cb.thanos_sidecar_endpoint %>/metrics |
    Then the step should succeed
    And the output should contain:
      | thanos_sidecar_prometheus_up |

    # Get metrics from prometheus-operator endpoint and check content
    When I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://<%= cb.umw_thanos_sidecar_endpoint %>/metrics |
    Then the step should succeed
    And the output should contain:
      | thanos_sidecar_prometheus_up |

    When I run the :get client command with:
      | n             | openshift-monitoring       |
      | resource      | configmap                  |
      | resource_name | prometheus-k8s-rulefiles-0 |
      | o             | yaml                       |
    Then the step should succeed
    And the output should contain:
      | ThanosSidecarPrometheusDown |

  # @author hongyli@redhat.com
  # @case_id OCP-38418
  @admin
  @destructive
  Scenario: prometheus-user-workload API allows requests to the metrics endpoint only
    Given the master version >= "4.7"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed
    When evaluation of `infrastructure("cluster").infra_topology=="SingleReplica"?"0":"1"` is stored in the :prometheusPodNum clipboard
    Given I use the "openshift-user-workload-monitoring" project
    When the pod named "prometheus-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    And the pod named "thanos-ruler-user-workload-<%= cb.prometheusPodNum %>" status becomes :running

    #create project and deploy pod
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed

    Given I obtain test data file "monitoring/prometheus-example-app-record.yaml"
    When I run the :apply client command with:
      | f         | prometheus-example-app-record.yaml |
      | overwrite | true                               |
    Then the step should succeed

    Given I switch to the second user
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                      |
      | pod              | prometheus-k8s-0                                                                                                                                          |
      | c                | prometheus                                                                                                                                                |
      | oc_opts_end      |                                                                                                                                                           |
      | exec_command     | sh                                                                                                                                                        |
      | exec_command_arg | -c                                                                                                                                                        |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" 'https://prometheus-user-workload.openshift-user-workload-monitoring.svc:9091/metrics' |
    Then the step should succeed
    And the output should contain:
      | Forbidden |
    """
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                                                                       |
      | pod              | prometheus-k8s-0                                                                                                                                                                                           |
      | c                | prometheus                                                                                                                                                                                                 |
      | oc_opts_end      |                                                                                                                                                                                                            |
      | exec_command     | sh                                                                                                                                                                                                         |
      | exec_command_arg | -c                                                                                                                                                                                                         |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" 'https://prometheus-user-workload.openshift-user-workload-monitoring.svc:9091/api/v1/query?query=version&namespace=<%= cb.proj_name %>' |
    Then the step should succeed
    And the output should contain:
      | 404 page not found |
    """
    #assign metric view access
    Given cluster role "cluster-monitoring-operator" is added to the "second" user
    And I wait up to 240 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                      |
      | pod              | prometheus-k8s-0                                                                                                                                          |
      | c                | prometheus                                                                                                                                                |
      | oc_opts_end      |                                                                                                                                                           |
      | exec_command     | sh                                                                                                                                                        |
      | exec_command_arg | -c                                                                                                                                                        |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" 'https://prometheus-user-workload.openshift-user-workload-monitoring.svc:9091/metrics' |
    Then the step should succeed
    And the output should contain:
      | promhttp_metric_handler_requests_total |
    """
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring                                                                                                                                                                                       |
      | pod              | prometheus-k8s-0                                                                                                                                                                                           |
      | c                | prometheus                                                                                                                                                                                                 |
      | oc_opts_end      |                                                                                                                                                                                                            |
      | exec_command     | sh                                                                                                                                                                                                         |
      | exec_command_arg | -c                                                                                                                                                                                                         |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= user.cached_tokens.first %>" 'https://prometheus-user-workload.openshift-user-workload-monitoring.svc:9091/api/v1/query?query=version&namespace=<%= cb.proj_name %>' |
    Then the step should succeed
    And the output should contain:
      | 404 page not found |
    """

  # @author juzhao@redhat.com
  # @case_id OCP-40029
  @admin
  Scenario: remove Ceph block devices in rules
    Given the master version >= "4.6"
    And I switch to cluster admin pseudo user

    Given I run the :get admin command with:
      | resource      | configmap                  |
      | resource_name | prometheus-k8s-rulefiles-0 |
      | namespace     | openshift-monitoring       |
      | o             | yaml                       |
    Then the step should succeed
    And the output should not contain:
      | rbd |

  # @author juzhao@redhat.com
  # @case_id OCP-40863
  @admin
  @destructive
  Scenario: set loglevel for prometheusOperator,prometheus and thanosQuerier
    Given the master version >= "4.7"
    And I switch to cluster admin pseudo user
    And admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    #set log level
    Given I obtain test data file "monitoring/loglevel_config.yaml"
    When I run the :apply client command with:
      | f         | loglevel_config.yaml |
      | overwrite | true                 |
    Then the step should succeed

    Given I use the "openshift-monitoring" project
    And I wait up to 180 seconds for the steps to pass:
    """
    Then the expression should be true> deployment("prometheus-operator").containers_spec(cached: false).first.args.include?("--log-level=warn")
    And the expression should be true> prometheus("k8s").log_level(cached: false) == "error"
    And the expression should be true> deployment("thanos-querier").containers_spec(cached: false).first.args.include?("--log.level=debug")
    """

  # @author hongyli@redhat.com
  # @case_id OCP-41205
  @admin
  @destructive
  Scenario: Support Monitoring to run in a single node cluster environment
    Given the master version >= "4.8"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    
    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed
    When evaluation of `infrastructure("cluster").infra_topology=="SingleReplica"?"0":"1"` is stored in the :prometheusPodNum clipboard
    Given I use the "openshift-user-workload-monitoring" project
    When the pod named "prometheus-user-workload-<%= cb.prometheusPodNum %>" status becomes :running
    And the pod named "thanos-ruler-user-workload-<%= cb.prometheusPodNum %>" status becomes :running

    When I check replicas of monitoring components for sno cluster
    Then the step should succeed
