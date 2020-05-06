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
    When I run the :check_messages_when_no_critical_alerts web action
    Then the step should succeed
    When I perform the :view_alert_detail_info_in_drawer web action with:
      | alert_name | AlertmanagerReceiversNotConfigured |
    Then the step should succeed

