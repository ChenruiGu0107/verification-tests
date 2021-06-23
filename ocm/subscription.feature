Feature: About subscriptions list page

  # @author tzhou@redhat.com
  # @case_id OCP-25353
  Scenario: Check the empty page for Openshift Dedicated card and Openshift Container Platform card
    Given I open ocm portal as an noAnyQuotaUser user
    Then the step should succeed
    When I run the :go_to_subscription_quota_annual_page web action
    Then the step should succeed
    When I run the :check_quota_annual_page web action
    Then the step should succeed
    When I run the :go_to_subscription_quota_limit_page web action
    Then the step should succeed
    When I run the :check_quota_limit_page web action
    Then the step should succeed
