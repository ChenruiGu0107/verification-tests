Feature: query browser

  # @author hongyli@redhat.com
  # @case_id OCP-24343
  @admin
  Scenario: navigate to the query browser via the left side OpenShift console menu
    #<=4.6
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed
    #perform example query
    When I run the :click_button_example_query web action
    Then I run the :check_sample_query_area web action
    And the step should succeed
    #clear query
    When I run the :click_clear_query_button web action
    And I run the :click_run_queries_button web action
    When I run the :check_button_example_query web action
    Then the step should succeed
    #check Prometheus UI link
    When I click the following "a" element:
      | text  | Prometheus UI    |
      | class | co-external-link |
    Then the step should succeed

  # @author juzhao@redhat.com
  # @case_id OCP-38879
  @admin
  Scenario: 4.7 and above-navigate to the query browser via the left side OpenShift console menu
    Given the master version >= "4.7"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed
    #perform example query
    When I run the :click_button_example_query web action
    Then I run the :check_sample_query_area web action
    And the step should succeed
    #clear query
    When I run the :click_clear_query_button web action
    And I run the :click_run_queries_button web action
    When I run the :check_button_example_query web action
    Then the step should succeed
    #check Prometheus UI link
    When I click the following "a" element:
      | text  | Platform Prometheus UI |
      | class | co-external-link       |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-28106
  Scenario: Developer query browser feature - common user
    Given the master version >= "4.4"
    Given I open admin console in a browser

    #create project and deploy pod
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed
    When I run the :new_app client command with:
      | app_repo | quay.io/openshifttest/deployment-example |
    Then the step should succeed

    #Go to developer mode, select the project
    When I run the :navigate_to_dev_console web action
    Then the step should succeed
    #Go to monitoring
    When I run the :goto_monitoring web action
    Then the step should succeed
    When I perform the :choose_project_developer_mode web action with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    #check there is tech_preview badge and no prometheus UI
    When I run the :check_tech_preview_badge web action
    Then the step should succeed
    When I click the following "a" element:
      | text | Prometheus UI |
    Then the step should fail
    #click tab metrics and perform metrics query
    When I perform the :click_tab web action with:
      | tab_name | Metrics |
    Then the step should succeed

    #check selected query from dropdown list
    When I run the :click_metrics_query_dropdown web action
    And I perform the :choose_metrics_query web action with:
      | metrics_name | Memory |
    Then the step should succeed
    #same code execute twice to workaround automation no data issue
    When I run the :click_metrics_query_dropdown web action
    And I perform the :choose_metrics_query web action with:
      | metrics_name | Memory |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | deployment-example |
    Then the step should succeed
    #zoom in/out test
    When I perform the :choose_zoom_value web action with:
      | zoom_value | 5m |
    And I perform the :check_zoom_value web action with:
      | zoom_value | 5m |
    Then the step should succeed
    When I perform the :choose_zoom_value web action with:
      | zoom_value | 2d |
    And I perform the :check_zoom_value web action with:
      | zoom_value | 2d |
    Then the step should succeed
    When I run the :click_reset_zoom_button web action
    And I perform the :check_zoom_value web action with:
      | zoom_value | 30m |
    Then the step should succeed
    #check show/hide promql
    When I run the :show_promql_if_exists web action
    And I run the :check_query_input_text_area web action
    Then the step should succeed
    When I run the :hide_promql_if_exists web action
    And I run the :check_query_input_text_area web action
    Then the step should fail

  # @author hongyli@redhat.com
  # @case_id OCP-27830
  @admin
  Scenario: Developer query browser feature - cluster admin
    Given the master version >= "4.4"
    And the first user is cluster-admin
    Given I open admin console in a browser

    #Go to developer mode, select the project
    When I run the :navigate_to_dev_console web action
    Then the step should succeed
    #Go to monitoring
    When I run the :goto_monitoring web action
    Then the step should succeed
    When I perform the :choose_project_developer_mode web action with:
      | project_name | openshift-apiserver |
    Then the step should succeed
    #check there is tech_preview badge and no prometheus UI
    When I run the :check_tech_preview_badge web action
    Then the step should succeed
    When I click the following "a" element:
      | text | Prometheus UI |
    Then the step should fail
    #click tab metrics and perform metrics query
    When I perform the :click_tab web action with:
      | tab_name | Metrics |
    Then the step should succeed

    #check custom query
    When I perform the :perform_cutomer_query web action with:
      | metrics     | pod:container_memory_usage_bytes:sum |
      | press_enter | :enter                               |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | openshift-apiserver |
    Then the step should succeed

    #check selected query from dropdown list
    When I run the :click_metrics_query_dropdown web action
    And I perform the :choose_metrics_query web action with:
      | metrics_name | Filesystem |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | openshift-apiserver |
    Then the step should succeed
    #zoom in/out test
    When I perform the :choose_zoom_value web action with:
      | zoom_value | 2h |
    And I perform the :check_zoom_value web action with:
      | zoom_value | 2h |
    Then the step should succeed
    When I perform the :choose_zoom_value web action with:
      | zoom_value | 1w |
    And I perform the :check_zoom_value web action with:
      | zoom_value | 1w |
    Then the step should succeed
    When I run the :click_reset_zoom_button web action
    And I perform the :check_zoom_value web action with:
      | zoom_value | 30m |
    Then the step should succeed
    #check show/hide promql
    When I run the :show_promql_if_exists web action
    And I run the :check_query_input_text_area web action
    Then the step should succeed
    When I run the :hide_promql_if_exists web action
    And I run the :check_query_input_text_area web action
    Then the step should fail

  # @author hongyli@redhat.com
  # @case_id OCP-24222
  @admin
  Scenario: a list of all available metrics in the drop-down list
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser
    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed

    When I use the "openshift-monitoring" project
    And evaluation of `route('prometheus-k8s').spec.host` is stored in the :prom_route clipboard
    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard
    #check metrics from prometheus
    #https://<prom_route>/api/v1/label/__name__/values
    When I perform the HTTP request:
      """
      :url: https://<%= cb.prom_route %>/api/v1/label/__name__/values
      :method: get
      :headers:
        :Authorization: Bearer <%= cb.sa_token %>
      """
    Then the step should succeed
    And the output should contain:
      | kube_pod_status_scheduled |
      | ALERTS                    |
    #check metrics from ocp conosle
    #check selected query from dropdown list
    When I perform the :perform_metric_query_drop_down_admin web action with:
      | metrics_name | kube_pod_status_scheduled |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | openshift-monitoring/k8s |
    Then the step should succeed
    #check selected query from dropdown list
    When I perform the :perform_metric_query_textarea web action with:
      | metrics_name | ALERTS |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | Watchdog |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-24760
  @admin
  Scenario: [Bug MON-743]Query Browser UI should show the `__name__` column inside the result table
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed
    #search in Query Browser
    When I perform the :perform_metric_query_textarea web action with:
      | metrics | sum({job="node-exporter"}) by (__name__) |
    Then the step should succeed
    When I perform the :check_result_page web action with:
      | table_text | count:up1 |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-24097
  @admin
  Scenario: Single query in metrics query browser
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed
    #check selected query from dropdown list
    When I perform the :perform_metric_query_drop_down_admin web action with:
      | metrics_name | kube_pod_status_scheduled |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | openshift-monitoring/k8s |
    Then the step should succeed
    #check query by filter metrics
    When I perform the :perform_filter_query web action with:
      | metrics | cluster:capacity_cpu_cores:sum |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | openshift-monitoring/k8s |
    Then the step should succeed
    #delete query
    When I run the :perform_query_cog_action_delete_query web action
    Then the step should succeed
    When I run the :check_query_input_text_area_no_value web action
    Then the step should succeed
    When I run the :check_button_example_query web action
    Then the step should succeed
    #verify function
    When I perform the :perform_metric_query_textarea web action with:
      | metrics | irate(node_disk_io_time_seconds_total{job="node-exporter"}[1m]) |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | openshift-monitoring/k8s |
    Then the step should succeed
    #hide/show table
    When I run the :perform_hide_table web action
    Then the step should succeed
    When I perform the :check_metric_query_table_text_not_exist web action with:
      | table_text | openshift-monitoring/k8s |
    Then the step should fail
    When I run the :perform_show_table web action
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | openshift-monitoring/k8s |
    Then the step should succeed
    #disable/enable query
    When I run the :perform_disable_query web action
    Then the step should succeed
    When I perform the :check_metric_query_result_not_exit web action with:
      | table_text | openshift-monitoring/k8s |
    Then the step should fail
    When I run the :check_button_example_query web action
    Then the step should succeed
    When I run the :perform_enable_query web action
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | openshift-monitoring/k8s |
    Then the step should succeed
    #Hide/Show all queries
    When I run the :perform_query_cog_action_hide_all_query web action
    Then the step should succeed
    When I run the :check_all_series_show web action
    Then the step should succeed
    When I run the :perform_query_cog_action_show_all_query web action
    Then the step should succeed
    When I run the :check_all_series_hide web action
    Then the step should succeed
    #zoom in/out test
    When I perform the :choose_zoom_value web action with:
      | zoom_value | 2h |
    And I perform the :check_zoom_value web action with:
      | zoom_value | 2h |
    Then the step should succeed
    When I perform the :choose_zoom_value web action with:
      | zoom_value | 1w |
    And I perform the :check_zoom_value web action with:
      | zoom_value | 1w |
    Then the step should succeed
    When I run the :click_reset_zoom_button web action
    And I perform the :check_zoom_value web action with:
      | zoom_value | 30m |
    Then the step should succeed
    When I perform the :perform_metric_query_textarea web action with:
      | metrics | ALERTS45 |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | No datapoints found |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21263
  @admin
  Scenario: Show correct and same CPU/Memory/Filesystem usage both in prometheus and Grafana UI
    Given the master version >= "4.4"
    And the first user is cluster-admin
    Given I open admin console in a browser
    #Workloads -> Pods
    When I perform the :goto_one_pod_page web action with:
      | project_name  | openshift-monitoring |
      | resource_name | alertmanager-main-0  |
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I perform the :click_pod_chart_link web action with:
      | chart_name | Memory |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | alertmanager-main-0 |
    Then the step should succeed
    When I perform the :goto_one_pod_page web action with:
      | project_name  | openshift-monitoring |
      | resource_name | alertmanager-main-0  |
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I perform the :click_pod_chart_link web action with:
      | chart_name | CPU |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | alertmanager-main-0 |
    Then the step should succeed
    When I perform the :goto_one_pod_page web action with:
      | project_name  | openshift-monitoring |
      | resource_name | alertmanager-main-0  |
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I perform the :click_pod_chart_link web action with:
      | chart_name | Filesystem |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | alertmanager-main-0 |
    Then the step should succeed
    #go to monitoring/dashboards/grafana-dashboard-k8s-resources-pod, Kubernetes/Compute Resources/Pod is selected for DB
    When I run the :goto_monitoring_db_k8s_resource_pod web action
    #choose namespace openshift-monitoring and alertmanager-main-0 is selected
    When I perform the :choose_dropdown_item_text web action with:
      | dropdown_field | namespace            |
      | dropdown_item  | openshift-monitoring |
    Then the step should succeed
    When I perform the :check_data_diplayed_db web action with:
      | data_name   | CPU             |
      | legend_name | config-reloader |
    Then the step should succeed
    When I perform the :check_data_diplayed_db web action with:
      | data_name   | Memory          |
      | legend_name | config-reloader |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-27841
  @admin
  Scenario: Administrator console check for admin user
    Given the master version >= "4.3"
    When the first user is cluster-admin
    And I open admin console in a browser

    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | View alerts        |
      | link_url | /monitoring/alerts |
    When I perform the :click_utilization_graph_link web action with:
      | metric_kind | memory |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | sum(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) |
    Then the step should succeed

    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    #Click on the resource usage value link, then click the link from a random pod
    When I perform the :click_link_from_uitilization_description web action with:
      | metric_kind | Memory               |
      | link_text   | openshift-monitoring |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | openshift-monitoring |
    Then the step should succeed

    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    #Click on the resource usage value link, then click the "View More" link
    When I perform the :click_link_from_uitilization_description web action with:
      | metric_kind | Memory    |
      | link_text   | View more |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | topk(25, sort_desc(sum(avg_over_time(container_memory_working_set_bytes{container="",pod!=""}[5m])) BY (namespace))) |
    Then the step should succeed

    # Node detail page
    Given I select a random node's host
    When I perform the :goto_one_node_page web action with:
      | node_name | <%= node.name %> |
    Then the step should succeed
    When I run the :check_node_detail_page_charts_style web action
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-34901
  Scenario: Administrator console check for common user
    Given the master version >= "4.3"
    Given I open admin console in a browser

    #create project and deploy pod
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed
    When I run the :new_app client command with:
      | app_repo | quay.io/openshifttest/deployment-example |
    Then the step should succeed

    #Go to admin console
    When I run the :navigate_to_admin_console web action
    Then the step should succeed
    When I perform the :goto_one_project_page web action with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    When I perform the :click_utilization_graph_link web action with:
      | metric_kind | memory |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | <%= cb.proj_name %> |
    Then the step should succeed

    When I perform the :goto_one_project_page web action with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    #Click on the resource usage value link, then click the link from a random pod
    When I perform the :click_link_from_uitilization_description web action with:
      | metric_kind | Memory             |
      | link_text   | deployment-example |
    Then the step should succeed
    When I run the :check_pod_detail web action
    Then the step should succeed

    When I perform the :goto_one_project_page web action with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    #Click on the resource usage value link, then click the "View More" link
    When I perform the :click_link_from_uitilization_description web action with:
      | metric_kind | Memory    |
      | link_text   | View more |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | <%= cb.proj_name %> |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21257
  Scenario: Show Pod metrics in Console under multi-tenant environment
    Given the master version >= "4.0"
    Given I open admin console in a browser

    #create project and deploy pod
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Then the step should succeed
    When I run the :new_app client command with:
      | app_repo | quay.io/openshifttest/deployment-example |
    Then the step should succeed

    #Go to admin console
    When I run the :navigate_to_admin_console web action
    Then the step should succeed
    When I perform the :goto_one_project_page web action with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    When I perform the :click_utilization_graph_link web action with:
      | metric_kind | memory |
    Then the step should succeed

    When I perform the :goto_project_pods_list_page web action with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    When I perform the :click_link_with_text web action with:
      | text     | deployment-example |
      | link_url | pods               |
    Then the step should succeed
    When I run the :check_pod_detail web action
    Then the step should succeed

    Given I switch to the second user
    And I open admin console in a browser
    #Go to admin console
    When I run the :navigate_to_admin_console web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Welcome to OpenShift |
    Then the step should succeed
    When I perform the :goto_project_pods_list_page web action with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | No Pods |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-24173
  @admin
  Scenario: run query that returns several hundred metrics
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed
    #search in Query Browser
    When I perform the :perform_metric_query_textarea web action with:
      | metrics | topk(500,cluster_quantile:apiserver_request_duration_seconds:histogram_quantile) |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | cluster_quantile:apiserver_request_duration_seconds:histogram_quantile |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-23243
  @admin
  Scenario: The alert graphs should display error messages returned by the Prometheus API
    Given the master version >= "4.1"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed
    #search in Query Browser
    When I perform the :perform_metric_query_textarea web action with:
      | metrics | openshift_build_total{phase=\"Complete\"} >= 0 |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | An error occurred |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | parse error: unexpected character inside braces: |
    Then the step should succeed
