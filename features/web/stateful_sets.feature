Feature: Stateful Set related feature on web console

  # @author: etrott@redhat.com
  # @case_id: OCP-11054
  Scenario: Check details on StatefulSet page
    Given the master version >= "3.5"
    Given I create a new project
    When I perform the :goto_stateful_sets_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_no_stateful_sets web console action
    Then the step should succeed
    When I perform the :check_resource_missing_on_other_resources_page web console action with:
      | project_name  | <%= project.name %> |
      | resource_name | Stateful Set        |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/statefulset/statefulset-hello.yaml               |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/statefulset/statefulset-world_volume-envvar.yaml |
    Then the step should succeed

    When I perform the :check_stateful_set_entry_on_stateful_sets_page web console action with:
      | project_name | <%= project.name %> |
      | name         | hello               |
      | replicas     | 1                   |
    Then the step should succeed
    When I perform the :check_stateful_set_entry web console action with:
      | name         | world |
      | replicas     | 2     |
    Then the step should succeed
    When I perform the :filter_resources web console action with:
      | label_key     | name   |
      | filter_action | in ... |
      | label_value   | hello  |
    Then the step should succeed
    When I perform the :check_stateful_set_entry_missing web console action with:
      | name         | world |
      | replicas     | 2     |
    Then the step should succeed
    When I perform the :click_to_goto_one_stateful_set_page web console action with:
      | name | hello |
    Then the step should succeed
    When I perform the :check_breadcrumb_link web console action with:
      | resource | Stateful Sets |
      | name     | hello         |
    Then the step should succeed
    When I perform the :check_label web console action with:
      | label_key   | app   |
      | label_value | hello |
    Then the step should succeed
    When I perform the :check_label web console action with:
      | label_key   | name  |
      | label_value | hello |
    Then the step should succeed
    When I perform the :click_on_label_value web console action with:
      | label_key   | name  |
      | label_value | hello |
    Then the step should succeed
    When I perform the :check_stateful_set_entry web console action with:
      | name         | hello |
      | replicas     | 1     |
    Then the step should succeed
    When I perform the :check_stateful_set_entry_missing web console action with:
      | name         | world |
      | replicas     | 2     |
    Then the step should succeed

    When I perform the :click_to_goto_one_stateful_set_page web console action with:
      | name | hello |
    Then the step should succeed
    When I perform the :check_one_stateful_set_details web console action with:
      | status     | Active                |
      | replicas   | 1                     |
      | image_name | aosqe/hello-openshift |
      | ports      | 8080/TCP              |
    Then the step should succeed
    When I run the :check_no_volumes_defined web console action
    Then the step should succeed
    When I perform the :check_pod_in_pods_table web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | hello-0             |
      | status       | Running             |
      | ready        | 1/1                 |
      | restarts     | 0                   |
    Then the step should succeed

    When I run the :click_show_annotations web console action
    Then the step should succeed
    When I perform the :check_annotation web console action with:
      | key   | note      |
      | value | happy boy |
    Then the step should succeed
    When I run the :click_hide_annotations web console action
    Then the step should succeed

    When I perform the :click_to_goto_one_stateful_set_page_on_stateful_sets_page web console action with:
      | project_name | <%= project.name %> |
      | name         | world               |
    Then the step should succeed
    When I perform the :check_volume_info web console action with:
      | name   | volume1                                                |
      | type   | empty dir (temporary directory destroyed with the pod) |
      | medium | node's default                                         |
    Then the step should succeed

    When I run the :click_on_environment_tab web console action
    Then the step should succeed
    When I perform the :check_stateful_set_environment_tab_info web console action with:
      | container_name | world |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | MYSQL_USER |
      | env_var_value | userJJLLLL |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | MYSQL_PASSWORD |
      | env_var_value | userJJKKKK     |
    Then the step should succeed

    When I run the :click_on_events_tab web console action
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Successful create |
      | message | pet: world-1      |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Successful create |
      | message | pet: world-0      |
    Then the step should succeed

    When I perform the :sort_by web console action with:
      | sort_field | Message |
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_reason   | Successful create |
      | first_message  | pet: world-0      |
      | second_reason  | Successful create |
      | second_message | pet: world-1      |
    Then the step should succeed
    When I run the :change_sort_direction web console action
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_reason   | Successful create |
      | first_message  | pet: world-1      |
      | second_reason  | Successful create |
      | second_message | pet: world-0      |
    Then the step should succeed

    When I perform the :filter_by_keyword web console action with:
      | keyword | world-0 |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | reason  | Successful create |
      | message | pet: world-1      |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Successful create |
      | message | pet: world-0      |
    Then the step should succeed

    When I run the :click_to_goto_edit_YAML_page web console action
    Then the step should succeed
    When I perform the :patch_ace_editor_content web console action with:
      | content_type | YAML                                               |
      | patch        | {"op":"replace","path":"/spec/replicas","value":1} |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_stateful_set_updated_successfully_message web console action with:
      | name | world |
    Then the step should succeed

    When I run the :click_to_goto_edit_YAML_page web console action
    Then the step should succeed
    When I run the :click_cancel web console action
    Then the step should succeed
    When I perform the :check_stateful_set_updated_successfully_message_missing web console action with:
      | name | world |
    Then the step should succeed
