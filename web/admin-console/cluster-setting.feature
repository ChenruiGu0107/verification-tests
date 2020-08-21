Feature: about cluster setting page

  # @author yanpzhan@redhat.com
  # @case_id OCP-33125
  @admin
  Scenario: Check subscription link and channel helper text with links
    Given the master version >= "4.6"
    Given I open admin console in a browser
    Given the first user is cluster-admin
    Given I store master major version in the :master_version clipboard
    When I run the :goto_cluster_settings_details_page web action
    Then the step should succeed
    When I perform the :check_ocm_subscription web action with:
      | cluster_id | <%= cluster_version("version").cluster_id %> |
    Then the step should succeed
    When I perform the :check_help_info_on_channel_popup web action with:
      | product_version | <%= cb.master_version %> |
    Then the step should succeed
    When I perform the :check_help_info_in_update_channel_modal web action with:
      | product_version | <%= cb.master_version %> |
    Then the step should succeed



