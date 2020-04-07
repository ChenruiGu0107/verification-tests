Feature: only about page related to cluster archive

  # @author xueli@redhat.com
  # @case_id OCP-25326
  Scenario: Archive OCP clusters from UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :archive_cluster_from_cluster_list_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :unarchive_cluster_from_cluster_list_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :go_to_cluster_list_page web action with:
      | from_page | archived |
    Then the step should succeed
    When I perform the :archive_cluster_from_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :go_to_archived_clusters_from_archived_cluster_detail_page web action with:
      | from_page | archived_cluster_detail |
    Then the step should succeed
    When I perform the :unarchive_cluster_from_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :wait_cluster_status_on_detail_page web action with:
      |cluster_status|disconnected|
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-25329
  Scenario: Archived cluster list page can display and work well
    Given I open ocm portal as an regularUser user
    When I perform the :go_to_archived_cluster_page web action with:
      |from_page| cluster_list|
    Then the step should succeed
    When I perform the :check_archived_cluster_list_page web action with:
      |empty_list|true|
    Then the step should succeed
    When I perform the :click_show_active_clusters_link web action with:
      |from_page| archived_clusters|
    Then the step should succeed
    When I perform the :cluster_list_page_loaded web action with:
      |from_page| archived_clusters|
    Then the step should succeed
    When I perform the :archive_cluster_from_cluster_list_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :go_to_archived_cluster_page web action with:
      |from_page| cluster_list|
    Then the step should succeed
    When I perform the :check_archived_cluster_list_page web action with:
      |archived_list|true|
    Then the step should succeed
    When I perform the :go_to_cluster_list_page web action with:
      |from_page| archived_clusters|
    Then the step should succeed
    When I perform the :unarchive_cluster_from_cluster_list_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-25581
  Scenario: Cluster detail page will display basic information and buttons for archived clusters
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :archive_cluster_from_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :check_archived_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :click_monitoring_tab web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should fail
    When I perform the :go_to_archived_clusters_from_archived_cluster_detail_page web action with:
      | from_page | archived_cluster_detail |
    Then the step should succeed
    When I perform the :unarchive_cluster_from_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-25328
  Scenario: Cluster member cannot archive the cluster not owned by themselves
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :archive_cluster_from_cluster_list_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    When I perform the :unarchive_cluster_from_cluster_list_page web action with:
      | cluster_name | sdqe-ui-archive |
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :click_archive_button_on_cluster_list_page web action with:
      |cluster_name|sdaqe-ui-disconnected-adminowned|
    Then the step should fail
    When I perform the :go_to_cluster_detail_page web action with:
      |cluster_name|sdaqe-ui-disconnected-adminowned|
    Then the step should succeed
    When I perform the :click_archive_button_on_cluster_detail_page web action with:
      |cluster_name|sdaqe-ui-disconnected-adminowned|
    Then the step should fail
    # Add a successful step to make sure browser close action will succeed
    When I perform the :go_to_cluster_list_page web action with:
      |parameter_needed|no|
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :archive_cluster_from_cluster_list_page web action with:
      | cluster_name | sdaqe-ui-disconnected-adminowned |
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    And I register clean-up steps:
      """
      Given I open ocm portal as an orgAdmin user
      Then the step should succeed
      When I perform the :unarchive_cluster_from_cluster_list_page web action with:
          | cluster_name | sdaqe-ui-disconnected-adminowned |
      Then the step should succeed
      """
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_archived_cluster_page web action with:
      | parameter_needed | no |
    Then the step should succeed
    When I perform the :click_unarchive_cluster_button_on_archived_cluster_list_page web action with:
      |cluster_name|sdaqe-ui-disconnected-adminowned|
    Then the step should fail
    When I perform the :go_to_archived_cluster_detail_page web action with:
      |cluster_name|sdaqe-ui-disconnected-adminowned|
    Then the step should succeed
    When I perform the :click_detail_page_unarchive_cluster_button web action with:
      |parameter_needed|no|
    Then the step should fail
    # Add this step to make sure close browser can be excute successfully
    When I perform the :go_to_cluster_list_page web action with:
      |parameter_needed|no|
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed


  # @author xueli@redhat.com
  # @case_id OCP-25330
  Scenario: Filters should work well for active and archived clusters
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :archive_cluster_from_cluster_list_page web action with:
      | cluster_name | sdaqe-ui-disconnected-adminowned |
    Then the step should succeed
    And I register clean-up steps:
      """
      Given I open ocm portal as an orgAdmin user
      Then the step should succeed
      When I perform the :unarchive_cluster_from_cluster_list_page web action with:
          | cluster_name | sdaqe-ui-disconnected-adminowned |
      Then the step should succeed
      """
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdaqe-ui-disconnected-adminowned |
    Then the step should succeed
    When I perform the :check_filter_no_result_message web action with:
      |parameter_needed|no|
    Then the step should succeed
    # When I perform the :clear_filter_name_or_id web action with:
    #     | parameter_needed | no |
    # Then the step should succeed
    When I perform the :go_to_archived_cluster_page web action with:
      |parameter_needed|no|
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdaqe-ui-default |
    Then the step should succeed
    When I perform the :empty_table_loaded web action with:
      |parameter_needed|no|
    Then the step should succeed
    When I perform the :filter_name_or_id web action with:
      | filter_keyword | sdaqe-ui-disconnected-adminowned |
    Then the step should succeed
    When I perform the :check_filter_cluster_existed web action with:
      |coloumn_number|1|
      | filter_keyword | sdaqe-ui-disconnected-adminowned |
    Then the step should succeed
