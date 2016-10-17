Feature: ONLY ONLINE Login related scripts in this file

  # @author etrott@redhat.com
  # @case_id 534613
  Scenario: The page should redirect to login page when access session protected pages after failed log in
    Given I have a project
    When I perform the :login_token web console action with:
      | token    | <%= rand_str(43, :dns) %> |
    Then the step should fail
    When I get the html of the web page
    Then the output should contain:
      | An error has occurred |
    When I access the "/console/project/<%= project.name %>/overview" path in the web console
    Given I wait for the title of the web browser to match "Login"
    And the expression should be true> browser.execute_script("return window.localStorage['LocalStorageUserStore.token']") == nil
