Feature: Alerting for machine-api

  # @author jhou@redhat.com
  # @case_id OCP-25615
  @admin
  Scenario: Machine metrics should be collected
    Given I switch to cluster admin pseudo user

    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                         |
      | query | mapi_machine_created_timestamp_seconds |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"] == "success"
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["__name__"] == "mapi_machine_created_timestamp_seconds"

  # @author jhou@redhat.com
  # @case_id OCP-25828
  @admin
  @destructive
  Scenario: Alert and metrics for maxPendingCSR
    Given I switch to cluster admin pseudo user

    # Create pending csr to exceed the value of maxPendingCSR(cb.machine_count + 100)
    Given I store the number of machines in the :machine_count clipboard
    And evaluation of `cb.machine_count + 101` is stored in the :pending_csr clipboard

    Given I obtain test data file "cloud/machine-approver/csr.yml"
    Given I run the steps <%= cb.pending_csr %> times:
    """
    When I run the :create admin command with:
      | f | csr.yml |
    Then the step should succeed
    """

    # Remove these csr after scenario
    And I register clean-up steps:
    """
    When I run the :delete admin command with:
      | object_type | csr                 |
      | l           | testpendingcsr=true |
    Then the step should succeed
    """

    And I wait up to 60 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?           |
      | query | mapi_current_pending_csr |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"][0]["value"][1] == cb.pending_csr.to_s
    """

    # Alerts
    And I wait up to 180 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                                           |
      | query | ALERTS{alertname="MachineApproverMaxPendingCSRsReached"} |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["alertstate"] =~ /pending|firing/
    """
