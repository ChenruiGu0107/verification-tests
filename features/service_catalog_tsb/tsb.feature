Feature: Template service broker related features

  # @author xiuwang@redhat.com
  # @case_id  ocp-18230
  Scenario: deprovision an unready serviceinstance
    Given the master version >= "3.7"
    And I have a project
    When I run the :goto_home_page web console action
    Then the step should succeed
    When I perform the :provision_from_unbindable_template_on_homepage web console action with:
      | primary_catagory | Languages                      |
      | sub_catagory     | Ruby                           |
      | service_item     | Rails + PostgreSQL (Ephemeral) |
    Then the step should succeed
    When I get project serviceinstances as JSON
    And evaluation of `service_instance.name` is stored in the :svcinstancename clipboard
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance |
    Then the step should succeed
    And the output should match:
      | Message:\\s+The instance is being provisioned asynchronously |
    """
    When I perform the :goto_overview_page web console action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :delete_serviceinstance_on_overview_page web console action with:
      | resource_name | Rails + PostgreSQL (Ephemeral)|
    Then the step should succeed
    And I wait for the resource "serviceinstance" named "<%= cb.svcinstancename %>" to disappear within 300 seconds

    When I run the :goto_home_page web console action
    Then the step should succeed
    When I perform the :provision_serviceclass_with_binding_on_homepage web console action with:
      | primary_catagory | Databases           |
      | sub_catagory     | Mongo               |
      | service_item     | MongoDB (Ephemeral) |
    Then the step should succeed
    When I get project serviceinstances as JSON
    And evaluation of `service_instance.name` is stored in the :svcinstancename clipboard
    When I get project servicebinding as JSON
    And evaluation of `service_binding` is stored in the :svcbindingname clipboard
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance |
    Then the step should succeed
    And the output should match:
      | Message:\\s+The instance is being provisioned asynchronously |
    """
    When I perform the :goto_overview_page web console action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :delete_serviceinstance_on_overview_page web console action with:
      | resource_name | MongoDB (Ephemeral) |
      | project_name  | <%= project.name %> |
    Then the step should succeed
    And I wait for the resource "serviceinstance" named "<%= cb.svcinstancename %>" to disappear within 300 seconds
    And I wait for the resource "serviceinstance" named "<%= cb.svcbindingname %>" to disappear
