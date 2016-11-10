Feature: test master config related steps
  @admin
  Scenario: master config change with multipline parameter
    Given master config is merged with the following hash:
    """
    volumeConfig:
      dynamicProvisioningEnabled: False
    """
    Then the step should succeed
