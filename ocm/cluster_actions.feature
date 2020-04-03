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
    | cluster_name         | sdqe-ui-default |
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
    | compute_node_number    | 7 |
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
    | cluster_name | sdqe-ui-ocp  |
  Then the step should succeed
  When I run the :expand_actions_on_cluster_detail_page web action
  Then the step should succeed
  When I run the :check_actions_items_of_ready_ocp_cluster_on_detail web action
  Then the step should succeed