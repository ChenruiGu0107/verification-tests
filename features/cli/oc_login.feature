Feature: oc_login.feature

  # @author cryan@redhat.com
  # @case_id 481490
  Scenario: oc login can deal with host which has trailing slash
    When I run the :login client command with:
      | server | https://localhost:8443/ |
    Then the step should succeed
