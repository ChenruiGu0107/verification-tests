Feature: Ansible-service-broker related scenarios

  # @author jiazha@redhat.com
  # @case_id OCP-15344
  @admin
  @destructive
  Scenario: Set the ASB fresh time
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project

    Given admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    "broker":
      "refresh_interval": 60s
    """
    And admin redeploys "asb" dc
    And I wait up to 150 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | dc/asb                             |
    Then the step should succeed
    And the output should match 2 times:
      | refresh specs every 1m0s seconds       |
    """
