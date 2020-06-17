Feature: Only for case related to cluster detail page

  # @author xueli@redhat.com
  # @case_id OCP-23050
  Scenario: User with right access can see logs view on UI for OSD/OCP clusters
    Given I open ocm portal as a srepUser user
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-default |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I perform the :check_logs_tab web action with:
      | cluster_type | OSD |
    Then the step should succeed
    When I perform the :go_to_cluster_list_page web action with:
      | from_page | cluster_detail_page |
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :check_logs_tab web action with:
      | cluster_type | OCP |
    Then the step should fail
     # Add a successful step to make sure browser close action will succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as a regularUser user
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I perform the :check_logs_tab web action with:
      | cluster_type | OSD |
    Then the step should fail
    When I perform the :go_to_cluster_list_page web action with:
      | from_page | cluster_detail_page |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-ocp |
    Then the step should succeed
    When I perform the :check_logs_tab web action with:
      | cluster_type | OCP |
    Then the step should fail

  # @author xueli@redhat.com
  # @case_id OCP-25343
  Scenario: Monitoring tab can display and work correctly for OCP and OSD clusters
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    Given I saved following keys to list in :clusters clipboard:
      | sdqe-ui-default ||
     #| sdqe-ui-ocp ||
    When I repeat the following steps for each :cluster_name in cb.clusters:
      """
      When I perform the :go_to_cluster_detail_page web action with:
          | cluster_name | #{cb.cluster_name} |
      Then the step should succeed
      When I perform the :check_monitoring_tab web action with:
          | issue_number| No |
      Then the step should succeed
      When I perform the :go_to_cluster_list_page web action with:
          | from_page | cluster_detail_page |
      Then the step should succeed
      """

  # @author xueli@redhat.com
  # @case_id OCP-25348
  Scenario: Monitoring tab should show correct message for cluster in installing/disconnected status and no metrics data from telemetry
    Given I open ocm portal as a regularUser user
    When  I perform the :create_osd_cluster web action with:
      | cluster_name | xueli-1 |
    Then the step should succeed
    Then I wait up to 600 seconds for the steps to pass:
      """
      When I perform the :wait_cluster_status_on_detail_page web action with:
          | cluster_status | installing |
      Then the step should succeed
      """
    When I run the :click_monitoring_tab web action
    Then the step should succeed
    When I run the :check_installing_cluster_monitoring_tab web action
    Then the step should succeed
    # Delete the cluster to clean the env
    When I perform the :delete_osd_cluster_from_detail_page web action with:
      | cluster_name | xueli-1 |
      | input_text   | xueli-1 |
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-disconnected |
    Then the step should succeed
    When I run the :click_monitoring_tab web action
    Then the step should succeed
    When I run the :check_disconnected_cluster_monitoring_tab web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-23864
  Scenario: Check the layout of the Users tab on the cluster detail page
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :click_access_control_tab web action
    Then the step should succeed
    When I run the :check_elements_on_user_card web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-26404
  Scenario: Check the validation for the user tab in detail page
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_access_control_tab web action with:
      | cluster_name | sdqe-ui-default |
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
    When I perform the :add_user web action with:
      | user_id    | test_user_1      |
      | user_group | dedicated-admins |
    Then the step should succeed
    When I perform the :check_user_added web action with:
      | user_id    | test_user_1      |
      | user_group | dedicated-admins |
    Then the step should succeed
    When I perform the :add_user web action with:
      | user_id    | test_user_1      |
      | user_group | dedicated-admins |
    Then the step should succeed
    When I perform the :check_danger_alert_box_in_user_tab web action with:
      | error_massage | already exists on group  |
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