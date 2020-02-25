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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc526202/bc.json |
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
    When I perform the :search_by_resource_type web action with:
      | type | Pod |
    Then the step should succeed
    When I perform the :search_by_event_catagory web action with:
      | catagory| All |
    Then the step should succeed
    When I perform the :check_results_contain_correct_type web action with:
      | type | pod |
    Then the step should succeed

    When I perform the :goto_project_events web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :search_by_api_group web action with:
      | api_group | build.openshift.io/v1 |
    Then the step should succeed
    When I run the :search_by_event_catagory web action
    Then the step should succeed
    When I run the :check_result_not_contain_warning_catagory web action
    Then the step should succeed
