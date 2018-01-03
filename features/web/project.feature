Feature: projects related features via web

  # @author xxing@redhat.com
  # @case_id OCP-10616
  Scenario Outline: Create a project with a valid project name on web console
    When I perform the :new_project web console action with:
      | project_name | <project_name> |
      | display_name | <display_name> |
      | description  | <display_name> |
    Then the step should succeed
    Examples:
      | project_name              | display_name |
      | <%= rand_str(5, :dns) %>  | test         |
      | <%= rand_str(63, :dns) %> | test         |
      | <%= rand_str(2, :dns) %>  | :null        |

  # @author xxing@redhat.com
  # @case_id OCP-10623
  Scenario: Create a project with an invalid name on web console
    Given I login via web console
    When I run the :create_project_without_filling_any_parameter web console action
    Then the step should succeed
    #create the project with a duplicate project name
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I perform the :new_project web console action with:
      | project_name | <%= cb.proj_name %> |
      | display_name | :null               |
      | description  ||
    Then the step should succeed
    Given I switch to the second user
    When I perform the :new_project web console action with:
      | project_name | <%= cb.proj_name %> |
      | display_name | :null               |
      | description  ||
    Then the step should fail
    When I get the html of the web page
    Then the output should contain "This name is already in use. Please choose a different name."
    # Create a project with <2 characters name
    When I perform the :fail_to_create_new_project web console action with:
      | project_name | <%= rand_str(1) %> |
      | display_name | :null              |
      | description  ||
    Then the step should succeed
    When I run the :get_disabled_project_submit_button web console action
    Then the step should succeed
    # Create a project with uper-case letters
    When I perform the :fail_to_create_new_project web console action with:
      | project_name | ABCDE |
      | display_name | :null |
      | description  ||
    Then the step should succeed
    When I run the :confirm_error_for_invalid_project_name web console action
    Then the step should succeed
    When I perform the :fail_to_create_new_project web console action with:
      | project_name | -<%= rand_str(4,:dns) %> |
      | display_name | :null                    |
      | description  ||
    Then the step should succeed
    When I run the :confirm_error_for_invalid_project_name web console action
    Then the step should succeed
    When I perform the :fail_to_create_new_project web console action with:
      | project_name | <%= rand_str(4,:dns) %>- |
      | display_name | :null                    |
      | description  ||
    Then the step should succeed
    When I run the :confirm_error_for_invalid_project_name web console action
    Then the step should succeed
    When I perform the :fail_to_create_new_project web console action with:
      | project_name | <%= rand_str(4,:dns) %>#% |
      | display_name | :null                     |
      | description  ||
    Then the step should succeed
    When I run the :confirm_error_for_invalid_project_name web console action
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-9613
  Scenario: Could delete project from web console
    When I create a project via web with:
      | display_name | :null |
      | description  ||
    Then the step should succeed
    When I run the :new_app client command with:
      | image_stream | openshift/php:latest                    |
      | code         | https://github.com/openshift/cakephp-ex |
      | name         | php-sample                              |
    Then the step should succeed
    Given the "php-sample-1" build was created
    When I perform the :cancel_delete_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain "<%= project.name %>"
    When I perform the :delete_project web console action with:
      | project_name | <%= project.name %> |
      | input_str    | <%= project.name %> |
    Then the step should succeed
    Given I wait for the resource "project" named "<%= project.name %>" to disappear
    When I run the :check_project_list web console action
    Then the step should fail
    Given I wait for the :new_project web console action to succeed with:
      | project_name | <%= project.name %> |
      | display_name | :null               |
      | description  ||
    When I perform the :check_project_overview_without_resource web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :delete_project web console action with:
      | project_name | <%= project.name %> |
      | input_str    | <%= project.name %> |
    Then the step should succeed
    Given I wait for the resource "project" named "<%= project.name %>" to disappear
    When I run the :check_project_list web console action
    Then the step should fail
    Given I create a new project
    When I run the :policy_add_role_to_user client command with:
      | role      | edit            |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed
    And I run the :policy_add_role_to_user client command with:
      | role      | view                |
      | user_name | <%= user(2, switch: false).name %>    |
    Given I switch to the second user
    When I perform the :delete_project web console action with:
      | project_name | <%= project.name %> |
      | input_str    | <%= project.name %> |
    And I get the html of the web page
    Then the output should contain:
      | User "<%= user.name %>" cannot delete projects in project "<%= project.name %>" |
    Given I switch to the third user
    When I perform the :delete_project web console action with:
      | project_name | <%= project.name %> |
      | input_str    | <%= project.name %> |
    And I get the html of the web page
    Then the output should contain:
      | User "<%= user.name %>" cannot delete projects in project "<%= project.name %>" |

  # @author wsun@redhat.com
  # @case_id OCP-12440
  Scenario: Could list all projects based on the user's authorization on web console
    Given an 8 characters random string of type :dns is stored into the :project1 clipboard
    Given an 8 characters random string of type :dns is stored into the :project2 clipboard
    Given an 8 characters random string of type :dns is stored into the :project3 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.project1 %> |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | <%= cb.project3 %> |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role  | view     |
      | user_name | <%= user(1, switch: false).name %> |
      | namespace |  <%= cb.project1 %>  |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role  | view     |
      | user_name | <%= user(1, switch: false).name %> |
      | namespace |  <%= cb.project2 %>  |
    Given I switch to the second user
    When I perform the :check_specific_project web console action with:
      | project_name | <%= cb.project1 %> |
    Then the step should succeed
    When I perform the :check_specific_project web console action with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    When I perform the :check_specific_project web console action with:
      | project_name | <%= cb.project3 %> |
    Then the step should fail
    Given I switch to the first user
    When I run the :policy_remove_role_from_user client command with:
      | role | view |
      | user_name | <%= user(1, switch: false).name %> |
      | namespace |  <%= cb.project2 %>  |
    Then the step should succeed
    Given I switch to the second user
    When I perform the :check_specific_project web console action with:
      | project_name | <%= cb.project1 %> |
    Then the step should succeed
    When I perform the :check_specific_project web console action with:
      | project_name | <%= cb.project2 %> |
    Then the step should fail
    When I perform the :check_specific_project web console action with:
      | project_name | <%= cb.project3 %> |
    Then the step should fail

  # @author wsun@redhat.com
  # @case_id OCP-9614
  Scenario: Can edit the project description and display name from web console
    When I create a project via web with:
      | display_name | projecttest |
      | description  | test        |
    Then the step should succeed
    When I perform the :check_general_information web console action with:
      | project_name | <%= project.name %> |
      | display_name | projecttest         |
      | description  | test                |
    Then the step should succeed
    When I perform the :cancel_edit_general_informantion web console action with:
      | project_name     | <%= project.name %> |
      | display_name     | projecttest         |
      | description      | test                |
      | new_display_name | projecttestupdate   |
      | new_description  | testupdate          |
    Then the step should succeed
    When I perform the :save_edit_general_informantion web console action with:
      | project_name     | <%= project.name %> |
      | display_name     | projecttestupdate   |
      | description      | testupdate          |
      | new_display_name | projecttestupdate   |
      | new_description  | testupdate          |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                                |
      | user_name |  <%= user(1, switch: false).name %> |
      | n         | <%= project.name %>                 |
    Given I switch to the second user
    When I perform the :check_general_information web console action with:
      | project_name | <%= project.name %> |
      | display_name | projecttestupdate   |
      | description  | testupdate          |
    Then the step should succeed
    When I perform the :save_edit_general_informantion web console action with:
      | project_name     | <%= project.name %> |
      | display_name     | projecttestupdate   |
      | description      | testupdate          |
      | new_display_name | projecttesteditor   |
      | new_description  | testeditor          |
    Then the step should succeed
    When I perform the :check_general_information web console action with:
      | project_name | <%= project.name %> |
      | display_name | projecttestupdate   |
      | description  | testupdate          |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-10014
  Scenario: Delete project from web console
    # delete project with project name on projects page
    When I create a project via web with:
      | display_name | testing project one |
      | description  ||
    Then the step should succeed
    When I perform the :type_project_delete_string web console action with:
      | project_name | testing project one      |
      | input_str    | <%= rand_str(7, :dns) %> |
    Then the step should succeed
    When I run the :check_delete_button_for_project_deletion web console action
    Then the step should fail
    When I perform the :delete_project web console action with:
      | project_name | testing project one |
      | input_str    | <%= project.name %> |
    Then the step should succeed
    Given I wait for the resource "project" named "<%= project.name %>" to disappear
    # delete project with project display name
    When I create a project via cli with:
      | display_name | testing project two |
    Then the step should succeed
    When I perform the :cancel_delete_project web console action with:
      | project_name | testing project two |
    Then the step should succeed
    When I perform the :delete_project web console action with:
      | project_name | testing project two |
      | input_str    | testing project two |
    Then the step should succeed
    Given I wait for the resource "project" named "<%= project.name %>" to disappear

  # @author xiaocwan@redhat.com
  # @case_id OCP-15256
  Scenario: Use kebab to create/edit project on project list page
    Given the master version >= "3.7"
    When I run the :goto_project_list_page web console action
    Then the step should succeed
    Given a 5 characters random string of type :dns is stored into the :project_name clipboard
    When I perform the :create_project_on_project_list_page web console action with:
      | project_name | <%= cb.project_name %>             |
      | display_name | <%= cb.project_name %>_display     |
      | description  | <%= cb.project_name %>_description |
    Then the step should succeed
    When I run the :goto_project_list_page web console action
    Then the step should succeed
    When I perform the :edit_save_for_project_in_project_list_kebab web console action with:
      | project_name | <%= cb.project_name %>        |
      | display_name | <%= cb.project_name %>_update |
      | description  | <%= cb.project_name %>_update |
    Then the step should succeed