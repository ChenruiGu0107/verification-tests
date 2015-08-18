Feature: sessions realated scenarios
  # @author pruan@redhat.com
  # @case_id 488991
  Scenario: Show information about the current session using 'oc whoami'
    When I run the :whoami client command
    Then the output should contain:
      | <%= @user.name %> |
    When I run the :whoami client command with:
      | context | true |
    Then the output should contain:
      | <%= user.env.hosts[0].hostname.gsub('.', '-') + ":8443/" + user.name %> |
    When I run the :whoami client command with:
      | token | true |
    Then the output should contain:
      | <%= user.cached_tokens[0].token %> |
    When I run the :whoami client command with:
      | invalid_option | true |
    Then the output should contain:
      | Error: unknown shorthand flag: 'b' in -b |
      | Run 'oc help' for usage.                 |
