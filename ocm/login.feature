Feature: About login feature

# @author tzhou@redhat.com
# @case_id OCP-21306
Scenario: Login the OCM console with an existed RH account and then logout
  Given I open ocm portal as an regularUser user
  Then the step should succeed
  When I run the :cluster_list_page_loaded web action
  Then the step should succeed
  When I run the :click_logout_button web action
  Then the step should succeed
  When I run the :logout_page_loaded web action
  Then the step should succeed

