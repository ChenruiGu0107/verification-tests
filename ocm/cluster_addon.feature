Feature: only about add-on page for OSD cluster
  # @author xueli@redhat.com
  # @case_id OCP-26501
  Scenario: Add-on can be installed successfully via Add-on tab with enough quota
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :check_addons_tab web action
    Then the step should succeed
    When I perform the :install_addon web action with:
      | addon_name  | DBA Operator  |
    Then the step should succeed
    When I perform the :install_addon web action with:
      | addon_name  | Prow Operator |
    Then the step should succeed
    When I perform the :wait_for_addon_to_status web action with:
      | addon_name  | Prow Operator |
      | wait_status | Failed        |
    Then the step should succeed
    When I perform the :wait_for_addon_to_status web action with:
      | addon_name  | Prow Operator |
      | wait_status | Installed     |
    Then the step should succeed