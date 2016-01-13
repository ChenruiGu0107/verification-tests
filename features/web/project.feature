Feature: projects related features via web

  # @author xxing@redhat.com
  # @case_id 479613
  Scenario: Create a project with a valid project name on web console
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(5, :dns) %> |
      | display_name | test                     |
      | description  | test                     |
    Then the step should succeed
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(63, :dns) %> |
      | display_name | test                      |
      | description  | test                      |
    Then the step should succeed
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(2, :dns) %> |
      | display_name | :null                    |
      | description  ||
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id 481744
  Scenario: Create a project with an invalid name on web console
    Given I login via web console
    When I access the "/console/createProject" path in the web console
    Then the step should succeed
    When I get the "disabled" attribute of the "button" web element:
      | type | submit |
    Then the output should contain "true"
    #create the project with a duplicate project name
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I perform the :new_project web console action with:
      | project_name | <%= cb.proj_name %> |
      | display_name | :null               |
      | description  ||
    Then the step should succeed
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
    When I get the "disabled" attribute of the "button" web element:
      | type | submit |
    Then the output should contain "true"
    # Create a project with uper-case letters
    When I perform the :new_project web console action with:
      | project_name | ABCDE |
      | display_name | :null |
      | description  ||
    Then the step should fail
    When I get the html of the web page
    Then the output should contain "Project names may only contain lower-case letters, numbers, and dashes. They may not start or end with a dash."
    When I perform the :new_project web console action with:
      | project_name | -<%= rand_str(4,:dns) %> |
      | display_name | :null                    |
      | description  ||
    Then the step should fail
    When I get the html of the web page
    Then the output should contain "Project names may only contain lower-case letters, numbers, and dashes. They may not start or end with a dash."
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(4,:dns) %>- |
      | display_name | :null                    |
      | description  ||
    Then the step should fail
    When I get the html of the web page
    Then the output should contain "Project names may only contain lower-case letters, numbers, and dashes. They may not start or end with a dash."
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(4,:dns) %>#% |
      | display_name | :null                     |
      | description  ||
    Then the step should fail
    When I get the html of the web page
    Then the output should contain "Project names may only contain lower-case letters, numbers, and dashes. They may not start or end with a dash."

  # @author xxing@redhat.com
  # @case_id 499989
  Scenario: Could delete project from web console
    Given I login via web console
    Given I switch to the second user
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
    When I perform the :cancel_delete_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain "<%= project.name %>"
    When I perform the :delete_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_project_list web console action 
    Then the step should fail
    When I perform the :new_project web console action with:
      | project_name | <%= project.name %> |
      | display_name | :null               |
      | description  ||
    Then the step should succeed
    When I perform the :check_project_overview_without_resource web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :delete_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_project_list web console action
    Then the step should fail
    Given I create a new project
    When I run the :policy_add_role_to_user client command with:
      | role      | edit            |
      | user_name | <%= user(0, switch: false).name %> |
    Then the step should succeed
    Given I switch to the first user
    When I perform the :delete_project web console action with:
      | project_name | <%= project.name %> |
    And I get the html of the web page
    Then the output should contain:
      | User "<%= user(0).name %>" cannot delete projects in project "<%= project.name %>" |
    Given I switch to the second user
    When I run the :policy_add_role_to_user client command with:
      | role      | view                |
      | user_name | <%= user(0, switch: false).name %> |
    Given I switch to the first user
    When I perform the :delete_project web console action with:
      | project_name | <%= project.name %> |
    And I get the html of the web page
    Then the output should contain:
      | User "<%= user(0).name %>" cannot delete projects in project "<%= project.name %>" |
