Feature: only about the overview page of OCM

  # @author yuwan@redhat.com
  # @case_id OCP-30479
  Scenario: Check the "empty state" on the dashboard overview page
    Given I open ocm portal as an noAnyQuotaUser user
    Then the step should succeed
    When I run the :go_to_ocm_overview_page web action
    Then the step should succeed
    When I run the :check_empty_overview_page web action
    Then the step should succeed

