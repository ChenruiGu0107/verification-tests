Feature: dashboards related cases

  # @author yapei@redhat.com
  # @case_id OCP-27584
  @admin
  Scenario: Add view all alerts to status card
    Given the master version >= "4.4"
    Given the first user is cluster-admin

    Given I open admin console in a browser
    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    When I run the :click_view_alerts_button web action
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    And the expression should be true> browser.url =~ /monitoring.*alerts/
    """
    When I run the :check_alerts_tab web action
    Then the step should succeed
    When I run the :check_silences_tab web action
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-27654
  @admin
  Scenario: check NotificationDrawer on the masthead
    Given the master version >= "4.4"
    And I open admin console in a browser
    When I run the :click_notification_drawer web action
    Then the step should fail
    Given the first user is cluster-admin
    And I open admin console in a browser
    When I run the :open_notification_drawer web action
    Then the step should succeed
    When I run the :close_notification_drawer web action
    Then the step should succeed
    When I run the :open_notification_drawer web action
    Then the step should succeed
    When I run the :check_toggle_title_in_notification_drawer web action
    Then the step should succeed
    When I run the :expand_critical_alerts_toggle web action
    Then the step should succeed
    When I perform the :view_alert_detail_info_in_drawer web action with:
      | alert_name | AlertmanagerReceiversNotConfigured |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-28297
  @admin
  Scenario: Cluster Inventory block has a full list of required items
    Given the master version >= "4.4"
    Given I have a project
    Given the first user is cluster-admin
    And I open admin console in a browser

    # Check all required items such as Pods, Nodes, Storage Classes, PVCs are shown in Cluster Inventory
    When I run the :check_cluster_inventory_items web action
    Then the step should succeed

    Given I stores all nodes to the :cluster_total_nodes clipboard
    Given I stores all storageclasses to the :cluster_total_storageclasses clipboard
    Given I stores all persistentvolumeclaims to the :cluster_total_pvcs clipboard

    # Check matched counter for resources
    When I perform the :check_matched_number_of_nodes web action with:
      | number_of_nodes | <%= cb.cluster_total_nodes.length %> |
    Then the step should succeed
    When I perform the :check_matched_number_of_pvcs web action with:
      | number_of_pvcs | <%= cb.cluster_total_pvcs.length %> |
    Then the step should succeed
    When I perform the :check_matched_number_of_storageclasses web action with:
      | number_of_storageclasses | <%= cb.cluster_total_storageclasses.length %> |
    Then the step should succeed

    # create a Pending pod
    Given I obtain test data file "pods/pod-invalid.yaml"
    When I run the :create client command with:
      | f | pod-invalid.yaml    |
      | n | <%= project.name %> |
    Then the step should succeed
    Given the pod named "hello-openshift-invalid" status becomes :pending within 300 seconds

    # create a Failed pod
    Given I obtain test data file "networking/failed-pod.json"
    When I run the :create client command with:
      | f | failed-pod.json     |
      | n | <%= project.name %> |
    Then the step should succeed
    Given the pod named "fail-pod" status becomes :failed within 300 seconds

    When I run the :click_failed_icon_link_in_cluster_inventory web action
    Then the step should succeed
    When I run the :wait_table_loaded web action
    Then the step should succeed
    When I perform the :check_resource_pod_name_and_link web action with:
      | pod_name     | fail-pod            |
      | project_name | <%= project.name %> |
    Then the step should succeed

    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    When I run the :click_progressing_icon_link_in_cluster_inventory web action
    Then the step should succeed
    When I run the :wait_table_loaded web action
    Then the step should succeed
    When I perform the :check_resource_pod_name_and_link web action with:
      | pod_name     | hello-openshift-invalid |
      | project_name | <%= project.name %>     |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-26557
  @admin
  @flaky
  Scenario: System events streaming
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    And I open admin console in a browser
    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    When I run the :click_view_events_button web action
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    And the expression should be true> browser.url.end_with? "/k8s/all-namespaces/events"
    """

    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    When I run the :click_events_pause_button web action
    Then the step should succeed
    Given I create a new project
    Given I obtain test data file "pods/pod-invalid.yaml"
    When I run the :create client command with:
      | f | pod-invalid.yaml    |
      | n | <%= project.name %> |
    Then the step should succeed
    Given 10 seconds have passed
    When I perform the :check_event_message_on_dashboard_page web action with:
      | event_message | Pulling image "wrong" |
    Then the step should fail
    When I run the :click_events_resume_button web action
    Then the step should succeed
    Given 10 seconds have passed
    When I perform the :check_event_message_on_dashboard_page web action with:
      | event_message | Pulling image "wrong" |
    Then the step should succeed

    Given I obtain test data file "networking/failed-pod.json"
    When I run oc create over "failed-pod.json" replacing paths:
      | ["spec"]["containers"][0]["image"] | uitest/hello-openshift |
    Then the step should succeed
    Given 10 seconds have passed
    When I perform the :check_event_message_on_dashboard_page web action with:
      | event_message | Pulling image "uitest/hello-openshift" |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-27586
  @admin
  Scenario: Add network and pod count to overview
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    And I open admin console in a browser

    # check Cluster Utilization card has CPU, Memory, Filesystem, Network Transfer and Pod count
    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    When I run the :check_cluster_utilization_items web action
    Then the step should succeed

    # check Cluster Utilization - CPU breakdown info
    When I run the :check_cpu_breakdown_info_when_filter_by_project web action
    Then the step should succeed
    When I run the :check_cpu_breakdown_info_when_filter_by_pod web action
    Then the step should succeed
    When I run the :check_cpu_breakdown_info_when_filter_by_node web action
    Then the step should succeed

    # check Cluster Utilization - Memory breakdown info
    When I run the :check_memory_breakdown_info_when_filter_by_project web action
    Then the step should succeed
    When I run the :check_memory_breakdown_info_when_filter_by_pod web action
    Then the step should succeed
    When I run the :check_memory_breakdown_info_when_filter_by_node web action
    Then the step should succeed

    # check Cluster Utilization - Filesystem breakdown info
    When I run the :check_filesystem_breakdown_info_when_filter_by_project web action
    Then the step should succeed
    When I run the :check_filesystem_breakdown_info_when_filter_by_pod web action
    Then the step should succeed

    # temporaly comment out the check due to bug 1865817
    #When I run the :check_filesystem_breakdown_info_when_filter_by_node web action
    #Then the step should succeed

    # check Cluster Utilization -  Network in breakdown info
    When I run the :check_network_in_breakdown_info_when_filter_by_project web action
    Then the step should succeed
    When I run the :check_network_in_breakdown_info_when_filter_by_pod web action
    Then the step should succeed
    When I run the :check_network_in_breakdown_info_when_filter_by_node web action
    Then the step should succeed

    # check Cluster Utilization -  Network out breakdown info
    When I run the :check_network_out_breakdown_info_when_filter_by_project web action
    Then the step should succeed
    When I run the :check_network_out_breakdown_info_when_filter_by_pod web action
    Then the step should succeed
    When I run the :check_network_out_breakdown_info_when_filter_by_node web action
    Then the step should succeed

    # check Cluster Utilization - Pod count breakdown info
    When I run the :check_pod_count_breakdown_info_when_filter_by_project web action
    Then the step should succeed
    # also check View More links to Monitoring page
    When I run the :check_pod_count_breakdown_info_when_filter_by_node web action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-19817
  @admin
  Scenario: Check metrics charts
    Given the master version >= "4.3"
    Given I register clean-up steps:
    """
    When I run the :oadm_policy_remove_role_from_user admin command with:
      | role_name | admin                              |
      | user_name | <%= user(0, switch: false).name %> |
      | n         | openshift-apiserver                |
    Then the step should succeed
    """
    When I run the :oadm_policy_add_role_to_user admin command with:
      | role_name | admin                              |
      | user_name | <%= user(0, switch: false).name %> |
      | n         | openshift-apiserver                |
    Then the step should succeed
    Given admin uses the "openshift-apiserver" project
    And a pod becomes ready with labels:
      | apiserver=true |
    Given I open admin console in a browser
    When I perform the :goto_one_project_page web action with:
      | project_name | openshift-apiserver |
    Then the step should succeed
    When I run the :check_charts_in_project_utilization web action
    Then the step should succeed
    When I run the :check_no_errors_in_charts web action
    Then the step should succeed
    When I run the :click_filesystem_chart web action
    Then the step should succeed
    When I perform the :check_on_dev_monitoring_page web action with:
      | project_name | openshift-apiserver |
    Then the step should succeed

    When I perform the :goto_one_pod_page web action with:
      | project_name  | openshift-apiserver |
      | resource_name | <%= pod.name %>     |
    Then the step should succeed
    When I run the :check_charts_on_pod_page web action
    Then the step should succeed
    When I run the :check_no_errors_in_charts web action
    Then the step should succeed
    When I run the :click_memory_usage_chart web action
    Then the step should succeed
    When I perform the :check_on_dev_monitoring_page web action with:
      | project_name | openshift-apiserver |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-36912
  @admin
  @destructive
  Scenario: Display insights status on console
    Given the master version >= "4.7"
    Given the first user is cluster-admin
    And I open admin console in a browser
    When I perform the :check_insights_status_when_available web action with:
      | cluster_id | <%= cluster_version("version").cluster_id %> |
    Then the step should succeed

    Given I register clean-up steps:
    """
    When I run the :scale admin command with:
      | resource | deployment         |
      | name     | insights-operator  |
      | replicas | 1                  |
      | n        | openshift-insights |
    Then the step should succeed
    """

    # scale insights operator down to 0
    When I run the :scale admin command with:
      | resource | deployment         |
      | name     | insights-operator  |
      | replicas | 0                  |
      | n        | openshift-insights |
    Then the step should succeed
    Given 120 seconds have passed
    When I run the :check_insights_status_when_unavailable web action
    Then the step should succeed
