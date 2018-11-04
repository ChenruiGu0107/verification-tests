Feature: Check links in Openshift

  # @author chali@redhat.com
  # @case_id OCP-10542
  Scenario: There is doc link for each resource on web console
    Given I create a new project
    And I store master major version in the clipboard
    When I perform the :check_learn_more_link web console action with:
      | project_name   | <%= project.name %>      |
      | master_version | <%= cb.master_version %> |
    Then the step should succeed
