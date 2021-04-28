Feature: Alerting for machine-api

  # @author jhou@redhat.com
  # @author zhsun@redhat.com
  @admin
  Scenario Outline: Machine metrics should be collected
    Given I switch to cluster admin pseudo user

    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query? |
      | query | <metric_name>  |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"] == "success"
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["__name__"] == "<metric_name>"

    Examples:
      | metric_name                               |
      | mapi_machine_created_timestamp_seconds    | # @case_id OCP-25615
      | mapi_machine_phase_transition_seconds_sum | # @case_id OCP-37264

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

  # @author zhsun@redhat.com
  @admin
  Scenario Outline: mapi_instance_create_failed metrics should work on all providers
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And I pick a random machineset to scale

    # Create an invalid machineset
    Given I get project machineset named "<%= machine_set.name %>" as YAML
    And I save the output to file> machineset-invalid.yaml
    And I replace content in "machineset-invalid.yaml":
      | <%= machine_set.name %> | <machineset-name>  |
      | <valid_field>           | <invalid_value>    |
      | /replicas:.*/           | replicas: 1        |

    When I run the :create admin command with:
      | f | machineset-invalid.yaml |
    Then the step should succeed
    And admin ensures <machineset-name> machineset is deleted after scenario

    # Verified machine has 'Failed' phase
    Given I store the last provisioned machine in the :invalid_machine clipboard
    And I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> machine(cb.invalid_machine).phase(cached: false) == "Failed"
    """

    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?              |
      | query | mapi_instance_create_failed |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"] == "success"
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["__name__"] == "mapi_instance_create_failed"

    Examples:
      | valid_field       | invalid_value           | machineset-name          |
      | /machineType:.*/  | machineType: invalid    | machineset-invalid-37846 | # @case_id OCP-37846
      | /instanceType:.*/ | instanceType: invalid   | machineset-invalid-36989 | # @case_id OCP-36989
      | /vmSize:.*/       | vmSize: invalid         | machineset-invalid-37847 | # @case_id OCP-37847
      | /flavor:.*/       | flavor: invalid         | machineset-invalid-37848 | # @case_id OCP-37848
      | /folder:.*/       | folder: /dc1/vm/invalid | machineset-invalid-37849 | # @case_id OCP-37849
