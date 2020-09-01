Feature: only about page related to cluster actions

  # @author yuwan@redhat.com
  # @case_id OCP-22117
  Scenario: Edit display_name on UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :expand_cluster_actions_on_cluster_list_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I perform the :edit_display_name_on_cluster_list_page web action with:
      | original_name | sdqe-ui-default     |
      | new_name      | sdqe-ui-default-new |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default-new |
    Then the step should succeed
    When I run the :expand_actions_on_cluster_detail_page web action
    Then the step should succeed
    When I perform the :edit_display_name_on_cluster_detail_page web action with:
      | original_name | sdqe-ui-default-new |
      | new_name      | sdqe-ui-default     |
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-21686
  Scenario: Check the elements on 'Scale Cluster' dialog
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_scale_cluster_dialog_on_cluster_list_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :check_elements_in_scale_cluster_dialog web action
    Then the step should succeed
    When I run the :click_cancel_button web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :go_to_scale_cluster_dialog_on_cluster_detail_page web action
    Then the step should succeed
    When I run the :check_elements_in_scale_cluster_dialog web action
    Then the step should succeed
    When I run the :click_cancel_button web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-21685
  Scenario: The user can resize the cluster nodes in the status of "Ready" on the UHC portal
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :scale_cluster_from_cluster_list_page web action with:
      | cluster_name        | sdqe-ui-default |
      | compute_node_number | 6               |
    Then the step should succeed
    When I perform the :scale_cluster_from_cluster_list_page web action with:
      | cluster_name        | sdqe-ui-default |
      | compute_node_number | 9               |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I perform the :check_scale_result_on_detail_page web action with:
      | expect_status         | ready |
      | desired_compute_nodes | 9     |
    Then the step should succeed
    When I perform the :scale_cluster_from_cluster_detail_page web action with:
      | compute_node_number | 7 |
    Then the step should succeed
    When I perform the :check_scale_result_on_detail_page web action with:
      | expect_status         | ready |
      | desired_compute_nodes | 7     |
    Then the step should succeed
    When I perform the :scale_cluster_from_cluster_detail_page web action with:
      | compute_node_number | 4 |
    Then the step should succeed
    When I perform the :check_scale_result_on_detail_page web action with:
      | expect_status         | ready |
      | desired_compute_nodes | 4     |
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-22599
  Scenario: Check the cluster actions dropdown menu of the cluster in the "Ready" status
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :expand_cluster_actions_on_cluster_list_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :check_actions_items_of_ready_osd_cluster_on_list web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :expand_actions_on_cluster_detail_page web action
    Then the step should succeed
    When I run the :check_actions_items_of_ready_osd_cluster_on_detail web action
    Then the step should succeed
    When I run the :click_clusters_url web action
    Then the step should succeed
    When I perform the :expand_cluster_actions_on_cluster_list_page web action with:
      | cluster_name | sdqe-ui-ocp |
    Then the step should succeed
    When I run the :check_actions_items_of_ready_ocp_cluster_on_list web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-ocp |
    Then the step should succeed
    When I run the :expand_actions_on_cluster_detail_page web action
    Then the step should succeed
    When I run the :check_actions_items_of_ready_ocp_cluster_on_detail web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-26640
  Scenario: Check the layout of the Setting storage and load balancer quota in the cluster creation page   
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :switch_to_osd_creation_page web action with:
      | product_id     | osd |
      | cloud_provider | aws |
    Then the step should succeed
    When I run the :check_persistent_storage_field_in_creation_page web action
    Then the step should succeed
    When I run the :check_lb_field_in_creation_page web action
    Then the step should succeed
    When I run the :check_persistent_storage_popover_message web action
    Then the step should succeed
    When I run the :check_lb_popover_message web action
    Then the step should succeed
    When I run the :click_customer_cloud_subscription web action
    Then the step should succeed
    When I run the :close_customer_cloud_subscription_prompt_message web action
    Then the step should succeed
    When I run the :check_persistent_storage_field_in_creation_page_missing web action
    Then the step should succeed
    When I run the :check_lb_field_in_creation_page_missing web action
    Then the step should succeed
    
  # @author xueli@redhat.com
  # @case_id OCP-27557
  Scenario: Edit buttons should only be enabled in disconnected cluster dropdown for user with right access
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :expand_cluster_actions_on_cluster_list_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :check_enabled_actions_in_dropdown web action with:
      | edit_cluster_registration_button ||
      | edit_display_name_button         ||
      | archive_button                   ||
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I run the :expand_actions_on_cluster_detail_page web action
    Then the step should succeed
    When I perform the :check_enabled_actions_in_dropdown web action with:
      | edit_cluster_registration_button ||
      | edit_display_name_button         ||
      | archive_button                   ||
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :expand_cluster_actions_on_cluster_list_page web action with:
      | cluster_name | sdqe-ui-adminowned-disconnected |
    Then the step should succeed
    When I perform the :check_missing_actions_in_dropdown web action with:
      | edit_cluster_registration_button ||
      | edit_display_name_button         ||
      | add_console_url_button           ||
      | archive_button                   ||
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-adminowned-disconnected |
    Then the step should succeed
    When I run the :check_disabled_actions_on_cluster_detail_page web action
    Then the step should succeed
    
  # @author xueli@redhat.com
  # @case_id OCP-27556
  Scenario: User can update disconnected cluster via UI
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :open_cluster_registration_dialog_from_cluster_list_page web action with:
      | cluster_name | sdqe-ui-disconnected |
    Then the step should succeed
    When I perform the :check_cluster_registration_dialog web action with:
      | sockets_type ||
    Then the step should succeed
    When I perform the :check_cluster_registration_dialog_default_value web action with:
      | default_sockets_value | 10 |
      | default_memory_value  | 10 |
      | default_node_value    | 10 |
    Then the step should succeed
    When I perform the :edit_cluster_registration web action with:
      | sockets_value | 9    |
      | memory_value  | 10.3 |
      | node_value    | 8    |
      | save          |      |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :open_cluster_registration_dialog_from_cluster_list_page web action with:
      |cluster_name|sdqe-ui-disconnected|
    Then the step should succeed
    When I perform the :edit_cluster_registration web action with:
      | sockets_value | 10 |
      | memory_value  | 10 |
      | node_value    | 10 |
      | save          |    |
    Then the step should succeed
    """
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-disconnected |
    Then the step should succeed
    When I perform the :check_cluster_metrics web action with:
      | total_sockets_value | 9    |
      | total_memory_value  | 10.3 |
      | total_node_value    | 8    | 
    Then the step should succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-adminowned-ui-disconnected |
    Then the step should succeed
    When I perform the :check_cluster_registration_dialog web action with:
      | vcpu_type ||
    Then the step should succeed
    When I perform the :check_cluster_registration_dialog_default_value web action with:
      | default_vcpu_value   | 11 |
      | default_memory_value | 0  |
      | default_node_value   | 0  |
    Then the step should succeed
    When I perform the :edit_cluster_registration web action with:
      | vcpu_value   | 9    |
      | memory_value | 10.3 |
      | node_value   | 8    |
      | cancel       |      |
    Then the step should succeed
    When I perform the :open_cluster_registration_dialog_from_cluster_list_page web action with:
      | cluster_name | sdqe-adminowned-ui-disconnected |
    Then the step should succeed
    When I perform the :check_cluster_registration_dialog web action with:
      | vcpu_type ||
    Then the step should succeed
    When I perform the :check_cluster_registration_dialog_default_value web action with:
      | default_vcpu_value   | 11 |
      | default_memory_value | 0  |
      | default_node_value   | 0  |
    Then the step should succeed
    When I perform the :edit_cluster_registration web action with:
      | cancel ||
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-21796
  Scenario: Delete an advanced OSD ready cluster can successfully
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-advanced |
    Then the step should succeed
    When I perform the :delete_osd_cluster_from_detail_page web action with:
      | cluster_name   | sdqe-ui-advanced |
      | input_text     | sdqe-ui-advanced |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-advanced |
    Then the step should succeed
    When I perform the :wait_cluster_status_on_detail_page web action with:
      | cluster_status | uninstalling |
    Then the step should succeed
    When I perform the :uninstall_succ_prompt_message_displayed web action with:
      | cluster_name   | sdqe-ui-advanced |
    Then the step should succeed
    When I perform the :uninstall_succ_prompt_message_missing web action with:
      | cluster_name   | sdqe-ui-advanced |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-advanced |
    Then the step should fail

  # @author yuwan@redhat.com
  # @case_id OCP-26848
  Scenario: Check the warning message under the Load Balancers + Persistent Storage from scaling down
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :scale_loadbalancer_from_cluster_list_page web action with:
      | cluster_name          | sdqe-ui-default |
      | load_balancers_number | 8               |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I perform the :scale_loadbalancer_from_cluster_list_page web action with:
      | cluster_name          | sdqe-ui-default |
      | load_balancers_number | 0               |
    Then the step should succeed
    """
    When I perform the :scale_persistent_quota_from_cluster_list_page web action with:
      | cluster_name              | sdqe-ui-default  |
      | persistent_storage_number | 1100 GiB         |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I perform the :scale_persistent_quota_from_cluster_list_page web action with:
      | cluster_name              | sdqe-ui-default  |
      | persistent_storage_number | 100 GiB          |
    Then the step should succeed
    """
    When I perform the :go_to_scale_cluster_dialog_on_cluster_list_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :click_persistent_quota_dropdown web action
    Then the step should succeed
    When I perform the :select_persistent_quota_in_dialog web action with:
      | persistent_storage_number | 600 GiB |
    Then the step should succeed
    When I run the :check_persistent_storage_scaledown_warning_message web action
    Then the step should succeed
    When I perform the :select_persistent_quota_in_dialog web action with:
      | persistent_storage_number | 1100 GiB |
    Then the step should succeed
    When I run the :check_persistent_storage_scaledown_warning_message_missing web action
    Then the step should succeed
    When I perform the :select_loadbalancer_in_dialog web action with:
      | load_balancers_number | 4 |
    Then the step should succeed
    When I run the :check_loadbalancer_scaledown_warning_message web action
    Then the step should succeed
    When I perform the :select_loadbalancer_in_dialog web action with:
      | load_balancers_number | 8 |
    Then the step should succeed
    When I run the :check_loadbalancer_scaledown_warning_message_missing web action
    Then the step should succeed
    When I run the :click_cancel_button web action
    Then the step should succeed
  
  # @author yuwan@redhat.com
  # @case_id OCP-26641
  Scenario: Scale storage and load balancer quota for the existing cluster on UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :scale_persistent_quota_from_cluster_list_page web action with:
      | persistent_storage_number | 100 GiB         |
      | cluster_name              | sdqe-ui-default |
    Then the step should succeed
    When I perform the :scale_loadbalancer_from_cluster_list_page web action with:
      | load_balancers_number | 0               |
      | cluster_name          | sdqe-ui-default |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I perform the :check_persistent_storage_on_detail_page web action with:
      | persistent_storage_value | 100 |
    Then the step should succeed
    When I perform the :check_load_balancer_on_detail_page web action with:
      | load_balancer_value | 0 |
    Then the step should succeed
    """
    When I perform the :scale_loadbalancer_from_cluster_list_page web action with:
      | cluster_name          | sdqe-ui-default |
      | load_balancers_number | 8               |
    Then the step should succeed
    When I perform the :scale_persistent_quota_from_cluster_list_page web action with:
      | cluster_name              | sdqe-ui-default  |
      | persistent_storage_number | 1100 GiB         |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I perform the :check_load_balancer_on_detail_page web action with:
      | load_balancer_value | 8 |
    Then the step should succeed
    When I perform the :check_persistent_storage_on_detail_page web action with:
      | persistent_storage_value | 1100 |
    Then the step should succeed
    When I perform the :scale_load_balancer_from_cluster_detail_page web action with:
      | load_balancers_number | 4 |
    Then the step should succeed
    When I perform the :scale_persistent_quota_from_cluster_detail_page web action with:
      | persistent_storage_number | 600 GiB |
    Then the step should succeed
    When I perform the :check_load_balancer_on_detail_page web action with:
      | load_balancer_value | 4 |
    Then the step should succeed
    When I perform the :check_persistent_storage_on_detail_page web action with:
      | persistent_storage_value | 600 |
    Then the step should succeed
    
