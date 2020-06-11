Feature: Testing for pv and pvc pre-bind feature

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-10110
  @admin
  Scenario: Prebound pv is availabe due to mismatched volume size with requested pvc
    Given I have a project
    Given I obtain test data file "storage/nfs/preboundpv-rwo.yaml"
    Given admin creates a PV from "preboundpv-rwo.yaml" where:
      | ["metadata"]["name"]              | pv-<%= project.name %> |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>    |
      | ["spec"]["claimRef"]["name"]      | mypvc                  |
      | ["spec"]["storageClassName"]      | sc-<%= project.name %> |
    Then the step should succeed
    And the "pv-<%= project.name %>" PV status is :available
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc                  |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                    |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available

  # @author lxia@redhat.com
  # @case_id OCP-10124
  @admin
  Scenario: PV/PVC bind in a reasonable time when PVC is created before PV while PVC pre-bind to PV
    Given I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["volumeName"]       | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/nfs/nfs.json"
    When admin creates a PV from "nfs.json" where:
      | ["metadata"]["name"]         | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV within 60 seconds

  # @author lxia@redhat.com
  # @case_id OCP-10125
  @admin
  Scenario: PV/PVC bind in a reasonable time when PVC is created before PV while PV pre-bind to PVC
    Given I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/nfs/preboundpv-rwo.yaml"
    When admin creates a PV from "preboundpv-rwo.yaml" where:
      | ["metadata"]["name"]              | pv-<%= project.name %> |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>    |
      | ["spec"]["claimRef"]["name"]      | mypvc                  |
      | ["spec"]["storageClassName"]      | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV within 60 seconds

  # @author lxia@redhat.com
  # @case_id OCP-12679
  @admin
  Scenario: PV/PVC bind in a reasonable time when PVC is created before PV while PV/PVC pre-bind to each other
    Given I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["volumeName"]       | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/nfs/preboundpv-rwo.yaml"
    When admin creates a PV from "preboundpv-rwo.yaml" where:
      | ["metadata"]["name"]              | pv-<%= project.name %> |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>    |
      | ["spec"]["claimRef"]["name"]      | mypvc                  |
      | ["spec"]["storageClassName"]      | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV within 60 seconds
