Feature: projects related features via web

  # @author xxing@redhat.com
  # @case_id 479613
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
  # @case_id 481744
  Scenario: Create a project with an invalid name on web console
    Given I login via web console
    When I access the "/console/createProject" path in the web console
    Then the step should succeed
    When I run the :get_disabled_project_submit_button web console action
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
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(1) %> |
      | display_name | :null              |
      | description  ||
    Then the step should fail
    When I run the :get_disabled_project_submit_button web console action
    Then the step should succeed
    # Create a project with uper-case letters
    When I perform the :new_project web console action with:
      | project_name | ABCDE |
      | display_name | :null |
      | description  ||
    Then the step should fail
    When I run the :confirm_error_for_invalid_project_name web console action
    Then the step should succeed
    When I perform the :new_project web console action with:
      | project_name | -<%= rand_str(4,:dns) %> |
      | display_name | :null                    |
      | description  ||
    Then the step should fail
    When I run the :confirm_error_for_invalid_project_name web console action
    Then the step should succeed
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(4,:dns) %>- |
      | display_name | :null                    |
      | description  ||
    Then the step should fail
    When I run the :confirm_error_for_invalid_project_name web console action
    Then the step should succeed
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(4,:dns) %>#% |
      | display_name | :null                     |
      | description  ||
    Then the step should fail
    When I run the :confirm_error_for_invalid_project_name web console action
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id 499989
  Scenario: Could delete project from web console
    When I create a project via web with:
      | display_name | :null |
      | description  ||
    Then the step should succeed
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>   |
      | image_name   | php                   |
      | image_tag    | 5.5                   |
      | namespace    | openshift             |
      | app_name     | php-sample            |
      | source_url   | https://github.com/openshift/cakephp-ex.git |
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
  # @case_id 470313
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
  # @case_id 499992
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
  # @case_id 528311
  Scenario: Delete project from web console
    # delete project with project name on /console page
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
    When I run the :get client command with:
      | resource | project |
    Then the step should succeed
    And the output should not contain:
      | testing project one |
      | <%= project.name %> |
    # delete project with project display name
    When I create a project via web with:
      | display_name | testing project two |
      | description  ||
    Then the step should succeed
    When I perform the :cancel_delete_project web console action with:
      | project_name | testing project two |
    Then the step should succeed
    When I perform the :delete_project web console action with:
      | project_name | testing project two |
      | input_str    | testing project two |
    Then the step should succeed
    Given I wait for the resource "project" named "<%= project.name %>" to disappear
    When I run the :get client command with:
      | resource | project |
    Then the step should succeed
    And the output should not contain:
      | testing project two |
      | <%= project.name %> |

  # @author etrott@redhat.com
  # @case_id 536573
  Scenario: Manage project membership about groups
    Given the master version >= "3.4"
    When I create a new project via web
    Then the step should succeed

    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Groups              |
      | count        | 0                   |
    Then the step should succeed
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Groups              |
      | name         | test_group          |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Groups              |
      | name         | test_group          |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Groups              |
      | count        | 1                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should contain:
      | test_group |
    When I perform the :delete_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Groups              |
      | name         | test_group          |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Groups              |
      | count        | 0                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should not contain:
      | test_group |

    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %>                        |
      | tab_name     | System Groups                              |
      | name         | system:serviceaccounts:<%= project.name %> |
      | role         | system:image-puller                        |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | System Groups       |
      | count        | 1                   |
    Then the step should succeed
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | System Groups       |
      | name         | test_group          |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | System Groups       |
      | count        | 2                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should contain:
      | system:test_group |
    When I perform the :delete_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | System Groups       |
      | name         | system:test_group   |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | System Groups       |
      | count        | 1                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should not contain:
      | system:test_group |

  # @author etrott@redhat.com
  # @case_id 536574
  Scenario: Manage project membership about users
    Given the master version >= "3.4"
    When I create a new project via web
    Then the step should succeed

    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | <%= user.name %>    |
      | role         | admin               |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | count        | 1                   |
    Then the step should succeed
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | test_user           |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | test_user           |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | count        | 2                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should contain:
      | test_user |
    When I perform the :delete_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | test_user           |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | count        | 1                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should not contain:
      | test_user |

    When I perform the :check_entry_content_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %>  |
      | tab_name     | Service Accounts     |
      | namespace    | <%= project.name %>  |
      | name         | builder              |
      | role         | system:image-builder |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | <%= project.name %> |
      | name         | deployer            |
      | role         | system:deployer     |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | count        | 2                   |
    Then the step should succeed
    When I perform the :add_role_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | <%= project.name %> |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | <%= project.name %> |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | count        | 3                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should contain:
      | test.sa |
    When I perform the :delete_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | <%= project.name %> |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | count        | 2                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should not contain:
      | test.sa |

    When I perform the :add_role_on_membership_with_typed_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | default             |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | default             |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | count        | 3                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should contain:
      | test.sa |
    When I perform the :delete_role_on_membership_with_namespace web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | namespace    | default             |
      | name         | test.sa             |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Service Accounts    |
      | count        | 2                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should not contain:
      | test.sa |

    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | System Users        |
      | name         | test_user           |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | System Users        |
      | count        | 1                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should contain:
      | system:test_user |
    When I perform the :delete_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | System Users        |
      | name         | system:test_user    |
      | role         | basic-user          |
    Then the step should succeed
    When I perform the :check_tab_count_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | System Users        |
      | count        | 0                   |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | basic-user  |
    Then the output should not contain:
      | system:test_user |

  # @author etrott@redhat.com
  # @case_id 536576
  Scenario: Check rolebinding duplication when editing membership
    Given the master version >= "3.4"
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role            |   view                |
      | user name       |   star                |
      | n               |   <%= project.name %> |
    Then the step should succeed
    And I run the :export client command with:
      | resource      | rolebinding |
      | name          | view        |
    Then the step should succeed
    And I save the output to file> rolebinding_view.yaml
    When I run oc create over "rolebinding_view.yaml" replacing paths:
      | ["metadata"]["name"] | view2nd |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
    Then the output should contain:
      | view2nd |
    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | star                |
      | role         | view                |
    Then the step should succeed
    When I perform the :check_entry_content_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | star                |
      | role         | view2nd             |
    Then the step should fail

    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | bob           |
      | role         | view          |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
    Then the output should contain:
      | bob |
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | Users               |
      | name         | bob           |
      | role         | view          |
    Then the step should succeed
    When I perform the :check_error_message_on_membership web console action with:
      | name | bob  |
      | role | view |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | rolebinding |
    Then the output should not contain 2 times:
      | bob |
