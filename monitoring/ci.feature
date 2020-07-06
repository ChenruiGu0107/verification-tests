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
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)monitoring(.*)/]}.compact!` is stored in the :crds_monitoring clipboard
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
      | overwrite | true |
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
      | overwrite | true |
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
    Given the master version >= "4.5"
    And I switch to cluster admin pseudo user
    And I use the "openshift-monitoring" project
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    Given admin ensures "test-ocp-29748" prometheusrule is deleted from the "openshift-monitoring" project after scenario
    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                                                                                      |
    Then the step should succeed
    #Deploy prometheus rules under user's namespace
    Given I obtain test data file "monitoring/prometheus_rules-OCP-29748.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-OCP-29748.yaml |
      | overwrite | true                                                                                       |
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
      | resource | pod |
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
    Given the master version >= "4.3"
    And I switch to cluster admin pseudo user
    And I use the "openshift-user-workload-monitoring" project
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true |
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
      | overwrite | true |
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
      | overwrite | true |
    Then the step should succeed
    #check retention time
    Then I wait up to 60 seconds for the steps to pass:
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
      | f          | externalLabels.yaml |
      | overwrite  | true |
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
    #check default page is graph and displays correctly
    When I perform the HTTP request:
    """
    :url: https://<%= cb.prom_route %>/
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | Prometheus |
      | Alerts     |
      | Graph      |
      | Help       |

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
    :url: https://<%= cb.prom_route %>/alerts
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
    :url: https://<%= cb.prom_route %>/targets
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.sa_token %>
    """
    Then the step should succeed
    And the output should contain:
      | Endpoint |
      | up)      |

  # @author hongyli@redhat.com
  # @case_id OCP-28957
  @admin
  @destructive
  Scenario: Alerting rules with the same name and different namespaces should not offend each other
    Given the master version >= "4.5"
    And I switch to cluster admin pseudo user
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    And admin ensures "ocp-28957-proj1" project is deleted after scenario
    And admin ensures "ocp-28957-proj2" project is deleted after scenario
    And admin ensures "ocp-28957.rules" prometheusrule is deleted from the "ocp-28957-proj1" project after scenario
    And admin ensures "ocp-28957.rules" prometheusrule is deleted from the "ocp-28957-proj2" project after scenario
    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                                                                                      |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | ocp-28957-proj1 |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | ocp-28957-proj2 |
    Then the step should succeed
    #Deploy prometheus rules under proj1
    Given I obtain test data file "monitoring/prometheus_rules-OCP-28957-proj1.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-OCP-28957-proj1.yaml |
      | overwrite | true                                                                                             |
    Then the step should succeed
    #Deploy prometheus rules under proj2
    Given I obtain test data file "monitoring/prometheus_rules-OCP-28957-proj2.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-OCP-28957-proj2.yaml |
      | overwrite | true                                                                                             |
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
      | ocp-28957-proj1 |
      | ocp-28957-proj2 |
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
      | ocp-28957-proj1 |
      | ocp-28957-proj2 |
  
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
      | alertname="Watchdog" |
      | ocp-28957-proj1      |
      | ocp-28957-proj2      |
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
      | Watchdog        |
      | ocp-28957-proj1 |
      | ocp-28957-proj2 |
      
  # @author hongyli@redhat.com
  # @case_id OCP-28961
  @admin
  @destructive
  Scenario: Deploy ThanosRuler in user-workload-monitoring
    Given the master version >= "4.5"
    And I switch to cluster admin pseudo user
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario
    And admin ensures "ocp-28961-proj" project is deleted after scenario
    And admin ensures "ocp-28961-story-rules" prometheusrule is deleted from the "ocp-28961-proj" project after scenario
    And admin ensures "ocp-28961-example" deployment is deleted from the "ocp-28961-proj" project after scenario
    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                                                                                      |
    Then the step should succeed
    #ThanosRuler related resouces are created
    When I use the "openshift-user-workload-monitoring" project
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | statefulset |
    Then the step should succeed
    And the output should contain:
      | prometheus-user-workload   |
      | thanos-ruler-user-workload |
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
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://prometheus-k8s.openshift-monitoring.svc:9091/rules |
    Then the step should succeed
    And the output should contain:
      | thanos-rule.rules |
    """
    
    #Create one project and prometheus rules under it
    When I run the :new_project client command with:
      | project_name | ocp-28961-proj |
    Then the step should succeed
    Given I obtain test data file "monitoring/prometheus_rules-ocp-28961.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules-ocp-28961.yaml |
      | overwrite | true                                                                                       |
    Then the step should succeed
    Given I obtain test data file "monitoring/pod_wrong_image-ocp-28961.yaml"
    When I run the :apply client command with:
      | f         | pod_wrong_image-ocp-28961.yaml |
      | overwrite | true                                                                                      |
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
    Given the master version >= "4.3"
    And I switch to cluster admin pseudo user
    Given admin ensures "ocp-25925-proj" project is deleted after scenario

    When I run the :get client command with:
      | resource | all                                |
      | n        | openshift-user-workload-monitoring |
    Then the step should succeed
    And the output should contain:
      | No resources found |
    #enable techPreviewUserWorkload
    Given I obtain test data file "monitoring/config_map_enable_techPreviewUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enable_techPreviewUserWorkload.yaml |
      | overwrite | true                                           |
    Then the step should succeed

    #Check resources are created under openshift-user-workload-monitoring namespaces
    And I wait up to 120 seconds for the steps to pass:
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
    """
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
    And I wait up to 120 seconds for the steps to pass:
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
    And evaluation of `endpoints('thanos-querier').subsets.first.ports[1].port.to_s` is stored in the :thanosquery_endpoint_port clipboard
    And evaluation of `cb.thanosquery_endpoint_ip + ':' +cb.thanosquery_endpoint_port` is stored in the :thanosquery_endpoint clipboard
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