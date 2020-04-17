Feature: oc convert related scenarios

  # @author yapei@redhat.com
  Scenario Outline: Convert resource files using convert
    Given I have a project
    Given I obtain test data file "job/job.yaml"
    # didn't specify output version
    When I run the :convert client command with:
      | _tool    | <tool>   |
      | file     | job.yaml |
      | loglevel | 2        |
    Then the step should succeed
    And the output should contain:
      | kind: Job            |
      | apiVersion: batch/v1 |
    # convert to JSON format
    When I run the :convert client command with:
      | _tool | <tool>   |
      | file  | job.yaml |
      | local | false    |
      | o     | json     |
    Then the step should succeed
    And the output should contain:
      | "kind": "Job"            |
      | "apiVersion": "batch/v1" |
    #convert files in directory and create
    Given I create the "testdir" directory
    Given I obtain test data file "job/job.yaml" into the "testdir" dir
    Given I obtain test data file "pods/busybox-pod.yaml" into the "testdir" dir
    When I run the :convert client command with:
      | _tool | <tool>   |
      | file  | testdir/ |
      | local | false    |
    Then the step should succeed
    And I run the :create client command with:
      | _tool  | <tool>                    |
      | f      | -                         |
      | _stdin | <%= @result[:response] %> |
    Then the step should succeed
    And the output should match:
      | job.*pi.*created  |
      | pod.*created      |
    # convert recursively
    Given I create the "mult/dir1" directory
    Given I obtain test data file "job/job.yaml" into the "mult/dir1" dir
    Given I create the "mult/dir2" directory
    Given I obtain test data file "pods/busybox-pod.yaml" into the "mult/dir2" dir
    When I run the :convert client command with:
      | _tool          | <tool>         |
      | file           | mult/          |
      | recursive      | true           |
    Then the step should succeed
    And the output should contain:
      | kind: List              |
      | items:                  |
      | - apiVersion: batch/v1  |
      | - apiVersion: v1        |
    # --output-version negative test
    When I run the :convert client command with:
      | _tool           | <tool>    |
      | file            | job.yaml  |
      | output_version  | xyz       |
    Then the step should fail
    And the output should match:
      | batch\.Job.*not suitable.*converting.*xyz |

    Examples:
      | tool     |
      | oc       | # @case_id OCP-10892
      | kubectl  | # @case_id OCP-20924
