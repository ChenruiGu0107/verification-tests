Feature: login related scenario
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
