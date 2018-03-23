Feature: create app on web console related


  # @author hasha@redhat.com
  # @case_id OCP-13718
  Scenario: Create and view advanced options while creating/selecting project from homepage
    # since it's 3.6 tech preview, no scripts for 3.6
    Given the master version >= "3.6"
    When I run the :goto_home_page web console action
    Then the step should succeed
    When I perform the :select_service_to_order_from_catalog web console action with:
      | primary_catagory | Languages |
      | sub_catagory     | Python    |
      | service_item     | Python    |
    Then the step should succeed
    When I run the :click_next_button web console action
    Then the step should succeed
    # Create first project while creating app
    When I perform the :do_configuration_step_in_wizard web console action with:
      | create_project | true      |
      | project_name   | testpro   |
      | app_name       | pythonapp |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :check_successful_result_info_in_wizard web console action with:
      | project_name   | testpro   |
    Then the step should succeed
    When I perform the :check_goto_overview_page_link_in_wizard web console action with:
      | project_name | testpro |
    Then the step should succeed
    When I run the :goto_home_page web console action
    Then the step should succeed
    # add app to existing project
    When I perform the :select_service_to_order_from_catalog web console action with:
      | primary_catagory | Languages |
      | sub_catagory     | Ruby      |
      | service_item     | Ruby      |
    Then the step should succeed
    When I run the :click_next_button web console action
    Then the step should succeed
    When I perform the :do_configuration_step_in_wizard web console action with:
      | create_project | false     |
      | project_name   | testpro   |
      | app_name       | rubyapp   |
    Then the step should succeed
    When I perform the :check_advanced_options_link_in_wizard web console action with:
      | service_item   | Ruby      |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    When I run the :check_successful_result_info_on_next_step_page web console action
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-13996
  Scenario: Check ordering process for builder image
    # since it's 3.6 tech preview, no scripts for 3.6
    Given the master version >= "3.6"
    Given I have a project
    When I run the :goto_home_page web console action
    Then the step should succeed
    When I perform the :select_service_to_order_from_catalog web console action with:
      | primary_catagory | Languages |
      | sub_catagory     | Ruby      |
      | service_item     | Ruby      |
    Then the step should succeed
    When I run the :click_next_button web console action
    Then the step should succeed
    When I perform the :set_app_name_in_wizard web console action with:
      | app_name | a@@  |
    Then the step should succeed
    When I run the :click_somewhere_out_of_focus_for_wizard web console action
    Then the step should succeed
    When I run the :check_app_name_pattern_error_from_catalog web console action
    Then the step should succeed
    When I run the :check_create_button_disabled web console action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-15453
  Scenario: Secret can be viewed from the results step of Create Binding dialog
    # since it's 3.6 tech preview, no scripts for 3.6, need TSB running
    Given the master version >= "3.6"
    Given I have a project
    When I run the :goto_home_page web console action
    Then the step should succeed
    # check secret is shown when provision from homepage wizard
    When I perform the :provision_serviceclass_with_binding_and_wait_secret_shown web console action with:
      | primary_catagory | Databases           |
      | sub_catagory     | Mongo               |
      | service_item     | MongoDB (Ephemeral) |
    Then the step should succeed
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance |
    Then the output should match "Message..*instance was provisioned successfully"
    When I run the :describe client command with:
      | resource | servicebinding |
    Then the output should match "Message.*njected bind result"
    """
    When I run the :wait_secret_showing_in_successful_result web console action
    Then the step should succeed
    When I run the :click_close web console action
    Then the step should succeed
    # check secret is shown when create binding from overview
    When I perform the :create_binding_on_overview_page web console action with:
      | project_name  | <%= project.name %> |
      | resource_name | MongoDB             |
    Then the step should succeed
    Given I wait up to 10 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding |
    Then the output should match 2 times:
      | Message.*njected bind result |
    """
    When I run the :wait_secret_showing_in_successful_result web console action
    Then the step should succeed
