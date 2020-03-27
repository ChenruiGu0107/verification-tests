Feature: Persistent Volume reclaim policy tests
  # @author jhou@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-10638
  @admin
  Scenario: Recycle reclaim policy for persistent volumes
    Given I have a project
    And I have a NFS service in the project
    Given admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/nfs/auto/pv.json" where:
      | ["metadata"]["name"]                      | pv-<%= project.name %>           |
      | ["spec"]["storageClassName"]              | sc-<%= project.name %>           |
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Recycle                          |
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["volumeName"]       | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
      | ["metadata"]["name"]                                         | mypod |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    Given I ensure "mypod" pod is deleted
    And I ensure "mypvc" pvc is deleted
    And the PV becomes :available within 300 seconds


  # @author lxia@redhat.com
  # @case_id OCP-12836
  @admin
  Scenario: Change dynamic provisioned PV's reclaim policy
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"] | Immediate |

    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
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
