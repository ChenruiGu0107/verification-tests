Feature: sessions related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-12595
  Scenario: Show information about the current session using 'oc whoami'
    When I run the :whoami client command
    Then the output should contain:
      | <%= @user.name %> |
    When I run the :whoami client command with:
      | c ||
    Then the output should contain:
      | <%= env.api_endpoint_url.gsub(%r{https?://},'').gsub('.', '-') %> |
      | <%= user.name %>                                                  |
    When I run the :whoami client command with:
      | t || 
    Then the output should contain:
      | <%= user.cached_tokens[0].token %> |
    When I run the :whoami client command with:
      | invalid_option | true |
    Then the output should contain:
      | Error: unknown shorthand flag: 'b' in -b |
