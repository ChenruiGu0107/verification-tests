Feature: create app on web console related
  # @author yapei@redhat.com
  # @case_id OCP-15453
  Scenario: Secret can be viewed from the results step of Create Binding dialog
    # since it's 3.6 tech preview, no scripts for 3.6, need TSB running
    Given the master version >= "3.6"
    Given I have a project
    When I run the :goto_home_page web console action
    Then the step should succeed
    # check secret is shown when provision from homepage wizard
    When I perform the :provision_serviceclass_with_binding_and_wait_secret_shown web console action with:
      | primary_catagory | Databases           |
      | sub_catagory     | Mongo               |
      | service_item     | MongoDB (Ephemeral) |
    Then the step should succeed
    Given I wait for all serviceinstances in the project to become ready
    And I wait for all servicebindings in the project to become ready
    When I run the :wait_secret_showing_in_successful_result web console action
    Then the step should succeed
    When I run the :click_close web console action
    Then the step should succeed
    # check secret is shown when create binding from overview
    When I perform the :create_binding_on_overview_page web console action with:
      | project_name  | <%= project.name %> |
      | resource_name | MongoDB             |
    Then the step should succeed
    Given I wait for all servicebindings in the project to become ready
    When I run the :wait_secret_showing_in_successful_result web console action
    Then the step should succeed
