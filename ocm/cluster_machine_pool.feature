Feature: This is for cluster machine pools testing

  # @author xueli@redhat.com
  # @case_id OCP-35970
  Scenario: User can create machine pools to cluster via UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    When I run the :switch_to_machine_pools_tab web action
    Then the step should succeed
    When I perform the :create_machine_pool web action with:
      | machine_pool_name | ocp-35970          |
      | machine_type      | m5.2xlarge         |
      | compute_node      | 1                  |
      | row_number        | 0                  |
      | label_key         | openshift.com/test |
      | label_value       | labelvalue1        |
      | taint_row_number  | 0                  |
      | taint_key         | taint_k            |
      | taint_value       | taint_v            |
      | taint_effect      | NoExecute          |
    Then the step should succeed
    When I perform the :check_specified_machine_pool web action with:
      | machine_pool_name  | ocp-35970          |
      | instance_type      | m5.2xlarge         |
      | node_count         | 1                  |
      | row_number         | 2                  |
      | availability_zones | us-east-1a         |
      | taint_key          | taint_k            |
      | taint_value        | taint_v            |
      | taint_effect       | NoExecute          |
      | label_key          | openshift.com/test |
      | label_value        | labelvalue1        |
    Then the step should succeed
    When I perform the :delete_machine_pool web action with:
      | machine_pool_name  | ocp-35970 |
    Then the step should succeed
    When I perform the :check_machine_pool_disappeared web action with:
      | machine_pool_name  | ocp-35970 |
      | row_number         | 2         |
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-35974
  Scenario: Check Machine pool creation dialog
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-gcp |
    When I run the :switch_to_machine_pools_tab web action
    Then the step should succeed
    When I perform the :check_specified_machine_pool web action with:
      | machine_pool_name  | Default                            |
      | instance_type      | custom-4-32768-ext                 |
      | node_count         | 9                                  |
      | row_number         | 1                                  |
      | availability_zones | us-east1-b, us-east1-c, us-east1-d |
    Then the step should succeed
    When I perform the :delete_machine_pool web action with:
      | machine_pool_name  | Default |
    Then the step should fail
    When I run the :click_add_machine_pool_button web action
    Then the step should succeed
    When I perform the :check_machine_pool_dialog web action with:
      | row_number          | 1         |
      | label_key           | tlabelk   |
      | label_value         | tlabelv   |
      | compute_node_number | 1         |
      | taint_row_number    | 1         |
      | taint_key           | taint_k   |
      | taint_value         | taint_v   |
      | taint_effect        | NoExecute |
    Then the step should succeed
    When I perform the :click_delete_node_label_button web action with:
      | row_number | 1 |
    Then the step should succeed
    When I perform the :click_delete_taint_button web action with:
      | taint_row_number | 1 |
    Then the step should succeed
    When I perform the :input_label web action with:
      | row_number  | 1       |
      | label_key   | tlabelk |
      | label_value | tlabelv |
    Then the step should fail
    When I perform the :set_taint web action with:
      | taint_row_number | 1         |
      | taint_key        | taint_k   |
      | taint_value      | taint_v   |
      | taint_effect     | NoExecute |
    Then the step should fail
    When I perform the :check_existed_label web action with:
      | label_key   | tlabelk |
      | label_value | tlabelv |
    Then the step should fail
    When I perform the :check_existed_taint web action with:
      | taint_row_number | 0       |
      | taint_key        | taint_k |
      | taint_value      | taint_v |
    Then the step should fail
    When I perform the :add_new_label web action with:
      | row_number  | 1       |
      | label_key   | tlabelk |
      | label_value | tlabelv |
    Then the step should succeed
    When I perform the :click_delete_node_label_button web action with:
      | row_number | 0 |
    Then the step should succeed
    When I perform the :check_existed_label web action with:
      | label_key   | tlabelk |
      | label_value | tlabelv |
    Then the step should succeed
    When I run the :click_add_machine_pool_button_on_dialog web action
    Then the step should succeed
    When I perform the :error_information_loaded web action with:
      | error_message_locator | name-helper                    |
      | error_reason          | Machine pool name is required. |
    Then the step should succeed
    Given I saved following keys to list in :names clipboard:
      | приветPékinاختبار ||
      | ^^^^^             ||
      | under_line        ||
      | 123numname        ||
      | -crossstart       ||
      | QWert123456       ||
    When I repeat the following steps for each :name in cb.names:
    """
    When I perform the :input_machine_pool_name web action with:
      | machine_pool_name | #{cb.name} |
    Then the step should succeed
    When I run the :click_add_machine_pool_button_on_dialog web action
    Then the step should succeed
    When I perform the :error_information_loaded web action with:
      | error_message_locator | name-helper                                                                 |
      | error_reason          | start with an alphabetic character, and end with an alphanumeric character. |
    Then the step should succeed
    """
    ################# need to implement the label part when related bug fixed #################################

  # @author xueli@redhat.com
  # @case_id OCP-35986
  Scenario: Check the Edit node count dialog
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    When I run the :switch_to_machine_pools_tab web action
    Then the step should succeed
    When I perform the :create_machine_pool web action with:
      | machine_pool_name | ocp-35986          |
      | machine_type      | m5.2xlarge         |
      | compute_node      | 1                  |
      | row_number        | 1                  |
      | label_key         | openshift.com/test |
      | label_value       | labelvalue1        |
    Then the step should succeed
    When I perform the :click_scale_machine_pool_button web action with:
      | machine_pool_name | ocp-35986 |
    Then the step should succeed
    Given I saved following keys to list in :machinepoolnames clipboard:
      | Default   ||
      | ocp-35986 ||
    When I repeat the following steps for each :machinepoolname in cb.machinepoolnames:
    """
    When I perform the :select_machine_pool_name web action with:
      | machine_pool_name | #{cb.machinepoolname} |
    Then the step should succeed
    """
    Given I saved following keys to list in :machinepoolnodes clipboard:
      | 0 ||
      | 1 ||
    When I repeat the following steps for each :machinepoolnode in cb.machinepoolnodes:
    """
    When I perform the :select_node_count web action with:
      | compute_node | #{cb.machinepoolnode} |
    Then the step should succeed
    """
    When I run the :click_cancel_button web action
    Then the step should succeed
    When I perform the :delete_machine_pool web action with:
      | machine_pool_name  | ocp-35986 |
    Then the step should succeed
    When I perform the :check_machine_pool_disappeared web action with:
      | machine_pool_name  | ocp-35986 |
      | row_number         | 2         |
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-35971
  Scenario: User can edit machine pools to cluster via UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    When I run the :switch_to_machine_pools_tab web action
    Then the step should succeed
    When I perform the :create_machine_pool web action with:
      | machine_pool_name | ocp-35971          |
      | machine_type      | m5.2xlarge         |
      | compute_node      | 1                  |
      | row_number        | 1                  |
      | label_key         | openshift.com/test |
      | label_value       | labelvalue1        |
    Then the step should succeed
    When I perform the :edit_machine_pool web action with:
      | machine_pool_name | ocp-35971 |
      | compute_node      | 0         |
    Then the step should succeed
    When I perform the :check_specified_machine_pool web action with:
      | machine_pool_name  | ocp-35971  |
      | instance_type      | m5.2xlarge |
      | node_count         | 0          |
      | row_number         | 2          |
      | availability_zones | us-east-1a |
    Then the step should succeed
    When I perform the :delete_machine_pool web action with:
      | machine_pool_name  | ocp-35971 |
    Then the step should succeed
    When I perform the :check_machine_pool_disappeared web action with:
      | machine_pool_name  | ocp-35971 |
      | row_number         | 2         |
    Then the step should succeed
