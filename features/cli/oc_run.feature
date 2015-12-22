Feature: oc run related scenarios
  # @author pruan@redhat.com
  # @case_id 499995
  Scenario: Negative test for oc run
    Given I have a project
    And I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | run |
      | test_do_not_use | -u |
    Then the step should fail
    Then the output should contain:
      | oc run NAME --image=image [--env="key=value"] [--port=port] [--replicas=replicas] [--dry-run=bool] [--overrides=inline-json] [options] |
      | Error: unknown shorthand flag: 'u' in -u |
    And I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | run |
      | test_do_not_use | -l -t |
    Then the step should fail
    Then the output should contain:
      | error: NAME is required for run |
    Then the step should fail
    And I run the :run client command with:
      | name | <%= project.name %> |
      | image |                    |
    Then the step should fail
    And the output should contain:
      | Parameter: image is required |
    # oc run with less options
    And I run the :run client command with:
      | name | newtest |
    Then the step should fail
    And the output should contain:
      | Parameter: image is required |
    And I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | run |
      | test_do_not_use | --image=test  |
    Then the step should fail
    And the output should contain:
      | error: NAME is required for run |
