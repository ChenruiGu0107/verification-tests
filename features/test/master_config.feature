Feature: test master config related steps
  @admin
  Scenario: master config change with multipline parameter
    Given I modify master config as admin with the following:
    """
    volumeConfig:
      dynamicProvisioningEnabled: False
    """
    Then the step should succeed
