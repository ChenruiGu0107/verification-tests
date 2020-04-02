Feature: login related scenario

  # @author xiaocwan@redhat.com
  # @case_id OCP-11091
  Scenario: [origin_platformexp_397] The page should not redirect to login page when access /oauth/authorize?client_id=openshift-challenging-client

    Given I login via web console
    When I access the "/oauth/authorize?response_type=token&client_id=openshift-challenging-client" path in the web console
    And I get the html of the web page
    Then the output should contain:
      | A non-empty X-CSRF-Token header is required to receive basic-auth challenges |

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

  # @author yapei@redhat.com
  # @case_id OCP-17141
  Scenario: Check oauth-proxy login ui
    Given I log the message> scenario only works when users are specified with passwords
    Given the master version >= "3.9"
    Given I have a project
    And I login via web console
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/OCP-17421/configmap.yaml |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/OCP-17421/proxy.yaml     |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | app=proxy |
    Given I access the "https://<%= route("proxy", service("proxy")).dns(by: user) %>" url in the web browser
#    Given I wait 30 seconds for the title of the web browser to match "Log In"
    When I perform the :oauth_proxy_login_with_openshift web console action with:
      | username  | <%= user.auth_name %>  |
      | password  | <%= user.password %>   |
    Then the step should succeed
    When I perform the :check_page_contain_text web console action with:
      | text | Hello OpenShift |
    Then the step should succeed

  # @author scheng@redhat.com
  # @case_id OCP-14988
  Scenario: Oauth token should be deleted after web logout
    Given I log the message> this scenario can pass only when user accounts have a known password
    When I perform the :login web console action with:
      | username | <%= user(0).name %>     |
      | password | <%= user(0).password %> |
      | _nologin | true                    |
    Given 15 seconds have passed
    And evaluation of `browser.execute_script("return window.localStorage['LocalStorageUserStore.token']")` is stored in the :token clipboard
    And I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | token           | <%= cb.token %>             |
      | config          | test.config                 |
      | skip_tls_verify | true                        |
    Then the step should succeed
    Given I run the :logout web console action
    Given 20 seconds have passed
    And I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | token           | <%= cb.token %>             |
      | config          | test.config                 |
      | skip_tls_verify | true                        |
    Then the step should fail
