Feature: ONLY Fuse Plan related scripts in this file

  # @author yuwei@redhat.com
  # @case_id OCP-19003
  Scenario: Check Fuse plan on 'Select a Plan' page	
    Given I open accountant console in a browser
    When I run the :go_to_register_plan web action
    Then the step should succeed
    When I run the :check_fuse_small_plan_info web action
    Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-19009
  # @note this Scenario requires a user that already has a fuse plan
  Scenario: Check "Subscription index" page - fuse
    Given I open accountant console in a browser
    When I perform the :check_fuse_subscription_index_page web action with:
      | console_url        | <%= env.web_console_url %> |
      | email              | <%= user.name %>           |
      | integration_number | 5                          |
      | memory             | 8GiB                       |
      | storage            | 5GiB                       |
      | cpu_number         | 16 vCPU                    |
    Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-19014
  # @note this Scenario requires a user that already has a fuse plan
  Scenario: Check the account overview page after provisioned on a fuse cluster	
    Given I open accountant console in a browser
    When I run the :go_to_account_page web action
    Then the step should succeed
    When I perform the :check_fuse_account_overview_page web action with:
      | cpu_number | 16 vCPU |
      | storage    | 5GiB    |
      | memory     | 8GiB    |
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-20440
  Scenario: Check 'Cluster Regions' page during registration - Fuse
    Given I open accountant console in a browser
    When I run the :go_to_fuse_cluster_page web action
    Then the step should succeed
    When I run the :check_fuse_cluster_region_info web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-20445
  Scenario: user can change the contact information after pre-populated during registration - Fuse
    Given I open accountant console in a browser
    When I run the :go_to_register_fuse_profile_page web action
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

  # @author yuwan@redhat.com
  # @case_id OCP-20446
  # @note this scenario requires a user who have pro cluster(1) left to resigster
  Scenario: check the hint on field frame in Profile page during registration - Fuse
    Given I open accountant console in a browser
    When I run the :go_to_register_fuse_profile_page web action
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

  # @author yuwan@redhat.com
  # @case_id OCP-19004
  Scenario: Check the 'Select Fuse Online Plan Size' page		
    Given I open accountant console in a browser
    When I run the :go_to_register_plan web action
    Then the step should succeed
    When I run the :click_starting_at_sixhundredandfifty_dollars_per_month web action
    Then the step should succeed
    When I run the :check_size_page_title_and_description web action
    Then the step should succeed
    When I perform the :check_fuse_small_plan_info_on_size_page web action with:
      | integration_number | 5    |
      | memory             | 8GiB |
      | storage            | 5GiB |
      | cpu_number         | 16   |
    Then the step should succeed
    When I run the :check_small_size_submit_button web action
    Then the step should succeed
    When I run the :click_wizard_item_back_to_plan_page web action
    Then the step should succeed
