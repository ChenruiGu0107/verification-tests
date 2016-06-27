Feature: job.feature

  # @author cryan@redhat.com
  # @case_id 511597
  Scenario: Create job with multiple completions
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc511597/job.yaml"
    When I run the :create client command with:
      | f | job.yaml |
    Then the step should succeed
    Given 5 pods become ready with labels:
      | app=pi |
    When I run the :get client command with:
      | resource | pods |
      | l | app=pi |
    Then the step should succeed
    And the output should contain 5 times:
      |  pi- |
    Given 5 pods become ready with labels:
      | app=pi |
    Given evaluation of `@pods[0].name` is stored in the :pilog clipboard
    Given the pod named "<%= cb.pilog %>" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | <%= cb.pilog %> |
    Then the step should succeed
    And the output should contain "3.14159"
    When I run the :delete client command with:
      | object_type | job |
      | object_name_or_id | pi |
    Then the step should succeed
    Given all existing pods die with labels:
      | app=pi |
    When I run the :get client command with:
      | resource | pods |
      | l | app=pi |
    Then the step should succeed
    And the output should not contain "pi-"
    Given I replace lines in "job.yaml":
      | completions: 5 | completions: -1 |
    When I run the :create client command with:
      | f | job.yaml |
    Then the step should fail
    And the output should contain "must be greater than or equal to 0"
    Given I replace lines in "job.yaml":
      | completions: -1 | completions: 0.1 |
    When I run the :create client command with:
      | f | job.yaml |
    Then the step should fail
    And the output should contain "fractional integer"

  # @author chezhang@redhat.com
  # @case_id 511600
  Scenario: Go through the job example
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | pods   |
    Then the output should contain 5 times:
      | pi-      |
    Given status becomes :succeeded of exactly 5 pods labeled:
      | app=pi   |
    Then the step should succeed
    And I wait until job "pi" completes
    When I run the :get client command with:
      | resource | jobs   |
    Then the output should match:
      | pi.*5 |
    When I run the :describe client command with:
      | resource | jobs   |
      | name     | pi     |
    Then the output should match:
      | Name:\\s+pi                               |
      | Image\(s\):\\s+openshift/perl-516-centos7 |
      | Selector:\\s+app=pi                       |
      | Parallelism:\\s+5                         |
      | Completions:\\s+<unset>                   |
      | Labels:\\s+app=pi                         |
      | Pods\\s+Statuses:\\s+0\\s+Running.*5\\s+Succeeded.*0\\s+Failed  |
    And the output should contain 5 times:
      | SuccessfulCreate  |
    When I run the :get client command with:
      | resource | pods   |
    Then the output should contain 5 times:
      | Completed         |
    When I run the :logs client command with:
      | resource_name     | <%= pod(-5).name %>   |
    Then the step should succeed
    And the output should contain:
      |  3.14159265       |
