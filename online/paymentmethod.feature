Feature: ONLY payment update related feature's scripts in this file

  # @author yuwan@redhat.com
  # @case_id OCP-14891
  Scenario: Subscription will be re-activated when there's a pending cancellation and then update "Payment Method"
    Given I open accountant console in a browser
    When I run the :click_to_change_plan web action
    Then the step should succeed
    When I run the :click_cancel_your_service web action
    Then the step should succeed
    When I perform the :cancel_your_service_correctly web action with:
      | username | <%= user.name %> |
    Then the step should succeed
    And I register clean-up steps:
    """
    Given I access the "./" url in the web browser
    When I perform the :click_resume_your_subscription_confirm web action with:
      | last_date | <%= last_second_of_month.strftime("%A, %B %d, %Y")%> |
    Then the step should succeed
    """
    When I run the :goto_payment_setting_page web action
    Then the step should succeed
    When I perform the :check_cancellation_warning_message_on_payment_page web action with:
      | last_date | <%= last_second_of_month.strftime("%A, %B %d, %Y")%> |
    Then the step should succeed
    When I perform the :update_payment_method web action with:
      | first_four_number    | 4111 |
      | second_four_number   | 1111 |
      | third_four_number    | 1111 |
      | fourth_four_number   | 1111 |
      | cc_exp_mm_option     | 09   |
      | cc_exp_yyyy_option   | 2023 |
      | security_code_number | 222  |
    Then the step should succeed
    When I run the :check_subscription_resumed_message web action
    Then the step should succeed
    When I run the :click_to_change_plan web action
    Then the step should succeed
    When I run the :click_cancel_your_service web action
    Then the step should succeed
    When I perform the :cancel_your_service_correctly web action with:
      | username | <%= user.name %> |
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-12884
  Scenario: Aria direct post errors are displayed on the payments page
    Given I open accountant console in a browser
    When I run the :goto_payment_setting_page web action
    Then the step should succeed
    When I perform the :input_credit_card_number web action with:
      | first_four_number  | 6228 |
      | second_four_number | 8888 |
      | third_four_number  | 8888 |
      | fourth_four_number | 8888 |
    Then the step should succeed
    When I run the :check_invalid_credit_card_warning_message web action
    Then the step should succeed
    When I perform the :input_credit_card_number web action with:
      | first_four_number  | 6228 |
      | second_four_number | 8888 |
      | third_four_number  | 8888 |
      | fourth_four_number | 8881 |
    Then the step should succeed
    When I run the :check_invalid_credit_card_warning_message web action
    Then the step should fail
    When I perform the :set_the_expiry_date web action with:
      | cc_exp_mm_option   | 10   |
      | cc_exp_yyyy_option | 2033 |
    Then the step should succeed
    When I perform the :input_the_security_code web action with:
      | security_code_number | 456 |
    Then the step should succeed
    When I run the :click_update_payment_method web action
    Then the step should succeed
    When I run the :check_warning_message_for_UnionPay web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-12885
  Scenario: Check error message if input invalid or unsupported credit card
    Given I open accountant console in a browser
    When I run the :goto_payment_setting_page web action
    Then the step should succeed
    When I perform the :input_credit_card_number web action with:
      | first_four_number  | 4123 |
      | second_four_number | 3456 |
      | third_four_number  | 8989 |
      | fourth_four_number | 1123 |
    Then the step should succeed
    When I run the :check_invalid_credit_card_warning_message web action
    Then the step should succeed
    When I perform the :input_credit_card_number web action with:
      | first_four_number  | 5123 |
      | second_four_number | 4567 |
      | third_four_number  | 8919 |
      | fourth_four_number | 1234 |
    Then the step should succeed
    When I run the :check_invalid_credit_card_warning_message web action
    Then the step should succeed
    When I perform the :input_credit_card_number web action with:
      | first_four_number  | 6012 |
      | second_four_number | 3455 |
      | third_four_number  | 6789 |
      | fourth_four_number | 1192 |
    Then the step should succeed
    When I run the :check_invalid_credit_card_warning_message web action
    Then the step should succeed
    When I perform the :input_credit_card_number web action with:
      | first_four_number  | 3411 |
      | second_four_number | 2314 |
      | third_four_number  | 6567 |
      | fourth_four_number | 9819 |
    Then the step should succeed
    When I run the :check_unsupported_credit_card_warning_message web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-14054
  Scenario Outline: The user can update the credit card to a supported one
    Given I open accountant console in a browser
    When I run the :goto_payment_setting_page web action
    Then the step should succeed
    When I perform the :input_credit_card_number web action with:
      | first_four_number  | <first_four>  |
      | second_four_number | <second_four> |
      | third_four_number  | <third_four>  |
      | fourth_four_number | <fourth_four> |
    Then the step should succeed
    When I perform the :check_logo_opacity web action with:
      | logo_no_opacity  | <no_opacity>  |
      | logo_opacity_one | <opacity_one> |
      | logo_opacity_two | <opacity_two> |
    Then the step should succeed
    When I perform the :set_the_expiry_date web action with:
      | cc_exp_mm_option   | <month> |
      | cc_exp_yyyy_option | <year>  |
    Then the step should succeed
    When I perform the :input_the_security_code web action with:
      | security_code_number | <security_code> |
    Then the step should succeed
    When I run the :click_update_payment_method web action
    Then the step should succeed
    When I run the :check_payment_method_update_message web action
    Then the step should succeed
    When I perform the :check_payment_method_on_subscription_page web action with:
      | card_type        | <credit_card> |
      | updated_card_num | <fourth_four> |
      | updated_month    | <month>       |
      | updated_year     | <year>        |
    Then the step should succeed
    When I run the :goto_payment_setting_page web action
    Then the step should succeed
    When I perform the :check_alert_message_on_payment_method_page web action with:
      | card_type        | <credit_card> |
      | updated_card_num | <fourth_four> |
      | updated_month    | <month>       |
      | updated_year     | <year>        |
    Then the step should succeed

    Examples:
    | credit_card | first_four | second_four | third_four | fourth_four | opacity_one   | opacity_two     | no_opacity      | month | year | security_code |
    | MasterCard  | 5454       | 5454        | 5454       | 5454        | logo_visa     | logo_discover   | logo_mastercard | 10    | 2032 | 345           |
    | Discover    | 6511       | 1111        | 1111       | 1112        | logo_visa     | logo_mastercard | logo_discover   | 10    | 2032 | 123           |
    | Visa        | 4111       | 1111        | 1111       | 1111        | logo_discover | logo_mastercard | logo_visa       | 10    | 2032 | 618           |

  # @author yuwan@redhat.com
  # @case_id OCP-14868
  Scenario: Check elements on Payment Method Page - UI
    Given I open accountant console in a browser
    When I run the :goto_payment_setting_page web action
    Then the step should succeed
    When I run the :check_legal_message_on_payment_page web action
    Then the step should succeed
    When I run the :check_update_address_link web action
    Then the step should succeed
    When I run the :check_update_button_disable web action
    Then the step should succeed
    When I run the :check_cancel_button_on_payment_page web action
    Then the step should succeed
