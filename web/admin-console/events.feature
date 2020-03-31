Feature: events related

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
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/tc526202/bc.json |
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

    When I perform the :set_filter_strings web action with:
      | filter_text | ruby-ex-1 |
    Then the step should succeed
    When I perform the :check_results_contain_correct_strings web action with:
      | filter_text | ruby-ex-1 |
    Then the step should succeed

    When I perform the :set_filter_strings web action with:
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
