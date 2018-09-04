Feature: secrets related

  # @author yapei@redhat.com
  # @case_id OCP-20236
  Scenario: Webhook Secret
    Given I have a project
    Given an 16 character random string of type :dns is stored into the :webhook_skey clipboard
    And I open admin console in a browser
    
    # create secret with manual input
    When I perform the :create_secret web action with:
      | project_name        | <%= project.name %>    |
      | secret_type         | webhook                |
      | secret_name         | webhooksecret1         |
      | webhook_secret_type | manually_set           |
      | webhook_secret_key  | <%= cb.webhook_skey %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | secret/webhooksecret1 |
    Then the step should succeed
    And the output should match:
      | [Tt]ype.*Opaque    |
      | WebHookSecretKey.* |
    
    # create secret with generated data
    When I perform the :create_secret web action with:
      | project_name        | <%= project.name %>    |
      | secret_type         | webhook                |
      | secret_name         | webhooksecret2         |
      | webhook_secret_type | generate               |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | secret/webhooksecret2 |
    Then the step should succeed
    And the output should match:
      | [Tt]ype.*Opaque    |
      | WebHookSecretKey.* |
    
    # Reveal/Hide could show/hide secret data
    When I perform the :goto_one_secret_page web action with:
      | project_name        | <%= project.name %>    |
      | secret_name         | webhooksecret1         |
    Then the step should succeed
    When I run the :click_reveal_values web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | <%= cb.webhook_skey %> |
    Then the step should succeed
    When I run the :click_hide_values web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | <%= cb.webhook_skey %> |
    Then the step should fail

  # @author yapei@redhat.com
  # @case_id OCP-20020
  Scenario: Source Secret
    Given I have a project
    And I open admin console in a browser

    # create source secret with u/p
    When I perform the :create_secret web action with:
      | project_name       | <%= project.name %>    |
      | secret_type        | source                 |
      | secret_name        | sourcesecret1          |
      | auth_type          | Basic Authentication   |
      | username           | testuser               |
      | password_or_token  | testpass               |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | secret/sourcesecret1 |
    Then the step should succeed
    And the output should match:
      | [Tt]ype.*kubernetes.io/basic-auth    |    
    When I perform the :goto_one_secret_page web action with:
      | project_name    | <%= project.name %>  |
      | secret_name     | sourcesecret1        |
    Then the step should succeed
    When I perform the :check_secret_type web action with:
      | secret_type | kubernetes.io/basic-auth |
    Then the step should succeed

    # create source secret only with token
    When I perform the :create_secret web action with:
      | project_name        | <%= project.name %>    |
      | secret_type         | source                 |
      | secret_name         | sourcesecret2          |
      | auth_type           | Basic Authentication   |
      | password_or_token   | testpass               |
    Then the step should succeed
    When I run the :get client command with:
      | resource | secret |
    Then the step should succeed
    And the output should contain:
      | sourcesecret2 |

    # create ssh key type secret
    When I perform the :create_secret web action with:
      | project_name        | <%= project.name %>    |
      | secret_type         | source                 |
      | secret_name         | sourcesecret3          |
      | auth_type           | SSH Key                |
      | textarea_value      | testinputvalue         |
    Then the step should succeed
    When I run the :get client command with:
      | resource | secret |
    Then the step should succeed
    And the output should contain:
      | sourcesecret3 |
