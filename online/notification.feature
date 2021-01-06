Feature: Online "Notification" related scripts in this file

  # @author bingli@redhat.com
  # @case_id OCP-12941
  Scenario: Extra key/value in the notification ConfigMap will be warned
    Given I have a project
    When I perform the :goto_notification_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :config_deployment_notification web console action with:
      | checkbox_value | true |
    Then the step should succeed
    When I run the :save_notification_config web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | configmap                      |
      | resource_name | openshift-online-notifications |
      | template      | {{.data}}                      |
    Then the step should succeed
    And the output should contain:
      | deployments:true |
      | torage:false     |
      | builds:false     |
    When I run the :patch client command with:
      | resource      | configmap                      |
      | resource_name | openshift-online-notifications |
      | p             | {"data":{"key1":"value1"}}     |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | configmap                      |
      | resource_name | openshift-online-notifications |
      | template      | {{.data}}                      |
    Then the step should succeed
    And the output should contain:
      | key1:value1 |
    When I perform the :check_notification_extra_value_warning web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

  # @author bingli@redhat.com
  # @case_id OCP-10480
  Scenario: Error messages should show if there's conflict when saving the notification configuration
    Given I have a project
    When I perform the :goto_notification_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :config_deployment_notification web console action with:
      | checkbox_value | true |
    Then the step should succeed
    When I run the :save_notification_config web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | configmap                      |
      | resource_name | openshift-online-notifications |
      | template      | {{.data}}                      |
    Then the step should succeed
    And the output should contain:
      | deployments:true |
      | torage:false     |
      | builds:false     |
    When I run the :patch client command with:
      | resource      | configmap                        |
      | resource_name | openshift-online-notifications   |
      | p             | {"data":{"deployments":"false"}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | configmap                      |
      | resource_name | openshift-online-notifications |
      | template      | {{.data}}                      |
    Then the step should succeed
    And the output should contain:
      | deployments:false |
    When I perform the :config_storage_notification web console action with:
      | checkbox_value | true |
    Then the step should succeed
    When I run the :check_notification_save_conflict_error web console action
    Then the step should succeed

  # @author yuwan@redhat.com
  Scenario Outline: Check notification alert message and related buttons on online
  Given I have a project
  Then evaluation of `project.name` is stored in the :project_name clipboard
  When I run the :new_app client command with:
    | template | mongodb-persistent                |
    | p        | MEMORY_LIMIT=<memory_limit>       |
  Then the step should succeed
  When I perform the :open_notification_drawer_on_overview web console action with:
    | project_name | <%= project.name %> |
  Then the step should succeed
  When I perform the :check_message_context_in_drawer web console action with:
    | status   | at             |
    | using    | 100%           |
    | total    | <total_memory> |
    | resource | memory (limit) |
  Then the step should succeed
  When I perform the :check_buttons_in_kebab web console action with:
    | status   | at             |
    | using    | 100%           |
    | total    | <total_memory> |
    | resource | memory (limit) |
  Then the step should succeed
  When I run the :check_mark_all_read_button_on_notification_drawer web action
  Then the step should succeed
  When I run the :check_clear_all_button_on_notification_drawer web action
  Then the step should succeed

  Examples:
    | memory_limit | total_memory |
    | 1Gi          | 1 GiB        | # @case_id OCP-20940
    | 2Gi          | 2 GiB        | # @case_id OCP-19978
