Feature: test node config related steps
  @admin
  @destructive
  Scenario: node config change with multipline parameter
    Given node config of all nodes is merged with the following hash:
    """
    iptablesSyncPeriod: "35s"
    """
    Then the step should succeed
    And the node service is restarted on all nodes

  @admin
  @destructive
  Scenario: node config will be modified multiple times
    Given node config of all nodes is merged with the following hash:
    """
    iptablesSyncPeriod: "35s"
    """
    Then the step should succeed

    Given node config of all nodes is merged with the following hash:
    """
    iptablesSyncPeriod: "40s"
    """
    Then the step should succeed

  @admin
  @destructive
  Scenario: the node service will fail to restart and return result
    Given node config of all schedulable nodes is merged with the following hash:
    """
    iptablesSyncPeriod: BadValue
    """
    Then the step should succeed
    And I try to restart the node service on all schedulable nodes
    Then the step should fail
    And the expression should be true> @result[:success] == false

  @admin
  @destructive
  Scenario: restore node config file before automatic restore
    Given node config of all nodes is merged with the following hash:
    """
    iptablesSyncPeriod: "35s"
    """
    Then the step should succeed
    When all nodes config is restored
    Then the step should succeed

  @admin
  Scenario: get value from node config
    Given I store the value of path ["networkConfig"]["mtu"] of node config in the :mtu clipboard
    And the expression should be true> cb.mtu == 1410
