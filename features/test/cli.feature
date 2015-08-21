Feature: Testing CLI Scenarios
  Scenario: simple create project
    When I run the :new_project client command with:
      | project_name | demo |
      | display name | OpenShift 3 Demo |
      | description  | This is the first demo project with OpenShift v3 |
    Then the step should succeed
    And 3 seconds have passed
    When I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should contain:
      | OpenShift 3 Demo |
      | Active |
    When I switch to the second user
    And I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should not contain:
      | demo |
    When I switch to the first user
    And I run the :delete client command with:
      | object_type | project |
      | object_name_or_id | demo |
    Then the step should succeed

  # actually, because of user clean-up relying on cli, we never run REST
  #   requests before we run cli requests
  Scenario: rest request before cli
    Given I perform the :delete_project rest request with:
      | project name | demo |
    # looks like time needs to pass for the project to be really gone
    And 5 seconds have passed
    And I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should not contain:
      | demo |

  Scenario: noescape, literal and false rules executor features
    When I run the :help client command with:
      | help word | help create |
      # we fail because "help create" is treated as a single option
    Then the step should fail
    When I run the :help client command with:
      | help word | noescape: help create |
      # here noescape prevents that
    Then the step should succeed
    When I run the :help client command with:
      | help word | literal: :false |
    Then the step should fail
    And the output should contain:
      |unknown command ":false"|
    And the output should not contain:
      |:literal|
    When I run the :help client command with:
      | help word | help |
      | fake option to be skipped | :false |
    Then the step should succeed
    And the output should match:
      |Developer .*? Client|

  Scenario: muti-args
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg             | help   |
      | test do not use | create |
      | arg             | -h     |
    Then the step should succeed
    And the expression should be true> @result[:instruction] =~ /oc.+?help.+?create.+?-h/
