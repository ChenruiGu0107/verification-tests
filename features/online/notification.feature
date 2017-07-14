Feature: Online "Notification" related scripts in this file

  # @author bingli@redhat.com
  # @case_id OCP-12870
  Scenario: Notification UI should correctly display in web console
    Given I have a project
    When I perform the :check_notification_message web console action with:
      | project_name | <%= project.name %> |
      | user_name    | <%= user.name %>    |
    Then the step should succeed

  # @author bingli@redhat.com
  # @case_id OCP-10334
  # @case_id OCP-10341
  Scenario: Enable/Disable online notification in web console - UI
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
      | template      | {{.data.deployments}}          |
    Then the step should succeed
    And the output should contain "true"
    When I perform the :config_build_notification web console action with:
      | checkbox_value | true |
    Then the step should succeed
    When I run the :save_notification_config web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | configmap                      |
      | resource_name | openshift-online-notifications |
      | template      | {{.data.builds}}               |
    Then the step should succeed
    And the output should contain "true"
    When I perform the :config_storage_notification web console action with:
      | checkbox_value | true |
    Then the step should succeed
    When I run the :save_notification_config web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | configmap                      |
      | resource_name | openshift-online-notifications |
      | template      | {{.data.storage}}              |
    Then the step should succeed
    And the output should contain "true"
    When I perform the :config_deployment_notification web console action with:
      | checkbox_value | false |
    Then the step should succeed
    When I perform the :config_build_notification web console action with:
      | checkbox_value | false |
    Then the step should succeed
    When I perform the :config_storage_notification web console action with:
      | checkbox_value | false |
    Then the step should succeed
    When I run the :save_notification_config web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | configmap                      |
      | resource_name | openshift-online-notifications |
      | template      | {{.data}}                      |
    Then the step should succeed
    And the output should contain:
      | deployments:false |
      | torage:false      |
      | builds:false      |

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
