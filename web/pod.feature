Feature: Pod related features on web console

  # @author yanpzhan@redhat.com
  # @case_id OCP-13569
  Scenario: Multiple containers in single pod should not mix logs
    Given the master version > "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/ocp13569/pod-with-three-containers-and-logs.yaml |
    Then the step should succeed
    Given the pod named "counter" becomes ready

    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | counter             |
    Then the step should succeed

    When I perform the :check_log_tab_on_pod_page web console action with:
      | status | Running |
    Then the step should succeed

    #Select containers, add checkpoint in bug1427289
    #Check the first container's log
    When I perform the :select_a_container web console action with:
      | container_name | count-log-0 |
    Then the step should succeed

    When I perform the :check_log_context_nonexist web console action with:
      | log_context | TEST |
    Then the step should succeed

    When I perform the :check_log_context_nonexist web console action with:
      | log_context | INFO |
    Then the step should succeed

    #Check the second container's log
    When I perform the :select_a_container web console action with:
      | container_name | count-log-1 |
    Then the step should succeed

    When I perform the :check_log_context web console action with:
      | log_context | TEST |
    Then the step should succeed

    When I perform the :check_log_context_nonexist web console action with:
      | log_context | INFO |
    Then the step should succeed

    #Check the third container's log
    When I perform the :select_a_container web console action with:
      | container_name | count-log-2 |
    Then the step should succeed

    When I perform the :check_log_context web console action with:
      | log_context | INFO |
    Then the step should succeed

    When I perform the :check_log_context_nonexist web console action with:
      | log_context | TEST |
    Then the step should succeed

    #Check the first container's log again
    When I perform the :select_a_container web console action with:
      | container_name | count-log-0 |
    Then the step should succeed

    When I perform the :check_log_context_nonexist web console action with:
      | log_context | TEST |
    Then the step should succeed

    When I perform the :check_log_context_nonexist web console action with:
      | log_context | INFO |
    Then the step should succeed


  # @author yapei@redhat.com
  # @case_id OCP-9592
  Scenario: Generate same labels in the UI as CLI
    Given I have a project
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>  |
      | image_name   | python               |
      | image_tag    | latest               |
      | namespace    | openshift            |
      | app_name     | python-sample        |
      | source_url   | https://github.com/sclorg/django-ex.git |
    Then the step should succeed
    Given I use the "<%= project.name %>" project
    Given a pod is present with labels:
      | deployment=python-sample-1 |
    Given evaluation of `pod.labels` is stored in the :label_from_ui clipboard
    # check labels via cli
    Given I create a new project
    When I run the :new_app client command with:
      | image_stream | python:latest                              |
      | code         | https://github.com/sclorg/django-ex.git |
      | name         | python-sample                              |
    Then the step should succeed
    Given a pod is present with labels:
      | deployment=python-sample-1 |
    Given evaluation of `pod.labels` is stored in the :label_from_cli clipboard
    Then the expression should be true> cb.label_from_ui == cb.label_from_cli

  # @author cryan@redhat.com
  # @case_id OCP-10822
  Scenario: Debug crashing pods on web console
    Given I have a project

    When I run the :run client command with:
      | name    | run-once-pod     |
      | image   | openshift/origin |
      | command | true             |
      | cmd     | ls               |
      | cmd     | /abcd            |
      | restart | Never            |
    Then the step should succeed

    When I perform the :goto_debug_in_terminal_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | run-once-pod        |
    Then the step should succeed
    Given the pod named "run-once-pod-debug" becomes ready

    When I run the :close_debug_in_terminal_page web console action
    Then the step should succeed
    Given I wait for the pod named "run-once-pod-debug" to die regardless of current status

    When I perform the :goto_debug_in_terminal_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | run-once-pod        |
    Then the step should succeed
    Given the pod named "run-once-pod-debug" becomes ready

    When I perform the :goto_debug_in_terminal_page_in_new_tab web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | run-once-pod        |
    Then the step should succeed
    When I run the :check_debug_pod_exists_error web console action
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-14311
  Scenario: Pod details should show information about init containers.
    Given the master version >= "3.6"
    Given I have a project
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/initContainer.yaml  |
    Then the step should succeed

    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | hello-pod           |
    Then the step should succeed
    When I perform the :check_container_status_on_one_pod_page web console action with:
      | name          | wait    |
      | state         | Running |
      | ready         | false   |
      | restart_count | 0       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=hello-pod |
    When I perform the :check_container_status_on_one_pod_page web console action with:
      | name          | hello-pod |
      | state         | Running   |
      | ready         | true      |
      | restart_count | 0         |
    Then the step should succeed
    When I perform the :check_init_container_successfully_completed_message web console action with:
      | name | wait |
    Then the step should succeed

    When I perform the :check_container_template_on_one_pod_page web console action with:
      | name    | wait   |
      | image   | centos |
      | command |        |
      | mount   |        |
    Then the step should succeed

    When I perform the :check_container_template_on_one_pod_page web console action with:
      | name  | hello-pod |
      | ports | 8080/TCP  |
      | mount |           |
    Then the step should succeed
