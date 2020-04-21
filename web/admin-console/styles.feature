  Feature: console style related

  # @author xiaocwan@redhat.com
  # @case_id OCP-27590
  @admin
  Scenario: Migrate PF3 modals to PF4
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    When I open admin console in a browser
    Then the step should succeed

    # check operator creation side dialog panel
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I run the :open_first_card_overlay_panel web action
    Then the step should succeed
    When I run the :check_side_overlay_dialog_modal web action
    Then the step should succeed

    # check namespace creation overlay modal
    When I run the :goto_namespace_list_page web action
    Then the step should succeed
    When I run the :click_yaml_create_button web action
    Then the step should succeed
    When I run the :check_overlay_edit_modal web action
    Then the step should succeed

    # check resource edit overlay modal
    When I perform the :goto_one_deployment_page web action with:
      | project_name | openshift-console |
      | deploy_name  | console           |
    Then the step should succeed
    When I run the :click_annotation_edit_link web action
    Then the step should succeed
    When I run the :check_overlay_edit_modal_title web action
    Then the step should succeed
    