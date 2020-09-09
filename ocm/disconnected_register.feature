Feature: Only for case related to disconnected cluster register page
  # @author xueli@redhat.com
  # @case_id OCP-25189
  Scenario: Check the "Register disconnected clusters" page UI
    Given I open ocm portal as an regularUser user
    When I run the :go_to_disconnected_cluster_register_page web action
    Then the step should succeed
    When I run the :check_disconnected_cluster_register_page web action
    Then the step should succeed
    When I run the :check_required_items_invalid_input_error_messages web action
    Then the step should succeed
    When I run the :check_optional_items_invalid_input_error_messages web action
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-24973
  Scenario: The Registered disconnected clusters can display correctly on UI page
    Given I open ocm portal as an regularUser user
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-disconnected |
    Then the step should succeed
    When I perform the :check_disconnected_cluster_overview_information web action with:
      | cluster_name     | sdqe-ui-disconnected          |
      | operating_system | N/A                           |
      | sockets_type     ||
    Then the step should succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-disconn-vcpu-type |
    Then the step should succeed
    When I perform the :check_disconnected_cluster_overview_information web action with:
      | cluster_name     | sdqe-ui-disconn-vcpu-type |
      | operating_system | N/A                       |
      | vcpu_type        ||
    Then the step should succeed
