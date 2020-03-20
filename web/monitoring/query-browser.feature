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
      | text  | sum(sort_desc(sum_over_time(ALERTS{alertstate="firing"}[24h]))) by (alertname) |
    #clear query
    When I click the following "button" element:
      | aria-label | Clear Query |
      | class      | pf-c-button |
    And I click the following "button" element:
      | text  | Run Queries |
      | class | pf-c-button |
    Then I get the "class" attribute of the "button" web element:
      | text | Insert Example Query |
    #check Prometheus UI link
    When I click the following "a" element:
      | text  | Prometheus UI    |
      | class | co-external-link |
    Then the step should succeed