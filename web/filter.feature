Feature: filter on create page

  # @author yapei@redhat.com
  # @case_id OCP-10692
  Scenario: search and filter for things on the create page
    Given the master version <= "3.3"
    Given I have a project
    # filter by tag instant-app
    When I perform the :filter_by_tags web console action with:
      | tag_name | instant-app |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | instant-app |
    Then the step should succeed
    # filter by tag quickstart
    When I perform the :filter_by_tags web console action with:
      | tag_name | quickstart |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | quickstart |
    Then the step should succeed
    # filter by tag xPaas
    When I perform the :filter_by_tags web console action with:
      | tag_name | xpaas |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | xpaas |
    Then the step should succeed
    # filter by tag java
    When I perform the :filter_by_tags web console action with:
      | tag_name | java |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | java |
    Then the step should succeed
    # filter by tag ruby
    When I perform the :filter_by_tags web console action with:
      | tag_name | ruby |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | ruby |
    Then the step should succeed
    # filter by tag perl
    When I perform the :filter_by_tags web console action with:
      | tag_name | perl |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | perl |
    Then the step should succeed
    # filter by tag python
    When I perform the :filter_by_tags web console action with:
      | tag_name | python |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | python |
    Then the step should succeed
    # filter by tag nodejs
    When I perform the :filter_by_tags web console action with:
      | tag_name | nodejs |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | nodejs |
    Then the step should succeed
    # filter by tag database
    When I perform the :filter_by_tags web console action with:
      | tag_name | database |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | database |
    Then the step should succeed
    # filter by tag messaging
    When I perform the :filter_by_tags web console action with:
      | tag_name | messaging |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | messaging |
    Then the step should succeed
    # filter by tag php
    When I perform the :filter_by_tags web console action with:
      | tag_name | php |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | php |
    Then the step should succeed
    When I run the :clear_tag_filters web console action
    Then the step should succeed
    # filter by partial keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | ph |
    Then the step should succeed
    When I perform the :check_all_resources_tags_contain web console action with:
      | tag_name | ph |
    Then the step should succeed
    When I run the :clear_keyword_filters web console action
    Then the step should succeed

    # filter by multi-keywords
    When I perform the :filter_by_keywords web console action with:
      | keyword | quickstart perl |
    Then the step should succeed
    When I perform the :check_all_resources_tags_contain web console action with:
      | tag_name | quickstart |
    Then the step should succeed
    When I perform the :check_all_resources_tags_contain web console action with:
      | tag_name | perl |
    Then the step should succeed
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    # filter by non-exist keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | hello |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I get the html of the web page
    Then the output should contain:
      | All builder images and templates are hidden by the current filter |
    """
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    # filter by invalid character keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | $#@ |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I get the html of the web page
    Then the output should contain:
      | All builder images and templates are hidden by the current filter |
    """
    # Clear filter link
    When I click the following "a" element:
      | text | Clear filter |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I get the html of the web page
    Then the output should not contain:
      | All builder images and templates are hidden by the current filter |
    """
    # filter by keyword and tag
    When I perform the :filter_by_keywords web console action with:
      | keyword | quickstart |
    Then the step should succeed
    When I perform the :check_all_resources_tags_contain web console action with:
      | tag_name | quickstart |
    Then the step should succeed
    When I perform the :filter_by_tags web console action with:
      | tag_name | nodejs |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | nodejs |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-13653
  Scenario: List and filter resources on overview page
    Given the master version >= "3.6"
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    Given the "ruby-ex-1" build was created
    Given the "ruby-ex-1" build completed
    When I run the :run client command with:
      | name      | myrun                 |
      | image     | aosqe/hello-openshift |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/replicaSet/tc536601/replicaset.yaml |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed

    When I perform the :filter_by_text_on_overview_page web console action with:
      | project_name | <%= project.name %> |
      | filter_text  | ruby                |
    Then the step should succeed
    When I perform the :check_filtered_entries_by_text_on_overview_page web console action with:
      | filter_text    | ruby |
      | num_of_entries | 1    |
    Then the step should succeed

    When I perform the :filter_by_label_on_overview_page web console action with:
      | label_key     | run    |
      | label_value   | myrun  |
      | filter_action | in ... |
    Then the step should succeed
    When I perform the :check_filtered_entries_by_text_on_overview_page web console action with:
      | filter_text    | myrun |
      | num_of_entries | 1     |
    Then the step should succeed
    When I run the :clear_all_filters web console action
    Then the step should succeed

    When I perform the :filter_by_label_on_overview_page web console action with:
      | label_key     | run        |
      | label_value   | myrun      |
      | filter_action | not in ... |
    Then the step should succeed
    When I perform the :check_filtered_entries_by_text_missing_on_overview_page web console action with:
      | filter_text    | myrun |
      | num_of_entries | 5     |
    Then the step should succeed
    When I run the :clear_all_filters web console action
    Then the step should succeed

    When I perform the :filter_resources_with_exists_option web console action with:
      | label_key     | app            |
      | filter_action | does not exist |
    Then the step should succeed
    Given 5 seconds have passed
    When I get the visible text on web html page
    Then the output should contain:
      | myrun |
    When I run the :clear_all_filters web console action
    Then the step should succeed    
    When I perform the :filter_resources_with_exists_option web console action with:
      | label_key     | app    |
      | filter_action | exists |
    Then the step should succeed
    Given 5 seconds have passed
    When I get the visible text on web html page
    Then the output should not contain:
      | myrun |
    When I run the :clear_all_filters web console action
    Then the step should succeed

    When I perform the :list_by_type_on_overview_page web console action with:
      | type | Application |
    Then the step should succeed
    When I perform the :check_resources_order_on_overview_page web console action with:
      | first_name  | ruby-ex    |
      | first_type  | deployment |
      | second_name | jenkins    |
      | second_type | deployment |
    Then the step should succeed

    When I perform the :list_by_type_on_overview_page web console action with:
      | type | Resource Type |
    Then the step should succeed
    When I perform the :check_resources_order_on_overview_page web console action with:
      | first_name  | ruby-ex     |
      | first_type  | deployment  |
      | second_name | frontend    |
      | second_type | replica set |
    Then the step should succeed

    When I perform the :list_by_type_on_overview_page web console action with:
      | type | Pipeline |
    Then the step should succeed
    When I perform the :check_resources_order_on_overview_page web console action with:
      | first_name  | nodejs-mongodb-example |
      | first_type  | deployment             |
      | second_name | jenkins                |
      | second_type | deployment             |
    Then the step should succeed
