Feature: cronjob related
  # @author yanpzhan@redhat.com
  # @case_id OCP-19672
  Scenario: Check cronjob on console
    Given the master version >= "3.11"
    Given I have a project
    When I run the :run client command with:
      | name         | mycron-job            |
      | image        | docker.io/aosqe/hello-openshift@sha256:a2d509d3d5164f54a2406287405b2d114f952dca877cc465129f78afa858b31a |
      | generator    | cronjob/v1beta1       |
      | restart      | OnFailure             |
      | schedule     | */1 * * * *           |
    Then the step should succeed

    Given I open admin console in a browser

    # check cronjob page
    When I perform the :goto_cronjobs_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    When I perform the :check_page_match web action with:
      | content | mycron-job |
    Then the step should succeed
    When I perform the :goto_one_cronjob_page web action with:
      | project_name | <%= project.name %> |
      | cronjob_name | mycron-job          |
    Then the step should succeed
    When I perform the :check_resource_name_and_icon web action with:
      | cronjob_name | mycron-job |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name               | mycron-job  |
      | schedule           | */1 * * * * |
      | concurrency_policy | Allow       |
      | last_schedule_time |             |
    Then the step should succeed
    When I perform the :click_tab web action with:
      | tab_name | YAML |
    Then the step should succeed
    When I perform the :click_tab web action with:
      | tab_name | Events |
    Then the step should succeed
    Given a job appears with labels:
      | run=mycron-job |
    Given a pod is present with labels:
      | run=mycron-job |
    When I perform the :check_page_match web action with:
      | content | Created job mycron-job- |
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
      | owner               | mycron-job          |
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
      | cronjob_name | mycron-job          |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item | Delete Cron Job |
    Then the step should succeed
    When I perform the :delete_resource_panel web action with:
      | cascade | true |
    Then the step should succeed
    And I wait for the resource "cronjob" named "mycron-job" to disappear within 60 seconds
    When I perform the :check_page_match web action with:
      | content | mycron-job |
    Then the step should fail

    # check job and pod are deleted automatically
    Given I check that there are no jobs in the project
    And I check that there are no pods in the project
