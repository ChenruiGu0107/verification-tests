Feature: Gluster Block features testing file

  # @author jhou@redhat.com
  # @case_id OCP-17583
  @admin
  Scenario: Using mountOptions for Gluster-block StorageClass
    Given I have a StorageClass named "gluster-block"
    And I have a project

    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster-block/storageclass-mount-options.yml" where:
      | ["metadata"]["name"]      | sc-<%= project.name %>                         |
      | ["parameters"]["resturl"] | <%= storage_class("gluster-block").rest_url %> |
      | ["mountOptions"][0]       | rw                                             |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster-block/pvc-gluster-block.json" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And I ensure "pvc-<%= project.name %>" pvc is deleted after scenario

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | grep | mpath | /proc/self/mountinfo |
    Then the output should contain:
      | rw |

  # @author jhou@redhat.com
  # @case_id OCP-17278
  @admin
  Scenario: Configure 'Retain' reclaim policy for Gluster-block
    Given I have a StorageClass named "gluster-block"
    And I have a project

    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster-block/storageclass-retain.yml" where:
      | ["metadata"]["name"]      | sc-<%= project.name %>                         |
      | ["parameters"]["resturl"] | <%= storage_class("gluster-block").rest_url %> |
      | ["reclaimPolicy"]         | Retain                                         |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster-block/pvc-gluster-block.json" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And admin ensures "<%= pv.name %>" pv is deleted after scenario

    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Retain"

    When I ensure "pvc-<%= project.name %>" pvc is deleted
    Given I run the :get admin command with:
      | resource      | pv             |
      | resource_name | <%= pv.name %> |
    Then the output should contain:
      | Released |

  # @author jhou@redhat.com
  # @case_id OCP-19189
  @admin
  Scenario: Dynamically provision glusterblock volume with block volumeMode
    Given I have a StorageClass named "gluster-block"
    And I have a project

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1          |
      | ["spec"]["storageClassName"]                 | gluster-block |
      | ["spec"]["volumeMode"]                       | Block         |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi           |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound within 120 seconds

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod-with-block-volume.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc1                    |
      | ["spec"]["containers"][0]["volumeDevices"][0]["devicePath"]  | /dev/block              |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the "pod-<%= project.name %>" pod:
      | ls | /dev/block |
    Then the step should succeed
