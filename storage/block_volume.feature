Feature: Scenarios specific for block volume support
  # @author lxia@redhat.com
  # @case_id OCP-25861
  @admin
  Scenario: VolumeMode defaults to Filesystem for dynamic provisioned volumes
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"] | Immediate |
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound
    And the expression should be true> pvc.volume_mode == "Filesystem"
    And the expression should be true> pv(pvc.volume_name).volume_mode == "Filesystem"
