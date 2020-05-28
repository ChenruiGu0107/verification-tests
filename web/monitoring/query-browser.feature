Feature: query browser

  # @author hongyli@redhat.com
  # @case_id OCP-24343
  @admin
  Scenario: navigate to the query browser via the left side OpenShift console menu
    Given the master version >= "4.2"
    Given I open admin console in a browser
    And the first user is cluster-admin

    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed
    #perform example query
    When I click the following "button" element:
      | text | Insert Example Query |
    Then I get the "class" attribute of the "textarea" web element:
      | text | sum(sort_desc(sum_over_time(ALERTS{alertstate="firing"}[24h]))) by (alertname) |
    #clear query
    When I click the following "button" element:
      | aria-label | Clear Query |
    And I click the following "button" element:
      | text  | Run Queries |
      | class | pf-c-button |
    Then I perform the :check_button_text web action with:
      | text | Insert Example Query |
    #check Prometheus UI link
    When I click the following "a" element:
      | text  | Prometheus UI    |
      | class | co-external-link |
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
      | app_repo | openshift/deployment-example |
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

    #check custom query
    When I perform the :perform_cutomer_query web action with:
      | metrics     | pod:container_memory_usage_bytes:sum |
      | press_enter | :enter                               |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | <%= cb.proj_name %> |
    Then the step should succeed

    #check selected query from dropdown list
    When I run the :click_metrics_query_dropdown web action
    And I perform the :choose_metrics_query web action with:
      | metrics_name | Memory Usage |
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
    Given I open admin console in a browser
    And the first user is cluster-admin

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
      | metrics_name | Filesystem Usage |
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
    Given I open admin console in a browser
    And the first user is cluster-admin
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
      | :kube_pod_info_node_count: |
      | ALERTS                     |
    #check metrics from ocp conosle
    #check selected query from dropdown list
    When I perform the :perform_metric_query_drop_down_admin web action with:
      | metrics_name | :kube_pod_info_node_count: |
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
    