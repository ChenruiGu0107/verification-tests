Feature: install metering with various backend storage configurations
  # @author pruan@redhat.com
  # @case_id OCP-32004
  @admin
  @destructive
  Scenario: install metering using sharePVC as storage
    Given the master version >= "4.1"
    Given I install metering service using:
      | meteringconfig | metering/configs/meteringconfig_sharedPVC.yaml |
      | storage_type   | sharedPVC                                      |


