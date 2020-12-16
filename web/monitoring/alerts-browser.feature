Feature: alerts browser

  # @author hongyli@redhat.com
  # @case_id OCP-21144
  @admin
  Scenario: Expire silence from alert details page
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #Prepare a silenced alert
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed

    When I run the :silence_alert_from_detail web action
    Then the step should succeed
    #Open Silence page, expire alert from alert detail page
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :open_silence_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :expire_alert_from_detail web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed
    When I run the :check_silence_detail web action
    Then the step should succeed
    When I perform the :check_page_not_match web action with:
      | content | Silenced |
    Then the step should succeed
    #Open alerts page, the expired alert should display
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    When I run the :disable_silence_tab web action
    Then the step should succeed
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed


  # @author hongyli@redhat.com
  # @case_id OCP-21199
  @admin
  Scenario: Edit Alertmanager Silence - Invalid matcher
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #Prepare a silenced alert
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :silence_alert_from_detail web action
    Then the step should succeed
    #Open Silence page, edit silence and set empty matcher
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :open_silence_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :edit_silence_alert web action
    Then the step should succeed
    When I run the :remove_matcher_silence_alert web action
    And  I run the :remove_matcher_silence_alert web action
    Then the step should succeed
    When I run the :perform_silence web action
    Then the step should succeed
    When I run the :input_matcher_name_silence web action
    When I run the :perform_silence web action
    Then the step should succeed
    And I click the following "button" element:
      | text | Cancel |
    Then the step should succeed
    #Expire silence to restore environment
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21150
  @admin
  Scenario: Edit Alertmanager Silence - Invalid End time
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #Prepare a silenced alert
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :silence_alert_from_detail web action
    Then the step should succeed
    #Open Silence page, edit silence and set invalid end time
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :open_silence_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :edit_silence_alert web action
    Then the step should succeed
    When I run the :set_invalid_end_time_silence web action
    Then the step should succeed
    When I run the :perform_silence web action
    And the step should succeed
    When I click the following "button" element:
      | text | Cancel |
    Then the step should succeed
    #Expire silence to restore environment
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21108
  @admin
  Scenario: List all alerts and could filter alerts by state
    #<=4.5
    Given the master version >= "4.0"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #Prepare a silenced alert
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :silence_alert_from_detail web action
    Then the step should succeed
    #Go back alert page and filter with status
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #alerts with both status display
    When I perform the :status_specific_alert web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should succeed
    #Disable Firing staus
    When I perform the :click_link_with_text_only web action with:
      | text | Firing |
    Then the step should succeed
    When I perform the :status_specific_alert web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should succeed
    #Disable Firing and Silenced
    When I perform the :click_link_with_text_only web action with:
      | text | Silenced |
    Then the step should succeed
    When I perform the :status_specific_alert web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should fail
    #Enable Firing and Disable Silenced
    When I perform the :click_link_with_text_only web action with:
      | text | Firing |
    Then the step should succeed
    When I perform the :status_specific_alert web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should fail
    #Open Silence page, open the detail page
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :open_silence_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    #Expire silence to restore environment
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-32857
  @admin
  Scenario: List all alerts and could filter alerts by state and severity
    Given the master version >= "4.6"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #Prepare a silenced alert
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :silence_alert_from_detail web action
    Then the step should succeed
    #Go back to alert page
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #By default, only firing alerts display
    When I perform the :status_specific_alert_no_clear web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should fail
    #Filter alerts with status silence
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | silenced |
    Then the step should succeed
    When I perform the :status_specific_alert_no_clear web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should succeed
    #Filter alerts with status firing
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | firing |
    Then the step should succeed
    When I perform the :status_specific_alert_no_clear web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should fail
    #Filter alerts with severity none
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | none |
    Then the step should succeed
    When I perform the :status_specific_alert_no_clear web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should succeed
    #Filter alerts with severity critical
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | critical |
    Then the step should succeed
    When I perform the :status_specific_alert_no_clear web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should fail
    #Filter alerts with status silence and severity none
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | silenced |
    Then the step should succeed
    When I perform the :list_alerts_by_filters web action with:
      | filter_item | none |
    Then the step should succeed
    When I perform the :status_specific_alert_no_clear web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should succeed
    #Go to alert rule page, and come back, filter come back to default status
    When I run the :goto_monitoring_alertrules_page web action
    Then the step should succeed
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    When I perform the :status_specific_alert_no_clear web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should fail
    #Open Silence page, open the detail page
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :open_silence_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    #Expire silence to restore environment
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21131
  @admin
  Scenario: List all silences and could filter silences by state
    #<=4.5
    Given the master version >= "4.1"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #Prepare a silenced alert
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :silence_alert_from_detail web action
    Then the step should succeed
    #Open Silence page, open the detail page
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :open_silence_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    #Expire silence to prepare Expired status alert
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed
    When I run the :check_silence_detail web action
    Then the step should succeed
    When I perform the :check_page_not_match web action with:
      | content | Silenced |
    Then the step should succeed
    #Prepare a silenced alert again
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :silence_alert_from_detail web action
    Then the step should succeed
    #Filter silence alerts by status
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    #By default, Active/pending enabled and Expired disabled
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Active   |
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Expired  |
    Then the step should fail
    #Active enabled and Enable Expired
    When I perform the :click_link_with_text_only web action with:
      | text | Expired |
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Active   |
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Expired  |
    Then the step should succeed
    #Disable Active and Enable Expired
    When I perform the :click_link_with_text_only web action with:
      | text | Active |
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Active   |
    Then the step should fail
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Expired  |
    Then the step should succeed
    #Enable Active and disable Expired to restore default status
    When I perform the :click_link_with_text_only web action with:
      | text | Active |
    Then the step should succeed
    When I perform the :click_link_with_text_only web action with:
      | text | Expired |
    Then the step should succeed
    #Expire silence to restore environment
    When I perform the :open_silence_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-32858
  @admin
  Scenario: Filter silences by state
    Given the master version >= "4.6"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #Prepare a silenced alert
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :silence_alert_from_detail web action
    Then the step should succeed
    #Open Silence page, open the detail page
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :open_silence_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    #Expire silence to prepare Expired status silence
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed
    When I run the :check_silence_detail web action
    Then the step should succeed
    When I perform the :check_page_not_match web action with:
      | content | Silenced |
    Then the step should succeed
    #Prepare a silenced alert again
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :silence_alert_from_detail web action
    Then the step should succeed
    #Filter silence alerts by status
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    #By default, Active/pending enabled and Expired disabled
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Active   |
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Expired  |
    Then the step should fail
    #Enable Active/pending/Expired filters
    When I perform the :list_alerts_by_filters web action with:
      | filter_item | expired |
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Active   |
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Expired  |
    Then the step should succeed
    #Disable Active and Enable Expired
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | expired |
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Active   |
    Then the step should fail
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Expired  |
    Then the step should succeed
    #Go to alert rule page, and come back, filter come back to default status
    When I run the :goto_monitoring_alertrules_page web action
    Then the step should succeed
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Active   |
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Expired  |
    Then the step should fail
    #Expire silence to restore environment
    When I perform the :open_silence_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-29061
  @admin
  Scenario: Check alerting rules list page
    Given the master version >= "4.5"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alertrules_page web action
    Then the step should succeed
    When I perform the :open_alertrules_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I perform the :click_alertrule_expression web action with:
      | expression | vector(1) |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-29300
  @admin
  Scenario: fields of silence alert
    Given the master version >= "4.5"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #Prepare a silenced alert
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :silence_alert_from_detail_check_fields web action
    Then the step should succeed
    When I run the :edit_silence_alert web action
    Then the step should succeed
    When I run the :check_silence_fields web action
    Then the step should succeed
    And I click the following "button" element:
      | text | Cancel |
    Then the step should succeed
    #Expire silence to restore environment
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21166
  @admin
  Scenario: Create, edit, expire Alertmanager Silence
    Given the master version >= "4.1"
    And the first user is cluster-admin
    Given I open admin console in a browser
    #Create new Alertmanager Silence
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    #click create silence button
    When I run the :click_create_button web action
    Then the step should succeed
    #set value for alert labels
    When I perform the :set_alert_label web action with:
      | label_value | Watchdo.* |
    Then the step should succeed
    When I run the :silence_alert_from_create_button web action
    Then the step should succeed
    #Open Silence page, edit silence
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :open_silence_detail web action with:
      | alert_name | Watchdo.* |
    Then the step should succeed
    When I run the :edit_silence_alert web action
    Then the step should succeed
    When I run the :check_use_regular web action
    Then the step should succeed
    When I run the :perform_silence web action
    Then the step should succeed
    #Expire silence from silences list page and silence details page
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :expire_alert_from_cog_menu web action with:
      | alert_name | Watchdo.* |
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21334
  @admin
  Scenario: alert should not be silenced if the silence does not satisfy specified label constraints
    Given the master version >= "4.1"
    And the first user is cluster-admin
    Given I open admin console in a browser
    #Create new Alertmanager Silence
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    #set value for alert labels
    When I perform the :set_alert_label web action with:
      | label_value | Watchdo.* |
    Then the step should succeed
    When I run the :silence_alert_from_create_button web action
    Then the step should succeed
    #Go back to alert page and filter with status
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #alerts is still firing status
    When I perform the :status_specific_alert web action with:
      | alert_name | Watchdog |
      | status     | Firing   |
    Then the step should succeed
    #Expire silence from silences list page and silence details page
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :expire_alert_from_cog_menu web action with:
      | alert_name | Watchdo.* |
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21363
  @admin
  Scenario: When Silence matcher is a regex, the Firing Alerts list should be populated correctly
    Given the master version >= "4.1"
    And the first user is cluster-admin
    Given I open admin console in a browser
    #Create new Alertmanager Silence
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    #set value for alert labels
    When I perform the :set_alert_label web action with:
      | label_value | Watchdo.* |
    Then the step should succeed
    When I run the :check_use_regular web action
    Then the step should succeed
    When I run the :silence_alert_from_create_button web action
    Then the step should succeed
    #When Silence matcher is a regex, the Firing Alerts list should be populated correctly
    #Go back to alert page and filter with status
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #alerts is silenced
    When I perform the :status_specific_alert web action with:
      | alert_name | Watchdog |
      | status     | Silenced |
    Then the step should succeed
    #Expire silence from silences list page and silence details page
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :expire_alert_from_cog_menu web action with:
      | alert_name | Watchdo.* |
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21192
  @admin
  Scenario: Show a detailed and complete view of Alertmanager Silence, "Firing Alerts" list is in Silence details page
    Given the master version >= "4.1"
    And the first user is cluster-admin
    Given I open admin console in a browser
    #Create new Alertmanager Silence
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    #set value for alert labels
    When I perform the :set_alert_label web action with:
      | label_value | Watchdo.* |
    Then the step should succeed
    When I run the :check_use_regular web action
    Then the step should succeed
    When I run the :silence_alert_from_create_button web action
    Then the step should succeed
    #Show a detailed and complete view of Alertmanager Silence, "Firing Alerts" list is in Silence details page
    When I run the :check_info_of_silence_detail_reg web action
    Then the step should succeed
    #Expire silence from silences list page and silence details page
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I perform the :expire_alert_from_cog_menu web action with:
      | alert_name | Watchdo.* |
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21132
  @admin
  Scenario: Show a detailed and complete view of an alerting rule
    Given the master version >= "4.1"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #open alert detail page
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :open_alert_rule_from_detail web action
    Then the step should succeed
    When I run the :check_alert_rule_details web action
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-24604
  @admin
  Scenario: Alert graph is added to alert rule details page
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #open alert detail page
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :open_alert_rule_from_detail web action
    Then the step should succeed
    #hide/show graph
    When I run the :hide_alert_graph web action
    Then the step should succeed
    When I perform the :check_zoom_value web action with:
      | zoom_value | 30m |
    Then the step should fail
    When I run the :show_alert_graph web action
    Then the step should succeed
    When I perform the :check_zoom_value web action with:
      | zoom_value | 30m |
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
    #Click the "View in Metrics" link
    When I run the :click_view_metrics web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | vector(1) |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-21124
  @admin
  Scenario: Show a detailed and complete view of an Alert
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #open alert detail page
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :check_alert_detail web action
    Then the step should succeed
    #check prometheus
    And I use the "openshift-monitoring" project
    And evaluation of `route('prometheus-k8s').spec.host` is stored in the :prom_route clipboard
    # get sa/prometheus-k8s token
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard
    #alerts page
    When I perform the HTTP request:
      """
      :url: https://<%= cb.prom_route %>/alerts
      :method: get
      :headers:
        :Authorization: Bearer <%= cb.sa_token %>
      """
    Then the step should succeed
    And the output should contain:
      | Prometheus Time Series Collection and Processing Server |

  # @author hongyli@redhat.com
  # @case_id OCP-24601
  @admin
  Scenario: Alert graph is added to alert details page
    Given the master version >= "4.2"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #open alert detail page
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    #hide/show graph
    When I run the :hide_alert_graph web action
    Then the step should succeed
    When I perform the :check_zoom_value web action with:
      | zoom_value | 30m |
    Then the step should fail
    When I run the :show_alert_graph web action
    Then the step should succeed
    When I perform the :check_zoom_value web action with:
      | zoom_value | 30m |
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
    #Click the "View in Metrics" link
    When I run the :click_view_metrics web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | vector(1) |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-32859
  @admin
  Scenario: List all alerting rules and could filter rules by severity and state
    Given the master version >= "4.6"
    And the first user is cluster-admin
    Given I open admin console in a browser

    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #Open alert rule page
    When I run the :goto_monitoring_alertrules_page web action
    Then the step should succeed
    #Filter alerting rules by state
    #By default, all alerting rules from platform are displayed
    When I perform the :status_specific_alert_rule_no_clear web action with:
      | alert_name | Watchdog |
      | table_text | Watchdog |
    Then the step should succeed
    #Enable Firing
    When I perform the :list_alerts_by_filters web action with:
      | filter_item | firing |
    Then the step should succeed
    When I perform the :status_specific_alert_rule_no_clear web action with:
      | alert_name | Watchdog |
      | table_text | Watchdog |
    Then the step should succeed
    #Enable inactive and diable active
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | pending |
    Then the step should succeed
    When I perform the :status_specific_alert_rule_no_clear web action with:
      | alert_name | Watchdog |
      | table_text | Watchdog |
    Then the step should fail
    #Enable severity info
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | none |
    Then the step should succeed
    When I perform the :status_specific_alert_rule_no_clear web action with:
      | alert_name | Watchdog |
      | table_text | Watchdog |
    Then the step should succeed
    #Enable severity critical and state pending
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | critical |
    Then the step should succeed
    When I perform the :list_alerts_by_filters web action with:
      | filter_item | pending |
    Then the step should succeed
    When I perform the :status_specific_alert_rule_no_clear web action with:
      | alert_name | Watchdog |
      | table_text | Watchdog |
    Then the step should fail
    #Go to Silence page, and come back, filter come back to default status
    When I run the :goto_monitoring_silences_page web action
    Then the step should succeed
    When I run the :goto_monitoring_alertrules_page web action
    Then the step should succeed
    When I perform the :status_specific_alert_rule_no_clear web action with:
      | alert_name | Watchdog |
      | table_text | Watchdog |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-33769
  @admin
  @destructive
  Scenario: Admin can see alerts from both sources "Platform" and "User"
    Given the master version >= "4.6"
    And the first user is cluster-admin
    Given admin ensures "cluster-monitoring-config" configmap is deleted from the "openshift-monitoring" project after scenario

    #enable UserWorkload
    Given I obtain test data file "monitoring/config_map_enableUserWorkload.yaml"
    When I run the :apply client command with:
      | f         | config_map_enableUserWorkload.yaml |
      | overwrite | true                               |
    Then the step should succeed

    Given I create a project with non-leading digit name
    Then the step should succeed
    Given I obtain test data file "monitoring/prometheus_rules_example_alert.yaml"
    When I run the :apply client command with:
      | f         | prometheus_rules_example_alert.yaml |
      | overwrite | true                                |
    Then the step should succeed
    When I use the "openshift-monitoring" project
    # get sa/prometheus-k8s token
    And evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard
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
      | TestAlert |
    """ 

    Given I open admin console in a browser
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | user |
    Then the step should succeed
    When I perform the :status_specific_alert_no_clear web action with:
      | alert_name | TestAlert |
      | status     | Firing    |
    Then the step should succeed
  
    #Go to alert rule page, and come back, filter come back to default status
    When I run the :goto_monitoring_alertrules_page web action
    Then the step should succeed
    #Enable inactive and diable active
    When I perform the :list_alerts_by_filters_clear web action with:
      | filter_item | user |
    Then the step should succeed
    When I perform the :status_specific_alert_rule_no_clear web action with:
      | alert_name | HighErrors |
      | table_text | HighErrors |
    Then the step should succeed

  # @author hongyli@redhat.com
  # @case_id OCP-24439
  @admin
  @destructive
  Scenario: If alerts have the same name and labels, should take to the right alert page when clicking the name
    Given the master version >= "4.3"
    Given the first user is cluster-admin
    Given admin ensures "ocp-24439-example" deployment is deleted from the "default" project after scenario

    Given I obtain test data file "monitoring/pod_wrong_image-ocp-24439.yaml"
    When I run the :apply client command with:
      | f         | pod_wrong_image-ocp-24439.yaml |
      | overwrite | true                           |
    Then the step should succeed

    Given I open admin console in a browser

    When I run the :get admin command with:
      | resource | pod     |
      | n        | default |
    Then the step should succeed
    And evaluation of `@result[:stdout].split(/\n/).map{|n| n.split(/\s/)[0]}.map{|n| n[/(.*)ocp-24439-example(.*)/]}.compact!` is stored in the :example_pods clipboard

    #check alert detail for both pods
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    #open alert detail page
    When I perform the :open_alert_detail_href web action with:
      | alert_name | KubePodNotReady           |
      | text       | KubePodNotReady           |
      | link_url   | <%= cb.example_pods[0] %> |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | <%= cb.example_pods[0]  %> |
    Then the step should succeed
    #check alert detail for both pods
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    When I perform the :open_alert_detail_href web action with:
      | alert_name | KubePodNotReady           |
      | text       | KubePodNotReady           |
      | link_url   | <%= cb.example_pods[1] %> |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | <%= cb.example_pods[1]  %> |
    Then the step should succeed
