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
    When I run the :silence_alert_from_action web action
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
    #Open alerts page, the expired alert should display
    When I run the :goto_monitoring_alerts_page web action
    Then the step should succeed
    When I run the :disable_silence_tab web action
    Then the step should succeed
    When I perform the :click_alert_link_with_text web action with:
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
    When I run the :silence_alert_from_action web action
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
    When I click the following "button" element:
      | text | Save |
    Then the step should succeed
    When I run the :input_matcher_name_silence web action
    And I click the following "button" element:
      | text | Save |
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
    When I run the :silence_alert_from_action web action
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
    When I click the following "button" element:
      | text | Save |
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