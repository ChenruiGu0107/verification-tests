Feature: Testing for pv and pvc pre-bind feature

  # @author chaoyang@redhat.com
  # @case_id OCP-10110
  @admin
  Scenario: Prebound pv is availabe due to mismatched volume size with requested pvc
    Given I have a project
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/preboundpv-rwo.yaml" where:
      | ["metadata"]["name"]              | nfspv-<%= project.name %> |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>       |
      | ["spec"]["claimRef"]["name"]      | nfsc-<%= project.name %>  |
    Then the step should succeed
    And the "nfspv-<%= project.name %>" PV status is :available
    Then I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | nfsc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                      |
    And the "nfsc-<%= project.name %>" PVC becomes :pending
    And the "nfspv-<%= project.name %>" PV status is :available

  # @author lxia@redhat.com
  # @case_id OCP-10124
  @admin
  @destructive
  Scenario: PV/PVC bind in a reasonable time when PVC is created before PV while PVC pre-bind to PV
    Given I have a project
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/preboundpvc-rwo.yaml" replacing paths:
      | ["metadata"]["name"]   | pvc-prebind-<%= project.name %> |
      | ["spec"]["volumeName"] | pv-<%= project.name %>          |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/nfs.json" where:
      | ["metadata"]["name"] | pv-<%= project.name %> |
    Then the step should succeed
    And the "pvc-prebind-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV within 60 seconds

  # @author lxia@redhat.com
  # @case_id OCP-10125
  @admin
  @destructive
  Scenario: PV/PVC bind in a reasonable time when PVC is created before PV while PV pre-bind to PVC
    Given I have a project
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/preboundpv-rwo.yaml" where:
      | ["metadata"]["name"]              | pv-prebind-<%= project.name %> |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>            |
      | ["spec"]["claimRef"]["name"]      | pvc-<%= project.name %>        |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-prebind-<%= project.name %>" PV within 60 seconds

  # @author lxia@redhat.com
  # @case_id OCP-12679
  @admin
  Scenario: PV/PVC bind in a reasonable time when PVC is created before PV while PV/PVC pre-bind to each other
    Given I have a project
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/preboundpvc-rwo.yaml" replacing paths:
      | ["metadata"]["name"]   | mypvc                  |
      | ["spec"]["volumeName"] | pv-<%= project.name %> |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/preboundpv-rwo.yaml" where:
      | ["metadata"]["name"]              | pv-<%= project.name %> |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>    |
      | ["spec"]["claimRef"]["name"]      | mypvc                  |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV within 60 seconds
    And I ensure "<%= project.name %>" project is deleted
