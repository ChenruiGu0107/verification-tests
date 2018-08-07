Feature: Enable LocalVolume in OCP cluster
  # @author piqin@redhat.com
  @admin
  @destructive
  Scenario: Enable LocalVolume
    Given I deploy local storage provisioner

  # @author piqin@redhat.com
  @admin
  @destructive
  Scenario: Enable LocalVolume on stage env
    Given I deploy local storage provisioner with "v3.10.14-2" version
