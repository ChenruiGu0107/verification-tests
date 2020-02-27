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
