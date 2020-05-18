Feature: Dynamic provisioning
  # @author chaoyang@redhat.com
  # @case_id OCP-13943
  @smoke
  Scenario: Dynamic provision smoke test
    Given I have a project
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc     |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/iaas |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    And the "mypvc" PVC becomes :bound
    When I execute on the pod:
      | ls | -ld | /mnt/iaas/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/iaas/testfile |
    Then the step should succeed
    When I execute on the pod:
      | cp | /hello | /mnt/iaas/ |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/iaas/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

  # @author jhou@redhat.com
  @admin
  Scenario Outline: Specify a file system type for dynamically provisioned volume
    Given I have a project
    And admin clones storage class "storageclass-<%= project.name %>" from ":default" with:
      | ["parameters"]["fstype"] | <fstype> |

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %>          |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce                    |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                              |
      | ["spec"]["storageClassName"]                 | storageclass-<%= project.name %> |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt                    |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | df | -T | /mnt |
    Then the step should succeed
    And the output should contain:
      | <fstype> |

    Examples:
      | fstype |
      | xfs    | # @case_id OCP-16058
      | ext3   | # @case_id OCP-16059
      | ext4   | # @case_id OCP-16060

  # @author chaoyang@redhat.com
  # @case_id OCP-17188
  @admin
  Scenario: User can dynamic created encryted ebs volume
    Given I have a project
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/sc_encrypted.yaml" where:
      | ["metadata"]["name"]  | sc-<%= project.name %> |
      | ["volumeBindingMode"] | WaitForFirstConsumer   |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | dynamic-pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>          |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod                           |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/aws                        |
    Then the step should succeed
    And the pod named "mypod" becomes ready

    And the "dynamic-pvc-<%= project.name %>" PVC becomes :bound
    When I execute on the pod:
      | touch | /mnt/aws/testfile |
    Then the step should succeed

  # @author piqin@redhat.com
  Scenario Outline: dynamic provisioning for block volume
    Given I have a project

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]   | pvc-<%= project.name %> |
      | ["spec"]["volumeMode"] | Block                   |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod-with-block-volume.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeDevices"][0]["devicePath"]  | /dev/block              |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the "pod-<%= project.name %>" pod:
      | ls | /dev/block |
    Then the step should succeed

    Examples:
      | cloud_provider |
      | cinder         | # @case_id OCP-19184
      | aws-ebs        | # @case_id OCP-19185
      | vsphere-volume | # @case_id OCP-19190
      | gce            | # @case_id OCP-19186
      | azure-disk     | # @case_id OCP-19188

  # @author jhou@redhat.com
  # @case_id OCP-17563
  Scenario: Using multiple block volumes
    Given I have a project

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]   | pvc1  |
      | ["spec"]["volumeMode"] | Block |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]   | pvc2  |
      | ["spec"]["volumeMode"] | Block |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod-with-two-block-volumes.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc1                    |
      | ["spec"]["containers"][0]["volumeDevices"][0]["devicePath"]  | /dev/block1             |
      | ["spec"]["volumes"][1]["persistentVolumeClaim"]["claimName"] | pvc2                    |
      | ["spec"]["containers"][0]["volumeDevices"][1]["devicePath"]  | /dev/block2             |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the "pod-<%= project.name %>" pod:
      | ls | /dev/block1 | /dev/block2 |
    Then the step should succeed

  # @author jhou@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-20728
  @admin
  Scenario: The reclaimPolicy is Retain when set as empty string
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["reclaimPolicy"]     | ""        |
      | ["volumeBindingMode"] | Immediate |
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Retain"
