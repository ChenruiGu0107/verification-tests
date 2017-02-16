Feature: oc convert related scenarios

  # @author yapei@redhat.com
  # @case_id OCP-10892
  Scenario: Convert files between different API versions using oc convert
    Given I have a project
    When I run the :convert client command
    Then the step should fail
    And the output should match:
      | [Ee]rror                |
      | must provide.*resources |
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job.yaml"
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/schedule-job.yaml"
    # didn't specify output version
    When I run the :convert client command with:
      | file     | job.yaml |
      | loglevel | 2        |
    Then the step should succeed
    And the output should contain:
      | kind: Job            |
      | apiVersion: batch/v1 |
    # specify output version
    When I run the :convert client command with:
      | file           | job.yaml          |
      | output_version | batch/v2alpha1    |
      | loglevel       | 2                 |
    Then the step should succeed
    And the output should contain:
      | kind: Job                  |
      | apiVersion: batch/v2alpha1 |
    # convert to JSON format
    When I run the :convert client command with:
      | file  | schedule-job.yaml |
      | local | false             |
      | o     | json              |
    Then the step should succeed
    And the output should contain:
      | "kind": "ScheduledJob"         |
      | "apiVersion": "batch/v2alpha1" |
    #convert files in directory and create
    Given I create the "testdir" directory
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job.yaml" into the "testdir" dir
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/schedule-job.yaml" into the "testdir" dir
    When I run the :convert client command with:
      | file  | testdir/ |
      | local | false    |
    Then the step should succeed
    And I run the :create client command with:
      | f      | -                         |
      | _stdin | <%= @result[:response] %> |
    Then the step should succeed
    And the output should match:
      | job.*pi.*created             |
      | scheduledjob.*hello.*created |
    # convert recursively
    Given I create the "mult/dir1" directory
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job.yaml" into the "mult/dir1" dir
    Given I create the "mult/dir2" directory
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/schedule-job.yaml" into the "mult/dir2" dir
    When I run the :convert client command with:
      | file           | mult/          |
      | output_version | batch/v2alpha1 |
      | recursive      | true           |
    Then the step should succeed
    And the output should match 2 times:
      | apiVersion: batch/v2alpha1 |
