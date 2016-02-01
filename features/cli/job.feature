Feature: job.feature

  # @author cryan@redhat.com
  # @case_id 511597
  Scenario: Create job with multiple completions
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc511597/job.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | jobs |
      | name | pi |
    Then the step should succeed
    And the output should contain "5 Running"
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
