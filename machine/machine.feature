Feature: Machine features testing

  # @author jhou@redhat.com
  @admin
  Scenario Outline: Machines phase should become 'Failed' when it has create error
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And I pick a random machineset to scale

    # Create an invalid machineset
    Given I run the :get admin command with:
      | resource      | machineset              |
      | resource_name | <%= machine_set.name %> |
      | namespace     | openshift-machine-api   |
      | o             | yaml                    |
    Then the step should succeed
    And I save the output to file> machineset-invalid.yaml
    And I replace content in "machineset-invalid.yaml":
      | <%= machine_set.name %> | machineset-invalid |
      | <valid_field>           | <invalid_value>    |
      | /replicas:.*/           | replicas: 1        |

    When I run the :create admin command with:
      | f | machineset-invalid.yaml |
    Then the step should succeed
    And admin ensures "machineset-invalid" machineset is deleted after scenario

    # Verified machine has 'Failed' phase
    Given I store the last provisioned machine in the :invalid_machine clipboard
    And I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> machine(cb.invalid_machine).phase(cached: false) == "Failed"
    """

    # Verify alert is fired
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                                |
      | query | ALERTS{alertname="MachineWithNoRunningPhase"} |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["alertstate"] =~ /pending|firing/

    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                              |
      | query | ALERTS{alertname="MachineWithoutValidNode"} |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["alertstate"] =~ /pending|firing/
    """

    Examples:
      | valid_field       | invalid_value         |
      | /machineType:.*/  | machineType: invalid  | # @case_id OCP-25927
      | /instanceType:.*/ | instanceType: invalid | # @case_id OCP-28817
      | /vmSize:.*/       | vmSize: invalid       | # @case_id OCP-28818
      | /flavor:.*/       | flavor: invalid       | # @case_id OCP-28916

  # @author zhsun@redhat.com
  # @case_id OCP-29351
  Scenario Outline: Use oc explain to see detailed documentation of the resources
    When I run the :explain client command with:
      | resource | <resource> |
    Then the step should succeed
    And the output should contain:
      | apiVersion |
    And the output should not contain:
      | <empty> |
      | <none>  |

    Examples:
      | resource           |
      | machine            |
      | machineset         |
      | machinehealthcheck |
      | clusterautoscaler  |
      | machineautoscaler  |
