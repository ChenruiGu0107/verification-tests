Feature: Node related

  # @author hasha@redhat.com
  # @case_id OCP-23044
  @admin
  @destructive
  Scenario: Taints and Tolerations support on console
    Given I store the schedulable workers in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    Given the master version >= "4.1"
    Given I have a project
    And I open admin console in a browser
    Given the first user is cluster-admin
    When I perform the :add_taint_to_node web action with:
      | node_name      | <%= cb.nodes[0].name %> |
      | key            | Taints                  |
      | affinity_key   | taint_test              |
      | affinity_value | taint                   |
      | effect         | NoSchedule              |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe admin command with:
      | resource | node                    |
      | name     | <%= cb.nodes[0].name %> |
    Then the output should match:
      | Taints:\\s+taint_test=taint:NoSchedule |
    """
    When I perform the :remove_taint_from_node web action with:
      | node_name      | <%= cb.nodes[0].name %> |
      | key            | Taints                  |
      | affinity_key   | taint_test              |
    Then the step should succeed
    # This wait up here is for node safe and the whole running will be terminated if failed
    And I wait up to 90 seconds for the steps to pass:
    """
    When I run the :describe admin command with:
      | resource | node                    |
      | name     | <%= cb.nodes[0].name %> |
    Then the output should not match:
      | Taints:\\s+taint_test=taint:NoSchedule |
    """

    When I run the :new_app_as_dc client command with:
      | app_repo | quay.io/openshifttest/ruby-25-centos7@sha256:575194aa8be12ea066fc3f4aa9103dcb4291d43f9ee32e4afe34e0063051610b~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    When I perform the :add_tolerations_to_pod web action with:
      | project_name      | <%= project.name %> |
      | dc_name           |  ruby-ex            |
      | key               | Tolerations         |
      | affinity_key      | taint_test          |
      | affinity_value    | taint               |
      | effect            | NoSchedule          |
      | operator          | Equal               |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource     | dc      |
      |resource_name | ruby-ex |
      | o            | yaml    |
    Then the step should succeed
    And the output should contain:
      | key: taint_test    |
      | operator: Equal    |
      | value: taint       |
      | effect: NoSchedule |
    """
    When I perform the :remove_tolerations_from_pod web action with:
      | project_name      | <%= project.name %> |
      | dc_name           |  ruby-ex            |
      | key               | Tolerations         |
      | affinity_key      | taint_test          |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | dc      |
      | resource_name | ruby-ex |
      | o             | yaml    |
    Then the step should succeed
    And the output should not contain:
      | key: taint_test    |
      | operator: Equal    |
      | value: taint       |
      | effect: NoSchedule |
    """

  # @author yapei@redhat.com
  # @case_id OCP-25764
  @admin
  Scenario: Filter Machines should also search for node name
    Given the master version >= "4.3"
    Given I open admin console in a browser
    Given the first user is cluster-admin
    Given I store the schedulable workers in the :schedule_workers clipboard
    Given I store all machines in the "openshift-machine-api" project to the :machines clipboard

    When I run the :goto_node_page web action
    Then the step should succeed
    Given I wait up to 120 seconds for the steps to pass:
    """
    When I run the :click_to_machines_page web action
    Then the step should succeed
    """
    # filter by machine name
    When I perform the :set_filter_strings web action with:
      | filter_text | <%= cb.machines[0].name %> |
    Then the step should succeed
    When I perform the :check_item_in_table web action with:
      | item | <%= cb.machines[0].name %> |
    Then the step should succeed
    When I perform the :check_item_in_table web action with:
      | item | <%= cb.machines[1].name %> |
    Then the step should fail

    # filter by node name
    When I perform the :set_filter_strings web action with:
      | filter_text | <%= cb.schedule_workers[0].name %> |
    Then the step should succeed
    When I perform the :check_item_in_table web action with:
      | item | <%= cb.schedule_workers[0].name %> |
    Then the step should succeed
    When I perform the :check_item_in_table web action with:
      | item | <%= cb.schedule_workers[2].name %> |
    Then the step should fail

  # @author xiaocwan@redhat.com
  # @case_id OCP-19722
  @admin
  Scenario: Check nodes list columns and terminal tab
    Given the master version >= "4.3"
    Given the first user is cluster-admin
    Given I store the schedulable workers in the :schedule_workers clipboard
    Given I open admin console in a browser
    When I run the :browse_to_nodes_page web action
    Then the step should succeed
    When I run the :check_node_list_column_headers web action
    Then the step should succeed

    # check node has terminal tab page
    When I perform the :click_link_with_text_only web action with:
      | text | <%= cb.schedule_workers[0].name %> |
    Then the step should succeed
    When I run the :click_terminal_tab web action
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource       | pods |
      | all_namespaces | true |
    Then the step should succeed
    And the output should match "<%= cb.schedule_workers[0].name %>.*debug.*Running"
    """
    When I run the :check_messages_on_terminal_page web action
    Then the step should succeed

