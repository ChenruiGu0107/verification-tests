Feature: user scope scenarios
  # @author pruan@redhat.com
  # @case_id OCP-10853
  Scenario: Should return 403 when the scope exceed the impersonated user's permission
    Given I have a project
    And I perform the :list_projects rest request with:
      | _header | Impersonate-User=system:serviceaccount:<%= user.name%>:default |
      | _header | Impersonate-User-Scope=role:admin:<%= user.name%>              |
    Then the expression should be true> @result[:exitstatus] == 403


