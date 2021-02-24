Feature: only about add-on page for OSD cluster
  
  # @author xueli@redhat.com
  # @case_id OCP-26501
  Scenario: Add-on can be installed successfully via Add-on tab with enough quota
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
      | addons_tab   |                 |
    Then the step should succeed
    When I perform the :install_addon web action with:
      | addon_name  | Prow Operator |
    Then the step should succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-adminosd |
      | addons_tab   |               |
    Then the step should succeed
    When I perform the :click_addon_install_button web action with:
      | addon_name | Prow Operator |
    Then the step should fail
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
      | addons_tab   |                 |
    Then the step should succeed
    When I perform the :wait_for_addon_to_status web action with:
      | addon_name  | Prow Operator |
      | wait_status | Add-on failed |
      | timeout     | 1200          |
    Then the step should succeed
    When I perform the :delete_addon web action with:
      | addon_name | Prow Operator |
      | input_text | Prow Operator |
    Then the step should succeed
    When I perform the :wait_for_addon_install_button_show web action with:
      | addon_name | Prow Operator |
      | timeout    | 5             |
    Then the step should succeed
  
  # @author xueli@redhat.com
  # @case_id OCP-37143
  Scenario: The add-on can be deleted from OCM UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
      | addons_tab   |                 |
    Then the step should succeed
    When I perform the :install_addon web action with:
      | addon_name               | API Management service |
      | set_parameter            |                        |
      | set_cidr_default         |                        |
      | parameter_key            | notification-email     |
      | parameter_value          | xueli@redhat.com       |
      | parameter_input_finished |                        |
    Then the step should succeed
    When I perform the :delete_addon web action with:
      | addon_name | API Management service |
      | input_text | API Management service |
    Then the step should succeed
    When I perform the :wait_for_addon_to_status web action with:
      | wait_status | Uninstalling           |
      | timeout     | 10                     |
      | addon_name  | API Management service |
    Then the step should succeed
    When I perform the :wait_for_addon_install_button_show web action with:
      | addon_name | API Management service |
      | timeout    | 1800                   |
    Then the step should succeed
    

  # @author xueli@redhat.com
  # @case_id OCP-37144
  Scenario: Check the UI page for add-on deletion
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-adminosd |
      | addons_tab   |               |
    Then the step should succeed
    When I perform the :install_addon web action with:
      | addon_name  | Prow Operator |
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-adminosd |
      | addons_tab   |               |
    When I perform the :no_permission_tooltip_display web action with:
      | addon_name | Prow Operator |
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-adminosd |
      | addons_tab   |               |
    Then the step should succeed
    When I perform the :click_delete_addon_button web action with:
      | addon_name | Prow Operator |
    Then the step should succeed
    When I perform the :check_addon_deletion_dialog web action with:
      | addon_name | Prow Operator |
    Then the step should succeed
    When I perform the :check_uninstall_button web action with:
      | input_text      | invalid |
      | button_disabled |         |
    Then the step should succeed
    When I perform the :check_uninstall_button web action with:
      | input_text     | Prow Operator |
      | button_enabled |               |
    Then the step should succeed
    When I run the :click_addon_uninstall_button web action
    Then the step should succeed
    When I run the :click_addon_uninstall_button web action
    Then the step should fail
