Feature: filter on create page
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
