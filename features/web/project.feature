Feature: projects related features via web

  # @author xxing@redhat.com
  # @case_id 479613
  Scenario: Create a project with a valid project name on web console
    When I perform the :new_project web action with:
      | project_name | <%= rand_str(5, :dns) %> |
      | display_name | test                     |
      | description  | test                     |
    Then the step should succeed
    When I perform the :new_project web action with:
      | project_name | <%= rand_str(63, :dns) %> |
      | display_name | test                      |
      | description  | test                      |
    Then the step should succeed
    When I perform the :new_project web action with:
      | project_name | <%= rand_str(2, :dns) %> |
      | display_name | :null                    |
      | description  ||
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id 481744
  Scenario: Create a project with an invalid name on web console
    Given I login via web console
    When I access the "/console/createProject" path in web console
    Then the step should succeed
    And I get the content of the web element with:
      | type      | button        |
      | selector  | :type=>submit |
      | attribute | disabled      |
    Then the output should contain "true"
    #create the project with a duplicate project name
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I perform the :new_project web action with:
      | project_name | <%= cb.proj_name %> |
      | display_name | :null               |
      | description  ||
    Then the step should succeed
    When I perform the :new_project web action with:
      | project_name | <%= cb.proj_name %> |
      | display_name | :null               |
      | description  ||
    Then the step should fail
    When I get the html of the web page
    Then the output should contain "This name is already in use. Please choose a different name."
    #Create the project with <2 characters name
    When I perform the :new_project web action with:
      | project_name | <%= rand_str(1) %> |
      | display_name | :null              |
      | description  ||
    Then the step should fail
    And I get the content of the web element with:
      | type      | button        |
      | selector  | :type=>submit |
      | attribute | disabled      |
    Then the output should contain "true"
    #.Create the project with uper-case letters
    When I perform the :new_project web action with:
      | project_name | ABCDE |
      | display_name | :null |
      | description  ||
    Then the step should fail
    When I get the html of the web page
    Then the output should contain "Project names may only contain lower-case letters, numbers, and dashes. They may not start or end with a dash."
    When I perform the :new_project web action with:
      | project_name | -<%= rand_str(4,:dns) %> |
      | display_name | :null                    |
      | description  ||
    Then the step should fail
    When I get the html of the web page
    Then the output should contain "Project names may only contain lower-case letters, numbers, and dashes. They may not start or end with a dash."
    When I perform the :new_project web action with:
      | project_name | <%= rand_str(4,:dns) %>- |
      | display_name | :null                    |
      | description  ||
    Then the step should fail
    When I get the html of the web page
    Then the output should contain "Project names may only contain lower-case letters, numbers, and dashes. They may not start or end with a dash."
    When I perform the :new_project web action with:
      | project_name | <%= rand_str(4,:dns) %>#% |
      | display_name | :null                     |
      | description  ||
    Then the step should fail
    When I get the html of the web page
    Then the output should contain "Project names may only contain lower-case letters, numbers, and dashes. They may not start or end with a dash."
