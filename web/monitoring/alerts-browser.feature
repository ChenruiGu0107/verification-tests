Feature: alerts browser

  # @author hongyli@redhat.com
  # @case_id OCP-21144
  @admin
  Scenario: Expire silence from alert details page
    Given the master version >= "4.2"
    Given I open admin console in a browser
    And the first user is cluster-admin

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
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :expire_alert_from_detail web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed
    When I run the :check_silence_detail web action
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
    Given I open admin console in a browser
    And the first user is cluster-admin

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
    When I perform the :open_alert_detail web action with:
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
    Given I open admin console in a browser
    And the first user is cluster-admin

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
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :edit_silence_alert web action
    Then the step should succeed
    When I run the :set_invalid_end_time_silence web action
    Then the step should succeed
    When I run the :perform_silence web action
    And the step should succeed
    When I perform the :check_div_text web action with:
      | text | be in the past |
    Then the step should succeed
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
    Given the master version >= "4.0"
    Given I open admin console in a browser
    And the first user is cluster-admin

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
    When I perform the :open_alert_detail web action with:
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
    Given the master version >= "4.0"
    Given I open admin console in a browser
    And the first user is cluster-admin

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
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    #Expire silence to prepare Expired status alert
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
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
      | status     | Active |
    Then the step should succeed
    When I perform the :status_specific_silence web action with:
      | alert_name | Watchdog |
      | status     | Expired |
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
      | status     | Expired |
    Then the step should succeed
    #Enable Active and disable Expired to restore default status
    When I perform the :click_link_with_text_only web action with:
      | text | Active |
    Then the step should succeed
    When I perform the :click_link_with_text_only web action with:
      | text | Expired |
    Then the step should succeed
    #Expire silence to restore environment
    When I perform the :open_alert_detail web action with:
      | alert_name | Watchdog |
    Then the step should succeed
    When I run the :expire_alert_from_actions web action
    And I click the following "button" element:
      | text | Expire Silence |
    Then the step should succeed