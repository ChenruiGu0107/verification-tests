Feature: cronjob related
  # @author yanpzhan@redhat.com
  # @case_id OCP-19672
  Scenario: Check cronjob on console
    Given the master version >= "3.11"
    Given I have a project
    Given I obtain test data file "job/cronjob_3.9_with_startingDeadlineSeconds.yaml"
    When I run the :create client command with:
      | f | cronjob_3.9_with_startingDeadlineSeconds.yaml |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I get project cronjobs
    Then the output should contain "sj3"
    """
    Given I open admin console in a browser

    # check cronjob page
    When I perform the :goto_cronjobs_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    When I perform the :check_page_match web action with:
      | content | sj3 |
    Then the step should succeed
    When I perform the :goto_one_cronjob_page web action with:
      | project_name | <%= project.name %> |
      | cronjob_name | sj3                 |
    Then the step should succeed
    When I perform the :check_resource_name_and_icon web action with:
      | cronjob_name | sj3 |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name               | sj3         |
      | schedule           | */1 * * * * |
      | concurrency_policy | Allow       |
      | last_schedule_time |             |
    Then the step should succeed
    When I run the :click_yaml_tab web action
    Then the step should succeed
    When I run the :click_events_tab web action
    Then the step should succeed
    Given a job appears with labels:
      | run=sj3 |
    Given a pod is present with labels:
      | run=sj3 |
    When I perform the :check_page_match web action with:
      | content | Created job sj3- |
    Then the step should succeed

    # check job page
    When I perform the :goto_jobs_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :goto_one_job_page web action with:
      | project_name | <%= project.name %> |
      | job_name     | <%= job.name %>     |
    Then the step should succeed
    When I perform the :check_resource_name_and_icon web action with:
      | job_name | <%= job.name %> |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name                | <%= cb.job_name %>  |
      | owner               | sj3                 |
      | desired_completions | 1                   |
      | parallelism         | 1                   |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item | Edit Parallelism |
    Then the step should succeed
    When I perform the :update_resource_count web action with:
      | resource_count | 2 |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | parallelism | 2 |
    Then the step should succeed

    # delete cronjob from console
    When I perform the :goto_one_cronjob_page web action with:
      | project_name | <%= project.name %> |
      | cronjob_name | sj3                 |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item | Delete Cron Job |
    Then the step should succeed
    When I perform the :delete_resource_panel web action with:
      | cascade | true |
    Then the step should succeed
    And I wait for the resource "cronjob" named "sj3" to disappear within 60 seconds
    When I perform the :check_page_match web action with:
      | content | sj3 |
    Then the step should fail

    # check job and pod are deleted automatically
    Given I check that there are no jobs in the project
    And I check that there are no pods in the project
