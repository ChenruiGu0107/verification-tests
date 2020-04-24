Feature: oc_login.feature
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
