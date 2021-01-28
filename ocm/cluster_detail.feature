Feature: Only for case related to cluster detail page

  # @author xueli@redhat.com
  # @case_id OCP-23050
  Scenario: Users can see logs on UI for installing or uninstalling OSD clusters
    Given I open ocm portal as a orgAdmin user
    Then the step should succeed
    When I perform the :create_osd_cluster web action with:
      | product_id     | osd          |
      | cloud_provider | aws          |
      | cluster_name   | sdqe-ui-logs |
    Then the step should succeed
    When I perform the :check_cluster_logs web action with:
      | installation ||
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-logs |
    Then the step should succeed
    When I perform the :check_osd_usage_in_detail_page web action with:
      | installing ||
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as a orgAdmin user
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-logs |
    Then the step should succeed
    When I perform the :delete_osd_cluster_from_detail_page web action with:
      | cluster_name | sdqe-ui-logs |
      | input_text   | sdqe-ui-logs |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-logs |
    Then the step should succeed
    When I perform the :check_cluster_logs web action with:
      | uninstallation ||
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-logs |
    Then the step should succeed
    When I perform the :check_osd_usage_in_detail_page web action with:
      | uninstalling ||

    # Add a successful step to make sure browser close action will succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as a regularUser user
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I perform the :check_cluster_logs web action with:
      | cluster_type | OSD |
    Then the step should fail
    When I perform the :go_to_cluster_list_page web action with:
      | from_page | cluster_detail_page |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :check_cluster_logs web action with:
      | cluster_type | OCP |
    Then the step should fail

  # @author xueli@redhat.com
  # @case_id OCP-25343
  Scenario: Monitoring tab can display and work correctly for OCP and OSD clusters
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    Given I saved following keys to list in :clusters clipboard:
      | sdqe-ui-default ||
    When I repeat the following steps for each :cluster_name in cb.clusters:
    """
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | #{cb.cluster_name}  |
    Then the step should succeed
    When I perform the :check_monitoring_tab web action with:
      | issue_number | No |
    Then the step should succeed
    When I perform the :go_to_cluster_list_page web action with:
      | from_page | cluster_detail_page |
    Then the step should succeed
    """
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-26404
  Scenario: Check the validation for the user tab in detail page
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_access_control_tab web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :click_add_user_button_on_page web action
    Then the step should succeed
    When I perform the :input_user_in_tab web action with:
      | user_id | test:test |
    Then the step should succeed
    When I perform the :check_user_validation_message web action with:
      | validation_error_message | User ID cannot contain |
      | validated_charactor      | :                      |
    Then the step should succeed
    When I perform the :input_user_in_tab web action with:
      | user_id | test/test |
    Then the step should succeed
    When I perform the :check_user_validation_message web action with:
      | validation_error_message | User ID cannot contain |
      | validated_charactor      | /                      |
    Then the step should succeed
    When I perform the :input_user_in_tab web action with:
      | user_id | test%test |
    Then the step should succeed
    When I perform the :check_user_validation_message web action with:
      | validation_error_message | User ID cannot contain |
      | validated_charactor      | %                      |
    Then the step should succeed
    When I perform the :input_user_in_tab web action with:
      | user_id | ' test' |
    Then the step should succeed
    When I perform the :check_user_validation_message web action with:
      | validation_error_message | User ID cannot contain      |
      | validated_charactor      | leading and trailing spaces |
    Then the step should succeed
    When I perform the :input_user_in_tab web action with:
      | user_id | 'test  ' |
    Then the step should succeed
    When I perform the :check_user_validation_message web action with:
      | validation_error_message | User ID cannot contain      |
      | validated_charactor      | leading and trailing spaces |
    Then the step should succeed
    When I perform the :input_user_in_tab web action with:
      | user_id | . |
    Then the step should succeed
    When I perform the :check_user_validation_message web action with:
      | validation_error_message | User ID cannot be |
      | validated_charactor      | .                 |
    Then the step should succeed
    When I perform the :input_user_in_tab web action with:
      | user_id | .. |
    Then the step should succeed
    When I perform the :check_user_validation_message web action with:
      | validation_error_message | User ID cannot be |
      | validated_charactor      | ..                |
    Then the step should succeed
    When I perform the :input_user_in_tab web action with:
      | user_id | '~' |
    Then the step should succeed
    When I perform the :check_user_validation_message web action with:
      | validation_error_message | User ID cannot be |
      | validated_charactor      | ~                 |
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-23866
  Scenario: Add/delete users for the cluster on the UHC portal
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_access_control_tab web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :click_add_user_button_on_page web action
    Then the step should succeed
    When I perform the :add_user web action with:
      | user_id    | test_user_1      |
      | user_group | dedicated-admins |
    Then the step should succeed
    When I perform the :check_user_added web action with:
      | user_id    | test_user_1      |
      | user_group | dedicated-admins |
    Then the step should succeed
    When I run the :click_add_user_button_on_page web action
    Then the step should succeed
    When I perform the :add_user web action with:
      | user_id    | test_user_1      |
      | user_group | dedicated-admins |
    Then the step should succeed
    When I perform the :check_danger_alert_box_in_user_tab web action with:
      | error_massage | already exists on group  |
    Then the step should succeed
    When I run the :click_cancel_add_user_button web action
    Then the step should succeed
    When I perform the :delete_user web action with:
      | user_id | test_user_1 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I perform the :check_the_user_list_item web action with:
      | user_id    | test_user_1      |
      | user_group | dedicated-admins |
    Then the step should fail
    """

  # @author xueli@redhat.com
  # @case_id OCP-29668
  Scenario: Check all of the elements on Networking tab
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I perform the :check_network_configuration web action with:
      | trimed_cluster_name | sdqe-ui-default |
      | machine_cidr        | 10.0.0.0/16     |
      | service_cidr        | 172.30.0.0/16   |
      | pod_cidr            | 10.128.0.0/14   |
      | host_prefix         | /23             |
      | timeout             | 300             |
    Then the step should succeed
    When I run the :click_enable_additional_route web action
    Given I saved following keys to list in :labels clipboard:
      | abcd                                                                   ||
      | a=b,                                                                   ||
      | a=b,c                                                                  ||
      | longerthan63characterslongerthan63characterslongerthan63characte=value ||
      | key=longerthan63characterslongerthan63characterslongerthan63characte   ||
    When I repeat the following steps for each :label in cb.labels:
    """
    When I perform the :check_invalid_label_error_message web action with:
      | label        | #{cb.label}                               |
      | error_message| Comma separated pairs in key=value format |
    Then the step should succeed
    """
    When I perform the :clear_input web action with:
      | locator_id | labels_additional_router |
    Then the step should succeed
    When I run the :click_change_settings_button_on_page web action
    Then the step should succeed
    When I perform the :check_change_cluster_privacy_settings_dialog web action with:
      | cancel_dialog ||
    Then the step should succeed
    When I run the :click_default_route_private_checkbox web action
    Then the step should succeed
    When I run the :click_change_settings_button_on_page web action
    Then the step should succeed
    When I run the :check_change_cluster_privacy_settings_with_warning_dialog web action
    Then the step should succeed
    When I run the :click_cancel_button web action
    Then the step should succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-adminosd |
    Then the step should succeed
    When I perform the :click_networking_tab web action with:
      | timeout | 5 |
    Then the step should succeed
    When I perform the :check_disabled_buttons_on_networking_tab web action with:
      | trimed_cluster_name | sdqe-adminosd |
      | machine_cidr        | 10.0.0.0/16   |
      | service_cidr        | 172.30.0.0/16 |
      | pod_cidr            | 10.128.0.0/14 |
      | host_prefix         | /23           |
    Then the step should succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-25348
  Scenario: Monitoring tab should show correct message for cluster in installing/disconnected status and no metrics data from telemetry
    Given I open ocm portal as a regularUser user
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-disconnected |
    Then the step should succeed
    When I run the :click_monitoring_tab web action
    Then the step should succeed
    When I run the :check_disconnected_cluster_monitoring_tab web action
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-22101
  Scenario: Check the cluster detail for the registered OCP cluster on UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :check_ocp_in_detail_page web action with:
      | cluster_name   | sdqe-ui-ocp |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-21090
  Scenario: Check the cluster information on a ready cluster overview page
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-default |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-default |
    Then the step should succeed
    When I perform the :check_osd_in_detail_page web action with:
      | cluster_name   | sdqe-ui-default |
      | ready          |                 |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-28142
  Scenario: The 'Edit subscription settings' link will be hidden if the cluster is archived
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-archive |
    Then the step should succeed
    When I run the :check_edit_subscription_settings_link web action
    Then the step should succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :archive_cluster_from_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I run the :check_edit_subscription_settings_link web action
    Then the step should fail
    When I perform the :go_to_archived_clusters_from_archived_cluster_detail_page web action with:
      | from_page | archived_cluster_detail |
    Then the step should succeed
    When I perform the :unarchive_cluster_from_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-28797
  Scenario: Check the elements for cluster history part in detail page
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-default |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-default |
    Then the step should succeed
    When I run the :check_cluster_history_section_common_part web action
    Then the step should succeed
    When I run the :check_default_osd_cluster_history web action
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-28797
  Scenario: Check the function for cluster history part in detail page
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-default |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-default |
    Then the step should succeed
    When I perform the :search_cluster_history_by_description web action with:
      | filter_keyword | Cluster installed and registered successfully |
      | result_keyword | Cluster installed and registered successfully |
    Then the step should succeed
    When I perform the :search_cluster_history_by_description web action with:
      | filter_keyword | cluster |
      | result_keyword | cluster |
    Then the step should succeed
    When I perform the :search_cluster_history_by_description web action with:
      | filter_keyword | cluster%success |
      | result_keyword | success         |
    Then the step should succeed
    When I perform the :search_cluster_history_by_description web action with:
      | filter_keyword | aaa              |
      | result_keyword | No results found |
    Then the step should succeed
    When I perform the :select_cluster_history_by_severity web action with:
      | filter_item    | Info |
      | result_keyword | Info |
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-29669
  Scenario: Networking tab only shows for the ready OSD cluster with provider AWS
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :create_osd_cluster web action with:
      | cluster_name   | sdqe-ocp-29669 |
      | product_id     | osd            |
      | cloud_provider | aws            |
    Then the step should succeed
    When I perform the :click_networking_tab web action with:
      | timeout | 5 |
    Then the step should fail
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :click_networking_tab web action with:
      | timeout | 5 |
    Then the step should fail
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-gcp |
    Then the step should succeed
    When I perform the :click_networking_tab web action with:
      | timeout | 5 |
    Then the step should fail
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :delete_cluster_from_cluster_list_page web action with:
      | cluster_name | sdqe-ocp-29669 |
      | input_text   | sdqe-ocp-29669 |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ocp-29669 |
    Then the step should succeed
    When I perform the :click_networking_tab web action with:
      | timeout | 5 |
    Then the step should fail

  # @author tzhou@redhat.com
  # @case_id OCP-28135
  Scenario: Only OrganizationAdmin and ClusterOwner can edit subscription settings
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-ocp |
    Then the step should succeed
    When I run the :check_edit_subscription_settings_link web action
    Then the step should succeed
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-ocp |
    Then the step should succeed
    When I run the :check_edit_subscription_settings_link web action
    Then the step should succeed
    Given I open ocm portal as an secondRegularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-ocp |
    Then the step should succeed
    When I run the :check_edit_subscription_settings_link web action
    Then the step should fail

  # @author tzhou@redhat.com
  # @case_id OCP-33436
  Scenario: Check the ui elements of the ownership transfer
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :check_filter_cluster_existed web action with:
      | coloumn_number | 1           |
      | filter_keyword | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-ocp |
    Then the step should succeed
    When I run the :transfer_cluster_ownership web action
    Then the step should succeed
    When I run the :cancel_transfer_cluster_ownership web action
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-35651
  Scenario: Check the UI layout of support tab in cluster detail page
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-adminosd |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-adminosd |
    Then the step should succeed
    When I perform the :check_support_tab web action with:
      | owner_email    | tzhou+uiorgadmin@redhat.com |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-36294
  Scenario: Check the permission of support tab in cluster detail page
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    Given I saved following keys to list in :clusters clipboard:
      | sdqe-ui-default ||
      | sdqe-adminosd   ||
    When I repeat the following steps for each :cluster_name in cb.clusters:
    """
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | #{cb.cluster_name}  |
    Then the step should succeed
    When I run the :click_support_tab web action
    Then the step should succeed
    When I run the :check_add_notification_contact_button_disabled web action
    Then the step should fail
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    """
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-adminosd |
    Then the step should succeed
    When I run the :click_support_tab web action
    Then the step should succeed
    When I run the :check_add_notification_contact_button_disabled web action
    Then the step should succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-default |
    Then the step should succeed
    When I run the :click_support_tab web action
    Then the step should succeed
    When I run the :check_add_notification_contact_button_disabled web action
    Then the step should fail

  # @author tzhou@redhat.com
  # @case_id OCP-28136
  Scenario: Update the Subscription Setting and check the result on the cluster overview page
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-disconnected |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-disconnected |
    Then the step should succeed
    When I run the :check_subscription_settings_dialog web action
    Then the step should succeed
    When I perform the :update_subscription_settings_in_dialog web action with:
      | support_level     | Premium    |
      | production_status | Production |
      | service_level     | L1-L3      |
      | unit              | Cores/vCPU |
      | unit_value        | 11         |
    Then the step should succeed
    When I run the :check_subscription_settings_dialog web action
    Then the step should succeed
    When I perform the :update_subscription_settings_in_dialog web action with:
      | support_level     | Self-Support      |
      | production_status | Disaster Recovery |
      | service_level     | L3-only           |
      | unit              | Sockets           |
      | unit_value        | 4                 |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-35840
  Scenario: Check the validation when update the Subscription Setting
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-disconnected |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-disconnected |
    Then the step should succeed
    When I run the :check_subscription_settings_dialog web action
    Then the step should succeed
    When I perform the :check_subscription_settings_error_message web action with:
      | unit_value    | -1      |
      | error_message | value can only be a positive integer. |
    Then the step should succeed
    When I perform the :check_subscription_settings_error_message web action with:
      | unit_value    | 2aa      |
      | error_message | value can only be a positive integer. |
    Then the step should succeed
    When I perform the :check_subscription_settings_error_message web action with:
      | unit_value    | 9999999999999      |
      | error_message | cannot be larger than 200000. |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-35653
  Scenario: Check the validation for the notification contact of support tab in cluster detail page - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-disconnected |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-disconnected |
    Then the step should succeed
    When I run the :click_support_tab web action
    Then the step should succeed
    When I perform the :check_error_message_in_notification_contact_dialog web action with:
      | notification_contact | sdqe-regular01       |
    Then the step should succeed
    When I perform the :check_error_message_in_notification_contact_dialog web action with:
      | notification_contact | sdqe-nonexistaccount |
    Then the step should succeed
    When I perform the :check_illegal_error_message_in_notification_contact_dialog web action with:
      | notification_contact | $% |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-35652
  Scenario: Check the function of notification contacts section in support tab on cluster detail page
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-disconnected |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name   | sdqe-ui-disconnected |
    Then the step should succeed
    When I run the :click_support_tab web action
    Then the step should succeed
    When I perform the :add_notification_contact web action with:
      | notification_contact | ocm-orgadmin |
    Then the step should succeed
    When I perform the :delete_notification_contact web action with:
      | notification_contact | ocm-orgadmin |
    Then the step should succeed
