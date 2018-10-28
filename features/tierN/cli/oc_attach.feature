Feature: oc attach related scenarios

  # @author yapei@redhat.com
  # @case_id OCP-10672
  Scenario: Negative test for oc attach
    Given I have a project
    And I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg             | attach |
      | test_do_not_use | -u     |
    Then the step should fail
    And the output should contain:
      | Error: unknown shorthand flag: 'u' in -u            |
      | Usage:                                              |
    When I run the :attach client command with:
      | pod | 123456-7890 |
    Then the step should fail
    And the output should contain:
      | pods "123456-7890" not found |
