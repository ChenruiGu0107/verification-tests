Feature: oc_login.feature

  # @author xiaocwan@redhat.com
  # @case_id OCP-10723
  Scenario: Logout of the active session by clearing saved tokens
    Given I log the message> this scenario can pass only when user accounts have a known password
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | u               | <%= user.name %>            |
      | p               | <%= user.password %>        |
      | config          | dummy.kubeconfig            |
      | skip_tls_verify | true                        |
    Then the step should succeed
    When I run the :config client command with:
      | subcommand | view             |
      | config     | dummy.kubeconfig |
    Then the step should succeed
    And the output should contain "token"
    And evaluation of `@result[:response].split("token: ")[1].strip()` is stored in the :token clipboard
    When I run the :get client command with:
      | resource | project          |
      | token    | <%= cb.token %>  |
      | config   | dummy.kubeconfig |
    Then the step should succeed

    When I run the :logout client command with:
      | config   | dummy.kubeconfig |
    Then the step should succeed
    When I run the :config client command with:
      | subcommand | view             |
      | config     | dummy.kubeconfig |
    Then the step should succeed
    And the output should not contain "token"
    # Need wait a moment for server side processing
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | project          |
      | token    | <%= cb.token %>  |
      | config   | dummy.kubeconfig |
    Then the step should fail
    """

  # @author pruan@redhat.com
  # @case_id OCP-11709
  Scenario: Warning should be displayed when login failed via oc login
    When I run the :login client command with:
      | u | <% "" %>            |
      | p | <% user.password %> |
    Then the step should fail
    Then the output should contain "Login failed"
    Given a 5 characters random string is saved into the :rand_str clipboard
    When I run the :login client command with:
      | u | <% user.name %>     |
      | p | <% @cb[:rand_str %> |
    Then the step should fail
    Then the output should contain "Login failed"
    When I run the :login client command with:
      | token | <% @cb[:rand_str %> |
    Then the step should fail
    Then the output should contain "The token provided is invalid or expired"
