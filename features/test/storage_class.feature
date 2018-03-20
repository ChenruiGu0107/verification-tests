Feature: StorageClass testing scenarios
  @admin
  Scenario: admin creates a StorageClass
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | storageclass           |
      | resource_name | sc-<%= project.name %> |
      | o             | yaml                   |
    Then the step should succeed

  @admin
  Scenario: Add option allowVolumeExpansion to StorageClass
    Given I check feature gate "ExpandPersistentVolumes" with admission "PersistentVolumeClaimResize" is enabled
    When I run the :get admin command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And as admin I successfully patch resource "storageclass/standard" with:
      | {"allowVolumeExpansion":true,"metadata":{"annotations":{"updatedBy":"<%=project.name%>-<%=Time.new%>"}}} |
    When I run the :get admin command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    # Multi times
    Given as admin I successfully patch resource "storageclass/standard" with:
      | {"allowVolumeExpansion":true,"metadata":{"annotations":{"updatedBy":"<%=project.name%>-<%=Time.new%>"}}} |
