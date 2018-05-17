Feature: ONLY Accountant console related feature's scripts in this file

  # @author xiaocwan@redhat.com
  # @case_id OCP-13630
  Scenario: the user's usernames are same in the openshift web console and the accountant web console
    Given I open accountant console in a browser
    When I perform the :check_account_name web action with:
      | account_name | <%= user.name.sub("-", "_") %> |
    Then the step should succeed
    Given I login via web console
    When I perform the :check_user_name web action with:
      | user_name | <%= user.name .sub("-", "_") %> |
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-10546
  # @note this scenario requires a user that has NOT already subscribed
  Scenario: Check 'Select Plan' page during registration
    Given I open accountant console in a browser
    When I run the :check_pro_plan_info web action
    Then the step should succeed
    When I run the :click_starting_at_fifty_dollars_per_month_button web action
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given the expression should be true> browser.url.end_with? "/app/register/profile"
    """

    When I run the :logout web action
    Then the step should succeed
    When I perform the :login_acc_console web action with:
      | username | <%= user.name %>     |
      | password | <%= user.password %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given the expression should be true> browser.url.end_with? "/app/register/plan"
    """

  # @author etrott@redhat.com
  # @case_id OCP-12751
  # @note this scenario requires a user that HAS already subscribed
  Scenario: Check 'My Account' page - UI
    Given I open accountant console in a browser
    When I perform the :check_account_page web action with:
      | console_url | <%= env.web_console_url %> |
      | email       | <%= user.name %>           |
    Then the step should succeed
