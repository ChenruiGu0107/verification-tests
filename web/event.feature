Feature: check event feature on web console
  # @author etrott@redhat.com
  # @case_id OCP-9861
  Scenario: Filter and sort event on web console
    Given I have a project
    When I run the :new_app client command with:
      | code         | https://github.com/sclorg/nodejs-ex.git |
      | image_stream | openshift/nodejs:latest                    |
      | name         | nodejs-sample                              |
    Then the step should succeed
    Given the "nodejs-sample-1" build completed

    # check one build event tab
    When I perform the :click_on_events_tab_on_build_page web console action with:
      | project_name      | <%= project.name %>           |
      | bc_and_build_name | nodejs-sample/nodejs-sample-1 |
    Then the step should succeed

    When I perform the :check_event_message web console action with:
      | reason | Scheduled |
    Then the step should succeed
    # filter by reason
    When I perform the :filter_by_keyword web console action with:
      | keyword | created |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | reason | Scheduled |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason | Created |
    Then the step should succeed
    When I run the :clear_keyword_filters web console action
    Then the step should succeed

    When I perform the :check_event_message web console action with:
      | message | Started container |
    Then the step should succeed
    # filter by message
    When I perform the :filter_by_keyword web console action with:
      | keyword | pulled |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | message | Started container |
    Then the step should succeed
    # Successfully pulled
    When I perform the :check_event_message web console action with:
      | message | ulled |
    Then the step should succeed
    When I run the :clear_keyword_filters web console action
    Then the step should succeed

    # sort by time
    When I perform the :sort_by web console action with:
      | sort_field | Time |
    Then the step should succeed
    # change sort direction from oldest messages to newest
    When I run the :change_sort_direction web console action
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_reason   | Scheduled |
      | second_message | Created   |
    Then the step should succeed

    # sort by reason
    When I perform the :sort_by web console action with:
      | sort_field | Reason |
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_reason  | Created |
      | second_reason | Started |
    Then the step should succeed

    # sort by message
    When I perform the :sort_by web console action with:
      | sort_field | Message |
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_message  | Created container |
      | second_message | Started container |
    Then the step should succeed

    # check events page
    When I perform the :goto_events_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    When I perform the :check_event_message web console action with:
      | name | nodejs-sample-1-build |
    Then the step should succeed
    # filter by name
    When I perform the :filter_by_keyword web console action with:
      | keyword | deploy |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | name | nodejs-sample-1-build |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | name | nodejs-sample-1-deploy |
    Then the step should succeed
    When I run the :clear_keyword_filters web console action
    Then the step should succeed

    When I perform the :check_event_message web console action with:
      | kind | Pod |
    Then the step should succeed
    # filter by kind
    When I perform the :filter_by_keyword web console action with:
      | keyword | Deployment Config |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | kind | Pod |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | kind | Deployment Config |
    Then the step should succeed
    When I run the :clear_keyword_filters web console action
    Then the step should succeed

    When I perform the :check_event_message web console action with:
      | reason | Scheduled |
    Then the step should succeed
    # filter by reason
    When I perform the :filter_by_keyword web console action with:
      | keyword | Successful create |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | reason | Scheduled |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason | Successful |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason | reate |
    Then the step should succeed

    When I run the :clear_keyword_filters web console action
    Then the step should succeed

    When I perform the :check_event_message web console action with:
      | message | Scheduled |
    Then the step should succeed
    # filter by message
    When I perform the :filter_by_keyword web console action with:
      | keyword | pulling image |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | message | Scheduled |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | message | pulling image |
    Then the step should succeed
    When I run the :clear_keyword_filters web console action
    Then the step should succeed

    # sort by time
    When I perform the :sort_by web console action with:
      | sort_field | Time |
    Then the step should succeed
    # change sort direction from oldest messages to newest
    When I run the :change_sort_direction web console action
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_name     | nodejs-sample-1-build |
      | first_reason   | Scheduled             |
      | second_name    | nodejs-sample-1-build |
      | second_message | Created               |
    Then the step should succeed

    # sort by name
    When I perform the :sort_by web console action with:
      | sort_field | Name |
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_name  | nodejs-sample-1-build  |
      | second_name | nodejs-sample-1-deploy |
    Then the step should succeed

    # sort by kind
    When I perform the :sort_by web console action with:
      | sort_field | Kind |
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_kind  | Deployment Config |
      | second_kind | Pod               |
    Then the step should succeed

    # sort by reason
    When I perform the :sort_by web console action with:
      | sort_field | Reason |
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_reason  | Created |
      | second_reason | Pulling |
    Then the step should succeed

    # sort by message
    When I perform the :sort_by web console action with:
      | sort_field | Message |
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_message  | Started container     |
      | second_message | Successfully assigned |
    Then the step should succeed

    # sort by count
    When I perform the :sort_by web console action with:
      | sort_field | Count |
    Then the step should succeed
    When I perform the :check_messages_order web console action with:
      | first_message  | Created container |
      | second_message | Started container |
    Then the step should succeed
