  Feature: console style related

  # @author xiaocwan@redhat.com
  # @case_id OCP-27590
  @admin
  Scenario: Migrate PF3 modals to PF4
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    When I open admin console in a browser
    Then the step should succeed

    # check operator creation side dialog panel
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I run the :open_first_card_overlay_panel web action
    Then the step should succeed
    When I run the :check_side_overlay_dialog_modal web action
    Then the step should succeed

    # check namespace creation overlay modal
    When I run the :goto_namespace_list_page web action
    Then the step should succeed
    When I run the :click_yaml_create_button web action
    Then the step should succeed
    When I run the :check_overlay_edit_modal web action
    Then the step should succeed

    # check resource edit overlay modal
    When I perform the :goto_one_deployment_page web action with:
      | project_name | openshift-console |
      | deploy_name  | console           |
    Then the step should succeed
    When I run the :click_annotation_edit_link web action
    Then the step should succeed
    When I run the :check_overlay_edit_modal_title web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-24307
  @admin
  Scenario: Check charts are using PF4 victory
    Given the master version >= "4.4"
    Given I have a project
    When I run the :create_quota admin command with:
      | name | myquota-<%= project.name %> |
      | hard | cpu=1,requests.memory=1G,limits.cpu=2,limits.memory=2G,pods=2,services=3 |
      | n    | <%= project.name %>         |
    Then the step should succeed

    Given the first user is cluster-admin
    When I open admin console in a browser
    Then the step should succeed

    # check area charts on Overview, Pod detail, Node detail pages
    # Overview page
    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    When I run the :check_cluster_utilization_charts_style web action
    Then the step should succeed
    # Pod detail page
    When I perform the :goto_one_pod_page web action with:
      | project_name  | openshift-monitoring |
      | resource_name | prometheus-k8s-0     |
    Then the step should succeed
    When I run the :check_pod_detail_page_charts_style web action
    Then the step should succeed
    # Node detail page
    Given I select a random node's host
    When I perform the :goto_one_node_page web action with:
      | node_name | <%= node.name %> |
    Then the step should succeed
    When I run the :check_node_detail_page_charts_style web action
    Then the step should succeed

    # check gauges for Quota detail page
    When I perform the :goto_one_quota_page web action with:
      | project_name | <%= project.name %>         |
      | quota_name   | myquota-<%= project.name %> |
    Then the step should succeed
    When I run the :check_quota_detail_page_charts_style web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-24305
  @admin
  Scenario: Check tables are in PF4 styles
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    When I open admin console in a browser
    Then the step should succeed

    When I perform the :goto_deployment_page web action with:
      | project_name  | openshift-console |
    Then the step should succeed
    When I run the :check_list_view_style web action
    Then the step should succeed

    When I perform the :goto_routes_page web action with:
      | project_name  | openshift-console |
    Then the step should succeed
    When I run the :check_list_view_style web action
    Then the step should succeed

    When I perform the :goto_imagestreams_page web action with:
      | project_name  | openshift |
    Then the step should succeed
    When I run the :check_list_view_style web action
    Then the step should succeed

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    When I run the :check_list_view_style web action
    Then the step should succeed

    When I run the :goto_node_page web action
    Then the step should succeed
    When I run the :check_list_view_style web action
    Then the step should succeed

    When I run the :goto_cluster_operators web action
    Then the step should succeed
    When I run the :check_list_view_style web action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-26877
  @admin
  Scenario: Operator Hub and Developer Catalog pages are migrated to pf4 catalog view
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    When I open admin console in a browser
    Then the step should succeed

    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I run the :check_catalog_tile_style web action
    Then the step should succeed
    When I run the :check_vertical_tabs_style web action
    Then the step should succeed
    When I run the :check_filter_panel_style web action
    Then the step should succeed
    When I run the :open_first_card_in_overlay web action
    Then the step should succeed
    When I run the :check_filter_side_panel_style web action
    Then the step should succeed

    When I perform the :goto_catalog_page web action with:
      | project_name | default |
    Then the step should succeed
    When I run the :show_catalog_items web action
    Then the step should succeed

    When I run the :check_catalog_tile_style web action
    Then the step should succeed
    When I run the :check_vertical_tabs_style web action
    Then the step should succeed
    When I run the :check_filter_panel_style web action
    Then the step should succeed
    When I run the :open_first_card_in_overlay web action
    Then the step should succeed
    When I run the :check_filter_side_panel_style web action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-24223
  Scenario: Check Alerts styles
    Given the master version >= "4.2"
    Given I have a project
    Given I obtain test data file "deployment/simpledc.json"
    When I run oc create with "simpledc.json" replacing paths:
      | ["metadata"]["name"] | ruby |
    Then the step should succeed

    When I open admin console in a browser
    Then the step should succeed
    When I perform the :goto_deploy_image_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :search_and_deploy_image web action with:
      | search_content | quay.io/openshifttest/hello-openshift:aosqe |
    Then the step should succeed
    Given I wait up to 10 seconds for the steps to pass:
    """
    When I get project deploymentconfigs
    Then the output should contain "hello-openshift"
    """
    When I perform the :check_alert_style_on_deploy_image_page web action with:
      | project_name   | <%= project.name %>                         |
      | search_content | quay.io/openshifttest/hello-openshift:aosqe |
    Then the step should succeed

    When I perform the :check_alert_style_on_dc_env_page web action with:
      | project_name  | <%= project.name %> |
      | dc_name       | ruby                |
      | env_var_name  | test                |
      | env_var_value | one                 |
    Then the step should succeed

    When I perform the :check_alert_style_for_dc_pause_rollouts web action with:
      | project_name  | <%= project.name %> |
      | dc_name       | ruby                |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-29799
  @admin
  Scenario: Check PF4 Toolbar on search page
    Given the master version >= "4.5"
    Given the first user is cluster-admin
    When I open admin console in a browser
    When I perform the :goto_project_pods_list_page web action with:
      | project_name | openshift-console |
    Then the step should succeed
    When I run the :check_search_tool_bar_style web action
    Then the step should succeed

    # check style for Filter
    When I run the :filter_running_and_check_style web action
    Then the step should succeed
    When I run the :filter_pending_and_check_style web action
    Then the step should succeed
    When I run the :check_filtered_style web action
    Then the step should succeed
    When I run the :check_remove_style_and_remove web action
    Then the step should succeed

    # check style for search input
    When I perform the :filter_name_and_check_style web action with:
      | input_value | console |
    Then the step should succeed
    When I run the :check_filtered_style web action
    Then the step should succeed
    When I perform the :filter_label_and_check_style web action with:
      | input_value     | app         |
      | suggestion_text | app=console |
    Then the step should succeed
    When I run the :check_filtered_style web action
    Then the step should succeed
    When I run the :clear_all_filters web action
    Then the step should succeed

    # check style on deployments page
    When I perform the :goto_deployment_page web action with:
      | project_name | openshift-console |
    Then the step should succeed
    When I perform the :filter_name_and_check_style web action with:
      | input_value | console |
    Then the step should succeed
    When I run the :check_filtered_style web action
    Then the step should succeed
    When I perform the :filter_label_and_check_style web action with:
      | input_value     | app         |
      | suggestion_text | app=console |
    Then the step should succeed
    When I run the :check_filtered_style web action
    Then the step should succeed
    When I run the :clear_all_filters web action
    Then the step should succeed

    # check style on secrets page
    When I perform the :goto_secrets_page web action with:
      | project_name | openshift-console |
    Then the step should succeed
    When I run the :check_search_tool_bar_style web action
    Then the step should succeed
