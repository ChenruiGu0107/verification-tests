Feature: oc_secrets.feature

  # @author cryan@redhat.com
  # @case_id 490968
  Scenario: Add secrets to serviceaccount via oc secrets add
    Given I have a project
    When I run the :secrets client command with:
      | action | new        |
      | name   | test       |
      | source | /etc/hosts |
    Then the step should succeed
    When I run the :secrets client command with:
      | action         | add                    |
      | serviceaccount | serviceaccount/default |
      | secrets_name   | secret/test            |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | serviceaccount |
      | name     | default        |
    Then the step should succeed
    And the output should contain:
      |Mountable secrets|
      |test|
    When I run the :secrets client command with:
      | action         | add                    |
      | serviceaccount | serviceaccount/default |
      | secrets_name   | secret/test            |
      | for            | pull                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | serviceaccount |
      | resource_name | default        |
      | o             | json           |
    Then the step should succeed
    And the output should contain:
      |"imagePullSecrets"|
      |"name": "test"    |
    When I run the :secrets client command with:
      | action         | add                    |
      | serviceaccount | serviceaccount/default |
      | secrets_name   | secret/test            |
      | for            | pull,mount             |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | serviceaccount |
      | resource_name | default        |
      | o             | json           |
    Then the step should succeed
    And the output should contain:
      |"imagePullSecrets"|
    And the output should contain 2 times:
      |"name": "test" |

