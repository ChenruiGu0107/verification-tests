Feature: test master config related steps
  @admin
  @destructive
  Scenario: master config change with multipline parameter
    Given master config is merged with the following hash:
    """
    volumeConfig:
      dynamicProvisioningEnabled: False
    """
    Then the step should succeed
    And the master service is restarted on all master nodes

  @admin
  @destructive
  Scenario: master config will be modified multiple times
    Given master config is merged with the following hash:
    """
    volumeConfig:
      dynamicProvisioningEnabled: False
    """
    Then the step should succeed

    Given master config is merged with the following hash:
    """
    volumeConfig:
      dynamicProvisioningEnabled: BadValue
    """
    Then the step should succeed

  @admin
  @destructive
  Scenario: the master service will fail to restart and return result
    Given master config is merged with the following hash:
    """
    volumeConfig:
      dynamicProvisioningEnabled: BadValue
    """
    Then the step should succeed
    And I try to restart the master service on all master nodes
    Then the step should fail
    And the expression should be true> @result[:success] == false

  @admin
  @destructive
  Scenario: restore master config file before automatic restore
    Given master config is merged with the following hash:
    """
    volumeConfig:
      dynamicProvisioningEnabled: BadValue
    """
    Then the step should succeed
    When master config is restored from backup
    Then the step should succeed

  @admin
  Scenario: get value from master config
    Given I store the value of path ["dnsConfig"]["bindNetwork"] of master config in the :network clipboard
    And the expression should be true> cb.network == "tcp4"
