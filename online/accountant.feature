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
      | user_name | <%= user.name.sub("-", "_") %> |
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

  # @author xiaocwan@redhat.com
  # @case_id OCP-15494
  # @note this scenario requires a user that has NOT already subscribed starter
  Scenario: Check 'Select a Plan' page
    Given I open accountant console in a browser
    When I run the :go_to_register_plan web action
    Then the step should succeed
    When I run the :check_free_plan_info web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-19002
  # @note this scenario requires a user who have at least one available pro cluster to resigster
  Scenario: Check Pro plan on 'Select a Plan' page
    Given I open accountant console in a browser
    When I run the :go_to_register_plan web action
    Then the step should succeed
    When I run the :check_pro_plan_info web action
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-12751
  # @note this scenario requires a user that HAS already subscribed
  Scenario: Check 'My Account' page - UI
    Given I open accountant console in a browser
    When I perform the :check_account_page web action with:
      | console_url | <%= env.web_console_url %> |
      | email       | <%= user.name %>           |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-12752
  Scenario: Check 'Manage Subscription' page
    Given I open accountant console in a browser
    When I run the :click_to_change_plan web action
    Then the step should succeed
    When I run the :check_page_logo_banner web action
    Then the step should succeed
    When I run the :check_addon_resources web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-10535
  Scenario: apply account user profile with greeting
    Given I open accountant console in a browser
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Primary |
      | contact          | primary |
      | current_greeting |         |
      | new_greeting     | Mr.     |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Primary |
      | contact          | primary |
      | current_greeting | Mr.     |
      | new_greeting     | Mrs.    |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Primary |
      | contact          | primary |
      | current_greeting | Mrs.    |
      | new_greeting     | Ms.     |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Primary |
      | contact          | primary |
      | current_greeting | Ms.     |
      | new_greeting     | Miss    |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Primary |
      | contact          | primary |
      | current_greeting | Miss    |
      | new_greeting     | Dr.     |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Primary |
      | contact          | primary |
      | current_greeting | Dr.     |
      | new_greeting     | Hr.     |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Primary |
      | contact          | primary |
      | current_greeting | Hr.     |
      | new_greeting     | Sr.     |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Primary |
      | contact          | primary |
      | current_greeting | Sr.     |
      | new_greeting     |         |
    Then the step should succeed

    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Billing |
      | contact          | billing |
      | current_greeting |         |
      | new_greeting     | Mr.     |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Billing |
      | contact          | billing |
      | current_greeting | Mr.     |
      | new_greeting     | Mrs.    |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Billing |
      | contact          | billing |
      | current_greeting | Mrs.    |
      | new_greeting     | Ms.     |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Billing |
      | contact          | billing |
      | current_greeting | Ms.     |
      | new_greeting     | Miss    |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Billing |
      | contact          | billing |
      | current_greeting | Miss    |
      | new_greeting     | Dr.     |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Billing |
      | contact          | billing |
      | current_greeting | Dr.     |
      | new_greeting     | Hr.     |
    Then the step should succeed
    When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Billing |
      | contact          | billing |
      | current_greeting | Hr.     |
      | new_greeting     | Sr.     |
    Then the step should succeed
   When I perform the :update_contact_greeting_on_index_page web action with:
      | contact_cap      | Billing |
      | contact          | billing |
      | current_greeting | Sr.     |
      | new_greeting     |         |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-14283
  Scenario: Update user infomation after plan cancellation
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
      | last_date | <%= last_second_of_month.strftime("%A, %B %d, %Y") %> |
    Then the step should succeed
    When I perform the :update_contact_item_input_on_index_page web action with:
      | contact_cap | Primary        |
      | contact     | primary        |
      | input_id    | middle_initial |
    Then the step should succeed
    When I perform the :update_contact_item_input_on_index_page web action with:
      | contact_cap | Billing        |
      | contact     | billing        |
      | input_id    | middle_initial |
     Then the step should succeed
    """
    When I perform the :update_contact_item_input_on_index_page web action with:
      | contact_cap | Primary        |
      | contact     | primary        |
      | input_id    | middle_initial |
      | text        | p              |
    Then the step should succeed
    When I run the :check_cancel_service_post_message web action
    Then the step should succeed
    When I perform the :update_contact_item_input_on_index_page web action with:
      | contact_cap | Billing        |
      | contact     | billing        |
      | input_id    | middle_initial |
      | text        | b              |
    Then the step should succeed
    When I run the :check_cancel_service_post_message web action
    Then the step should succeed

  # @case_id OCP-10558
  # @note this scenario requires a user who have at least one available pro cluster to resigster
  Scenario: Check expanded countries on Profile page
    Given I open accountant console in a browser
    When I run the :go_to_register_pro_cluster_page web action
    Then the step should succeed

    When I perform the :check_autocomplete_from_country_input web action with:
      | profile      | Primary                              |
      | spelling     | UM                                   |
      | autocomplete | United States Minor Outlying Islands |
    Then the step should succeed
    When I perform the :check_autocomplete_from_country_input web action with:
      | profile      | Primary                  |
      | spelling     | United States            |
      | autocomplete | United States of America |
    Then the step should succeed
    When I perform the :check_autocomplete_from_country_input web action with:
      | profile      | Primary          |
      | spelling     | 中国             |
      | autocomplete | China            |
    Then the step should succeed
    When I perform the :check_autocomplete_from_country_input_nation_code web action with:
      | profile      | Primary         |
      | nation_code  | CZ              |
      | autocomplete | Czechia         |
    Then the step should succeed
    When I perform the :check_autocomplete_from_country_input web action with:
      | profile      | Primary         |
      | spelling     | Česká           |
      | autocomplete | Czechia         |
    Then the step should succeed
    When I perform the :check_autocomplete_from_country_input web action with:
      | profile      | Primary         |
      | spelling     | Беларусь        |
      | autocomplete | Belarus         |
    Then the step should succeed
    When I perform the :check_autocomplete_from_country_input web action with:
      | profile      | Primary         |
      | spelling     | 한국             |
      | autocomplete | Korea           |
    Then the step should succeed
    When I perform the :check_autocomplete_from_country_input web action with:
      | profile      | Primary         |
      | spelling     | Κύπρος          |
      | autocomplete | Cyprus          |
    Then the step should succeed
    When I perform the :check_autocomplete_from_country_input web action with:
      | profile      | Primary         |
      | spelling     | عمان            |
      | autocomplete | Oman            |
    Then the step should succeed
    When I perform the :check_unsupported_country_not_exist web action with:
      | country      | Cuba |
    Then the step should succeed
    When I perform the :check_unsupported_country_not_exist web action with:
      | country      | Iran |
    Then the step should succeed
    When I perform the :check_unsupported_country_not_exist web action with:
      | country      | N. Korea |
    Then the step should succeed
    When I perform the :check_unsupported_country_not_exist web action with:
      | country      | Sudan |
    Then the step should succeed
    When I perform the :check_unsupported_country_not_exist web action with:
      | country      | Syria |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-19429
  # @note this scenario requires a user who have at least one available pro cluster to resigster
  Scenario: Check expanded countries without postcode on Profile page
    Given I open accountant console in a browser
    When I run the :go_to_register_pro_cluster_page web action
    Then the step should succeed
    Given I saved following keys to list in :countries clipboard:
      | Angola  | |
      | Antigua and Barbuda | |
      | Aruba | |
      | Bahamas | |
      | Belize  | |
      | Benin | |
      | Bolivia | |
      | Botswana  | |
      | Burkina Faso  | |
      | Burundi | |
      | Cameroon  | |
      | Central African Republic  | |
      | Comoros | |
      | Congo | |
      | Congo (Democratic Republic of the)  | |
      | Cook Islands  | |
      # #| Cote D | | Bug https://bugzilla.redhat.com/show_bug.cgi?id=1590739
      | Djibouti  | |
      | Dominica  | |
      | Equatorial Guinea | |
      | Eritrea | |
      | Fiji  | |
      | Ghana | |
      | Grenada | |
      | Guinea  | |
      | Guyana  | |
      | Ireland | |
      | Jamaica | |
      | Kenya | |
      | Kiribati  | |
      | Malawi  | |
      | Mali  | |
      | Mauritania  | |
      | Mauritius | |
      | Montserrat  | |
      | Nauru | |
      | Niue  | |
      | Panama  | |
      | Qatar | |
      | Rwanda  | |
      | Saint Kitts and Nevis | |
      | Saint Lucia | |
      | Sao Tome and Principe | |
      | Saudi Arabia  | |
      | Seychelles  | |
      | Sierra Leone  | |
      | Solomon Islands | |
      | Somalia | |
      | South Africa  | |
      | Suriname  | |
      | Tanzania, United Republic of  | |
      | Timor-Leste | |
      | Tokelau | |
      | Tonga | |
      | Trinidad and Tobago | |
      | Tuvalu  | |
      | Uganda  | |
      | United Arab Emirates  | |
      | Vanuatu | |
      | Yemen | |
      | Zimbabwe | |
    When I repeat the following steps for each :country in cb.countries:
    """
    When I perform the :check_country_related_item_hide web action with:
      | country    | #{cb.country}  |
      | item       | data-postcode  |
    Then the step should succeed
    """

  # @author xiaocwan@redhat.com
  # @case_id OCP-19425
  # @note this scenario requires a user who have at least one available pro cluster to resigster
  Scenario: Check expanded countries without subdivision on Profile page
    Given I open accountant console in a browser
    When I run the :go_to_register_pro_cluster_page web action
    Then the step should succeed
    Given I saved following keys to list in :countries clipboard:
      | American Samoa  | |
      | Anguilla  |  |
      | Antarctica  |  |
      | Aruba  |  |
      | Bermuda  |  |
      | Bouvet Island  |  |
      | British Indian Ocean Territory  |  |
      | Cayman Islands  |  |
      | Christmas Island  |  |
      | Cocos (Keeling) Islands  |  |
      | Cook Islands  |  |
      | Falkland Islands (Malvinas)  |  |
      | Faroe Islands  |  |
      | Gibraltar  |  |
      | Greenland  |  |
      | Guadeloupe  |  |
      | Guam  |  |
      | Heard Island and McDonald Islands  |  |
      | Holy See  |  |
      | Martinique  |  |
      | Mayotte  |  |
      | Monaco  |  |
      | Montserrat  |  |
      | New Caledonia  |  |
      | Niue  |  |
      | Norfolk Island  |  |
      | Northern Mariana Islands  |  |
      | Pitcairn  |  |
      | Puerto Rico  |  |
    #  | Reunion  |  | Bug https://bugzilla.redhat.com/show_bug.cgi?id=1590739
      | Saint Lucia  |  |
      | Saint Pierre and Miquelon  |  |
      | Saint Vincent and the Grenadines  |  |
      | South Georgia and the South Sandwich Islands  |  |
      | Svalbard and Jan Mayen  |  |
      | Tajikistan  |  |
      | Tokelau  |  |
      | Turks and Caicos Islands  |  |
      | Virgin Islands (British)  |  |
      | Virgin Islands (U.S.)  |  |
      | Wallis and Futuna  |  |
      | Åland Islands  |  |
    When I repeat the following steps for each :country in cb.countries:
    """
    When I perform the :check_country_related_item_hide web action with:
      | country    | #{cb.country} |
      | item       | data-region   |
    Then the step should succeed
    """

  # @author xiaocwan@redhat.com
  # @case_id OCP-13129
  Scenario: Check contact data format validation
    Given I open accountant console in a browser
    When I run the :go_to_register_pro_cluster_page web action
    Then the step should succeed
    Given I saved following keys to list in :profiles clipboard:
      | Billing  | |
      | Primary  | |
    When I repeat the following steps for each :profile in cb.profiles:
    """
    When I perform the :check_maxlength_or_required web action with:
      | profile   | #{cb.profile}   |
      | name      | first           |
      | maxlength | 32              |
      | required  | yes             |
    Then the step should succeed
    When I perform the :check_maxlength_or_required web action with:
      | profile   | #{cb.profile}   |
      | name      | middle          |
      | maxlength | 1               |
    Then the step should succeed
    When I perform the :check_maxlength_or_required web action with:
      | profile   | #{cb.profile}   |
      | name      | last            |
      | maxlength | 32              |
      | required  | yes             |
    Then the step should succeed
    When I perform the :check_maxlength_or_required web action with:
      | profile   | #{cb.profile}   |
      | name      | address1        |
      | maxlength | 100             |
      | required  | yes             |
    Then the step should succeed
    When I perform the :check_maxlength_or_required web action with:
      | profile   | #{cb.profile}   |
      | name      | address2        |
      | maxlength | 100             |
    Then the step should succeed
    When I perform the :check_maxlength_or_required web action with:
      | profile             | #{cb.profile}   |
      | name                | country         |
      | required_invisible  | yes             |
    Then the step should succeed
    When I perform the :check_maxlength_or_required web action with:
      | profile   | #{cb.profile}   |
      | name      | city            |
      | maxlength | 32              |
      | required  | yes             |
    Then the step should succeed
    When I perform the :check_maxlength_or_required web action with:
      | profile   | #{cb.profile}   |
      | name      | zip             |
      | maxlength | 14              |
      | required  | yes             |
    Then the step should succeed
    When I perform the :check_maxlength_or_required web action with:
      | profile   | #{cb.profile}   |
      | name      | phone           |
      | maxlength | 25              |
    Then the step should succeed
    """
    When I perform the :check_maxlength_or_required web action with:
      | profile   | Primary         |
      | name      | tax             |
      | maxlength | 17              |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-12759
  Scenario: user can change the contact information after pre-populated during registration
    Given I open accountant console in a browser
    When I run the :go_to_register_pro_cluster_page web action
    Then the step should succeed

    ## check select elements on the page - each has at least two options
    When I perform the :check_select_item_have_at_least_two_options web action with:
      | select_id | contact_greeting |
    Then the step should succeed
    When I perform the :check_select_item_have_at_least_two_options web action with:
      | select_id | contact_region |
    Then the step should succeed
    When I perform the :check_select_item_have_at_least_two_options web action with:
      | select_id | billing_greeting |
    Then the step should succeed
    When I perform the :check_select_item_have_at_least_two_options web action with:
      | select_id | billing_region |
    Then the step should succeed

    ## check input box could be edited on the page
    Given I saved following keys to list in :input_ids clipboard:
      | contact_first_name     | |
      | contact_middle_initial | |
      | contact_last_name      | |
      | contact_company_name   | |
      | contact_address1       | |
      | contact_address2       | |
      | contact_address3       | |
      | contact_city           | |
      | contact_phone_number   | |
      | tax_id                 | |
      | billing_first_name     | |
      | billing_middle_initial | |
      | billing_last_name      | |
      | billing_company_name   | |
      | billing_address1       | |
      | billing_address2       | |
      | billing_address3       | |
      | billing_city           | |
      | billing_phone_number   | |
    When I repeat the following steps for each :id in cb.input_ids:
    """
    When I perform the :check_input_could_be_edited_on_current_page web action with:
      | input_id | #{cb.id} |
    Then the step should succeed
    """

  # @author yuwei@redhat.com
  # @case_id OCP-17678
  Scenario: Check the coupon block - UI
    Given I open accountant console in a browser
    When I run the :goto_coupons_webpage web action
    Then the step should succeed
    When I run the :click_apply_new_coupon web action
    Then the step should succeed
    When I run the :check_apply_new_coupon_page web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-19557
  Scenario: Select all button and show count in collaborator manage
    Given I open accountant console in a browser
    When I run the :goto_collaboration_setting_page web action
    Then the step should succeed
    When I perform the :add_collaborator_by_input web action with:
       | username | <%= user(1).name  %> |
    Then the step should succeed
    When I perform the :add_collaborator_by_input web action with:
       | username | <%= user(2).name  %> |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :click_select_all_button web action
    Then the step should succeed
    When I run the :remove_all_collaborator web action
    Then the step should succeed
    When I perform the :check_collaboration_info web action with:
      | total         | 50       |
      | current_used  | 0        |
    Then the step should succeed
    """
    When I perform the :check_collaboration_info web action with:
       | total         | 50      |
       | current_used  | 2       |
    Then the step should succeed
    When I run the :click_select_all_button web action
    Then the step should succeed
    When I run the :click_deselect_all_button web action
    Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-19728
  Scenario: Check nav links to RHD account info
    Given I open accountant console in a browser
    When I run the :check_nav_link web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-19679
  # @note this scenario requires a user who have at least one available pro cluster to resigster
  Scenario: Check the tooltip for County info on registration
    Given I open accountant console in a browser
    When I run the :go_to_register_pro_cluster_page web action
    Then the step should succeed
    When I run the :check_county_info web action

  # @author yuwan@redhat.com
  # @case_id OCP-13183
  # @note this scenario requires a user who have pro cluster(1) left to resigster
  Scenario: check the hint on field frame in Profile page during registration
    Given I open accountant console in a browser
    When I run the :go_to_register_pro_cluster_page web action
    Then the step should succeed
    Given I saved following keys to list in :elementid clipboard:
      | contact_first_name   | |
      | contact_last_name    | |
      | contact_address1     | |
      | contact_city         | |
      | contact_region       | |
      | contact_postcode     | |
      | contact_phone_number | |
      | billing_first_name   | |
      | billing_last_name    | |
      | billing_address1     | |
      | billing_city         | |
      | billing_region       | |
      | billing_postcode     | |
    When I repeat the following steps for each :element_id in cb.elementid:
    """
    When I perform the :check_hint_on_field_frame web action with:
      | checkpoint_id | #{cb.element_id} |
    Then the step should succeed
    """
    When I run the :check_the_hint_on_country_field web action
    Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-15503
  # this case required an account with a Pro plan
  Scenario: Check the account overview page after provisioned on a Pro cluster
    Given I open accountant console in a browser
    When I run the :check_current_plan_content web action
    Then the step should succeed
    And I run the :go_to_account_page web action
    Then the step should succeed
    When I run the :check_open_web_console_link web action
    Then the step should succeed
    When I perform the :check_tooltips_for_pro_memory web action with:
      | cur_resource | Memory |
      | cur_amount   | 2GiB   |
    Then the step should succeed
    When I perform the :check_tooltips_for_persistent_storage web action with:
      | cur_resource | Persistent Storage |
      | cur_amount   | 2GiB               |
    Then the step should succeed
    When I perform the :check_tooltips_for_terminating_memory web action with:
      | cur_resource | Terminating Memory |
      | cur_amount   | 2GiB               |
    Then the step should succeed
    When I run the :check_tooltips_for_pro_support web action
    Then the step should succeed
    And I run the :check_add_a_new_plan web action
    Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-15530
  # This case requires account without any addon
  Scenario Outline: Upgrade/downgrade the resource add-on will refresh the resouce values on the account overview page
    Given I open accountant console in a browser
    # upgrade addon and check
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource   | <resource>   |
      | amount     | <upgrade>    |
    Then the step should succeed
    # reset after all steps
    And I register clean-up steps:
    """
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource   | <resource>   |
      | amount     | 0            |
    Then the step should succeed
    """
    And I run the :go_to_account_page web action
    And I perform the :check_resource_account_overview_page web action with:
      | cur_resource | <cur_resource> |
      | cur_amount   | <upg_total>    |
    Then the step should succeed
    # downgrade and check
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource   | <resource>   |
      | amount     | <downgrade>  |
    Then the step should succeed
    And I run the :go_to_account_page web action
    And I perform the :check_resource_account_overview_page web action with:
      | cur_resource | <cur_resource> |
      | cur_amount   | <dng_total>    |
    Then the step should succeed

    Examples: Upgrade/downgrade the resource add-on will refresh the resouce values on the account overview page
      | resource            | upgrade | downgrade | upg_total  | dng_total  | cur_resource        |
      | memory              | 8       | 4         | 10GiB      | 6GiB       | Memory              |
      | storage             | 8       | 4         | 10GiB      | 6GiB       | Persistent Storage  |
      | terminating_memory  | 8       | 4         | 10GiB      | 6GiB       | Terminating Memory  |

  # @author yuwan@redhat.com
  # @case_id OCP-13491
  Scenario: Check the elements on Primary Contact page - UI	
    Given I open accountant console in a browser
    When I perform the :click_edit_contact web action with:
      | contact_cap | Primary |
      | contact     | primary |
    Then the step should succeed
    Given I saved following keys to list in :elementid clipboard:
      | first_name   | |
      | last_name    | |
      | address1     | |
      | city         | |
      | county       | |
      | postcode     | |
    When I repeat the following steps for each :element_id in cb.elementid:
    """
    When I perform the :check_hint_on_field_frame web action with:
      | checkpoint_id | #{cb.element_id} |
    Then the step should succeed
    """
    Given I saved following keys to list in :input_ids clipboard:
      | first_name     | |
      | middle_initial | |
      | last_name      | |
      | company_name   | |
      | address1       | |
      | address2       | |
      | address3       | |
      | city           | |
      | county         | |
      | postcode       | |
      | phone_number   | |
    When I repeat the following steps for each :id in cb.input_ids:
    """
    When I perform the :check_input_could_be_edited_on_current_page web action with:
      | input_id | #{cb.id} |
    Then the step should succeed
    """
    When I run the :check_country_element_on_primary_contact_page web action
    Then the step should succeed
    When I perform the :check_update_contact_button_initially_disabled web action with:
      | contact_cap | Primary |
    Then the step should succeed
    When I run the :click_cancel_on_primary_and_billing_contact_page web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-20795
  Scenario: Check the elements on Billing Contact page - UI	
    Given I open accountant console in a browser
    When I perform the :click_edit_contact web action with:
      | contact_cap | Billing |
      | contact     | billing |
    Then the step should succeed
    Given I saved following keys to list in :elementid clipboard:
      | first_name   | |
      | last_name    | |
      | address1     | |
      | city         | |
      | county       | |
      | postcode     | |
    When I repeat the following steps for each :element_id in cb.elementid:
    """
    When I perform the :check_hint_on_field_frame web action with:
      | checkpoint_id | #{cb.element_id} |
    Then the step should succeed
    """
    Given I saved following keys to list in :input_ids clipboard:
      | first_name     | |
      | middle_initial | |
      | last_name      | |
      | company_name   | |
      | address1       | |
      | address2       | |
      | address3       | |
      | city           | |
      | county         | |
      | postcode       | |
      | phone_number   | |
    When I repeat the following steps for each :id in cb.input_ids:
    """
    When I perform the :check_input_could_be_edited_on_current_page web action with:
      | input_id | #{cb.id} |
    Then the step should succeed
    """
    When I perform the :check_update_contact_button_initially_disabled web action with:
      | contact_cap | Billing |
    Then the step should succeed
    When I run the :click_cancel_on_primary_and_billing_contact_page web action
    Then the step should succeed
