Feature: Persistent Volume reclaim policy tests
  # @author lxia@redhat.com
  # @case_id OCP-12836
  @admin
  Scenario: Change dynamic provisioned PV's reclaim policy
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"] | Immediate |

    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound
    And admin ensures "<%= pvc.volume_name %>" pv is deleted after scenario
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Delete"
    When I run the :patch admin command with:
      | resource      | pv                                                  |
      | resource_name | <%= pvc.volume_name %>                              |
      | p             | {"spec":{"persistentVolumeReclaimPolicy":"Retain"}} |
    Then the step should succeed
    And the expression should be true> pv(pvc.volume_name).reclaim_policy(cached: false) == "Retain"

    Given I ensure "mypvc" pvc is deleted
    And the PV becomes :released within 60 seconds
