Feature: scenarios related to catalog page

  # @author chali@redhat.com
  # @case_id OCP-11675
  Scenario: Don't show hidden image stream tags in the catalog
    Given the master version >= "3.5"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json |
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | istag |
    Then the output should contain:
      | ruby:2.2 |
    """
    When I run the :patch client command with:
      | resource      | istag                                                       |
      | resource_name | ruby:2.2                                                    |
      | p             | {"metadata":{"annotations":{"tags":"hidden,builder,ruby"}}} |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :click_add_to_project_from_catalog web console action
    Then the step should succeed
    When I perform the :select_category_in_catalog web console action with:
      | category | Ruby |
    Then the step should succeed
    When I perform the :select_card_version_in_catalog web console action with:
      | card_name | Ruby                |
      | namespace | <%= project.name %> |
      | version   | latest              |
    Then the step should succeed
    When I perform the :check_card_version_missing_in_catalog web console action with:
      | card_name | Ruby                |
      | namespace | <%= project.name %> |
      | version   | 2.2                 |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-13722
  Scenario: Project guide tour message and order
    Given the master version >= "3.6"
    ## Start tour by getting started section
    When I run the :click_tour_button_on_home_page web console action
    Then the step should succeed
    ## From first message to last message check all text and buttons, click Next and Done buttons
    When I perform the :go_tour_guide_steps_and_check_messages web console action with:
      | step_number | 1 |
    Then the step should succeed
    When I perform the :go_tour_guide_steps_and_check_messages web console action with:
      | step_number | 2 |
    Then the step should succeed
    When I perform the :go_tour_guide_steps_and_check_messages web console action with:
      | step_number | 3 |
    Then the step should succeed
    When I perform the :go_tour_guide_steps_and_check_messages web console action with:
      | step_number | 4 |
    Then the step should succeed
    When I perform the :go_tour_guide_steps_and_check_messages web console action with:
      | step_number | 5 |
    Then the step should succeed
    When I perform the :go_tour_guide_steps_and_check_messages web console action with:
      | step_number | 6 |
    Then the step should succeed

    ## start tour by top-right drop-down button
    When I run the :click_tour_from_helper web console action
    Then the step should succeed
    ## check clicking Back button, clicking close button
    When I perform the :go_tour_guide_steps_and_check_messages web console action with:
      | step_number | 1 |
    Then the step should succeed
    When I run the :check_tour_2nd_step_message_and_go_back web console action
    Then the step should succeed
    When I perform the :go_tour_guide_steps_and_check_messages web console action with:
      | step_number | 1 |
    Then the step should succeed
    When I run the :click_close_x web console action
    Then the step should succeed
    When I perform the :check_message_step_missing web console action with:
      | step_number | 1 |

  # @author yanpzhan@redhat.com
  # @case_id OCP-15066
  Scenario: Catalog should include template from another project
    Given the master version >= "3.7"
    When I run the :click_select_from_project web console action
    Then the step should succeed
    When I perform the :check_text_in_wizard web console action with:
      | text | No Available Projects |
    Then the step should succeed
    When I run the :click_cancel web console action
    Then the step should succeed

    Given I have a project
    And I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    And I create a new project

    When I perform the :check_project_number_on_home_page web console action with:
      | project_number | 2 |
    Then the step should succeed
    When I run the :click_select_from_project web console action
    Then the step should succeed
    When I perform the :check_text_in_wizard web console action with:
      | text | No Project Selected |
    Then the step should succeed
    When I run the :click_select_a_project_dropdown_list_in_wizard web console action
    Then the step should succeed
    When I perform the :select_existing_project_in_dropdown web console action with:
      | project_name | <%= project(1, switch: false).name %> |
    Then the step should succeed
    When I perform the :check_text_in_wizard web console action with:
      | text | No Templates |
    Then the step should succeed

    When I run the :click_select_a_project_dropdown_list_in_wizard web console action
    Then the step should succeed
    When I perform the :select_existing_project_in_dropdown web console action with:
      | project_name | <%= project(0, switch: false).name %> |
    Then the step should succeed
    When I perform the :check_resource_item_in_wizard web console action with:
      | item_name | ruby-helloworld-sample |
    Then the step should succeed

    When I perform the :filter_by_keywords web console action with:
      | keyword     | php    |
      | press_enter | :enter |
    Then the step should succeed
    When I perform the :check_resource_item_not_in_wizard web console action with:
      | item_name | ruby-helloworld-sample |
    Then the step should succeed

    When I run the :clear_all_filters web console action
    Then the step should succeed

    When I perform the :create_app_with_template_from_user_project web console action with:
      | project_name   | <%= project(1, switch: false).name %> |
      | template_name  | ruby-helloworld-sample                |
      | create_project | false                                 |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-16665
  Scenario: Browse catalog and quick search from within a project
    Given the master version >= "3.9"
    Given I have a project
    # search catalog item by a page in project
    When I perform the :search_catalog_from_project_page web console action with:
      | project_name | <%= project.name %> |
      | keyword      | python              |
      | number       | 3                   |
    Then the step should succeed
    # check page direct to Catalog
    And the expression should be true> browser.url.end_with? "/catalog?filter=python"
    When I perform the :check_catalog_page_title_and_first_level_menu web console action with:
      | menu_name | Catalog |
    Then the step should succeed
    # only check overlay panel shows
    When I perform the :select_service_from_catalog_and_cancel web console action with:
      | service_item     | Python |
    Then the step should succeed
    # check page direct to Catalog by clicking browse catalog in project
    When I perform the :browse_catalog_from_project_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    And the expression should be true> browser.url.end_with? "/catalog"
    When I perform the :filter_by_keywords web console action with:
      | keyword     | ruby   |
      | press_enter | :enter |
    When I perform the :check_service_item_from_catalog web console action with:
      | service_item | Ruby |
    Then the step should succeed
