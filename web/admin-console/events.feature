Feature: events and logs related

  # @author yapei@redhat.com
  # @case_id OCP-19532
  Scenario: Check resource events
    Given the master version >= "3.11"
    Given I have a project
    And I open admin console in a browser

    # no events when project is empty
    When I perform the :goto_project_events web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | No Events |
    Then the step should succeed

    # create 1st build
    Given I obtain test data file "build/tc526202/bc.json"
    When I run the :create client command with:
      | f | bc.json |
    Then the step should succeed

    # 2nd build will fail
    When I run the :patch client command with:
      | resource      | buildconfig                                                                     |
      | resource_name | ruby-ex                                                                         |
      | p             | {"spec":{"source":{"git":{"uri":"https://github.com/sclorg/ruby-extest.git"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-2" build finished

    When I perform the :filter_event_by_name_or_message web action with:
      | filter_text | ruby-ex-1 |
    Then the step should succeed
    When I perform the :check_results_contain_correct_strings web action with:
      | filter_text | ruby-ex-1 |
    Then the step should succeed

    When I perform the :filter_event_by_name_or_message web action with:
      | filter_text | ruby-ex-3 |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | No Matching Events |
    Then the step should succeed

    When I perform the :goto_project_events web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :search_by_resource web action with:
      | resource_kind | Pod |
    Then the step should succeed
    When I perform the :check_results_contain_correct_type web action with:
      | type | pod |
    Then the step should succeed

    # show failed builds events
    When I perform the :goto_project_events web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :search_by_resource web action with:
      | resource_kind  | Build                 |
      | resource_group | build.openshift.io/v1 |
    Then the step should succeed
    When I run the :search_by_catagory_to_show_build_failures web action
    Then the step should succeed
    When I run the :check_results_contain_correct_build_failures_type web action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-27601
  Scenario: Multiple resources could be selected on event page
    Given the master version >= "4.4"
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:latest                         |
      | app_repo     | https://github.com/openshift/ruby-hello-world |
      | name         | ruby |
    Then the step should succeed
    And I open admin console in a browser
    When I perform the :goto_project_events web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    Given the "ruby-1" build was created
    When I perform the :search_by_resource web action with:
      | resource_kind  | Build                 |
      | resource_group | build.openshift.io/v1 |
    Then the step should succeed
    When I perform the :search_by_resource web action with:
      | resource_kind  | Pod |
    Then the step should succeed
    When I perform the :check_results_contain_correct_type web action with:
      | type | pod |
    Then the step should succeed
    When I perform the :check_results_contain_correct_type web action with:
      | type | build |
    Then the step should succeed
    When I run the :clear_resource_filters web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | All |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-20688
  Scenario: Check log streaming
    Given the master version >= "4.1"
    Given I have a project
    Given I obtain test data file "deployment/dc-with-two-containers.yaml"
    And I run the :create client command with:
      | f | dc-with-two-containers.yaml |
    Given 1 pods become ready with labels:
      | deploymentconfig=dctest,deployment=dctest-1 |
    And I open admin console in a browser

    # check Logs when Pod is in Completed status
    When I perform the :goto_one_pod_log_page web action with:
      | project_name | <%= project.name %> |
      | pod_name     | dctest-1-deploy     |
    Then the step should succeed
    When I run the :check_log_streaming_is_ended web action
    Then the step should succeed

    # check Logs can be shown for specific container
    When I perform the :goto_one_pod_log_page web action with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= pod.name %>     |
    Then the step should succeed
    When I perform the :check_log_content_contains web action with:
      | log_content | serving at 8080 |
    Then the step should succeed
    When I perform the :switch_to_container web action with:
      | container_name  | dctest-2 |
    Then the step should succeed
    When I perform the :check_log_content_contains web action with:
      | log_content | serving on 8081 |
    Then the step should succeed
    When I perform the :check_log_content_contains web action with:
      | log_content | serving at 8080 |
    Then the step should fail

    # check Logs can be Expanded & Collapsed
    When I run the :expand_log web action
    Then the step should succeed
    When I run the :check_required_context_shown_in_expanded_log_view web action
    Then the step should succeed
    When I perform the :check_log_content_contains web action with:
      | log_content | serving on 8081 |
    Then the step should succeed
    When I run the :check_some_context_missing_in_expanded_log_view web action
    Then the step should succeed

    When I run the :collapse_log web action
    Then the step should succeed
    When I run the :check_required_context_shown_in_collapsed_log_view web action
    Then the step should succeed
    When I run the :check_some_context_missing_in_collapsed_log_view web action
    Then the step should succeed

    # check Logs can be Paused/Resumed
    When I run the :pause_log_streaming web action
    Then the step should succeed
    When I run the :check_log_streaming_is_paused web action
    Then the step should succeed
    When I run the :resume_log_streaming web action
    Then the step should succeed
    When I run the :check_log_streaming_is_resumed web action
    Then the step should succeed
