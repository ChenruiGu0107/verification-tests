Feature: login related scenario

  # @author wjiang@redhat.com
  # @case_id OCP-12239
  Scenario: login and logout via web
    Given I login via web console
    Given I run the :logout web console action
    Then the step should succeed
    When I perform the :access_overview_page_after_logout web console action with:
      | project_name | <%= rand_str(2, :dns) %> |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-11091
  Scenario: [origin_platformexp_397] The page should not redirect to login page when access /oauth/authorize?client_id=openshift-challenging-client

    Given I login via web console
    When I access the "/oauth/authorize?response_type=token&client_id=openshift-challenging-client" path in the web console
    And I get the html of the web page
    Then the output should contain:
      | A non-empty X-CSRF-Token header is required to receive basic-auth challenges |

  # @author xxing@redhat.com
  # @case_id OCP-9771
  Scenario: User could not access pages directly without login first
    Given I have a project
    # Disable default login
    When I perform the :new_project_navigate web console action with:
      | _nologin | true |
    Then the step should succeed
    Given I wait for the title of the web browser to match "(Login|Sign\s+in|SSO)"
    When I access the "/console/project/<%= project.name %>/create" path in the web console
    Given I wait for the title of the web browser to match "(Login|Sign\s+in|SSO)"
    When I access the "/console/project/<%= project.name %>/overview" path in the web console
    Given I wait for the title of the web browser to match "(Login|Sign\s+in|SSO)"

  # @author xxing@redhat.com
  # @case_id OCP-12118
  Scenario: The page should reflect to login page when access session protected pages after failed log in
    Given I log the message> this auto script is not suitable for allow_all/github/google auth env
    Given I have a project
    When I perform the :login web console action with:
      | username | <%= rand_str(6, :dns) %> |
      | password | <%= rand_str(6, :dns) %> |
      | _nologin | true                     |
    Then the step should fail
    When I get the html of the web page
    Then the output should contain:
      | Invalid login or password. Please try again |
    When I access the "/console/project/<%= project.name %>/overview" path in the web console
    Given I wait for the title of the web browser to match "Login"
    And the expression should be true> browser.execute_script("return window.localStorage['LocalStorageUserStore.token']") == nil

  # @author xxing@redhat.com
  # @case_id OCP-12189
  Scenario: The page should redirect to login page when access session protected pages after session expired
    When I create a new project via web
    Then the step should succeed
    #make token expired
    And the expression should be true> browser.execute_script("return window.localStorage['LocalStorageUserStore.token']='<%= rand_str(32, :dns) %>';")
    When I access the "/console/project/<%= project.name %>/overview" path in the web console
    Given I wait for the title of the web browser to match "(Login|Sign\s+in|SSO)"
