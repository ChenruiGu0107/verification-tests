Feature: oc_login.feature

  # @author cryan@redhat.com
  # @case_id 481490
  Scenario: oc login can deal with host which has trailing slash
    When I switch to the first user
    When I run the :login client command with:
      | server   | https://<%= env.master_hosts[0].hostname %>:8443/ |
      | u | <%= @user.name %>     |
      | p | <%= @user.password %> |
    Then the step should succeed
    And the output should contain "Logged into"
