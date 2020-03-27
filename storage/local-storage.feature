Feature: Local Persistent Volume

  # @author piqin@redhat.com
  # @case_id OCP-15455
  @admin
  Scenario: Local PV is deleted and a new PV will be created
    Given I have a StorageClass named "local-fast"

    Given I have a project

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | local-fast              |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    Then I ensure "pvc-<%= project.name %>" pvc is deleted
    And the "<%= pvc.volume_name %>" PV becomes :available within 60 seconds

  # @author piqin@redhat.com
  # @case_id OCP-15463
  @admin
  Scenario: Local PV can be used by Pod
    Given I have a StorageClass named "local-fast"

    Given I have a project

    When I run the :patch admin command with:
      | resource      | namespace                                                         |
      | resource_name | <%= project.name %>                                               |
      | p             | {"metadata": {"annotations": {"openshift.io/node-selector": ""}}} |
    Then the step should succeed

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | local-fast              |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/local-storage      |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | cp | /hello | /mnt/local-storage |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/local-storage/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

    Given I use the "<%= pod.node_name %>" node
    And I run commands on the host:
      |ls <%= pv(pvc.volume_name).local_path %>/hello |
    Then the step should succeed

    Given I ensure "pod-<%= project.name %>" pod is deleted
    And I run commands on the host:
      |ls <%= pv(pvc.volume_name).local_path %>/hello |
    Then the step should succeed

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod2-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/local-storage      |
    Then the step should succeed
    Given the pod named "pod2-<%= project.name %>" becomes ready

    When I execute on the pod:
      | /mnt/local-storage/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

    Given I ensure "pod2-<%= project.name %>" pod is deleted
    And I ensure "pvc-<%= project.name %>" pvc is deleted
    And the "<%= pvc.volume_name %>" PV status becomes :available within 60 seconds
    And I run commands on the host:
      |ls <%= pv(pvc.volume_name).local_path %>/hello |
    Then the step should fail

  # @author piqin@redhat.com
  # @case_id OCP-15452
  @admin
  Scenario: No PV will be created for regular file
    Given I have a StorageClass named "local-fast"

    Given I select a random node's host

    Given the "/mnt/local-storage/fast/volfile1" file is restored on host after scenario
    When I run commands on the host:
      | touch /mnt/local-storage/fast/volfile1 |
    Then the step should succeed

    Given 10 seconds have passed
    And there are no PVs with local path "/mnt/local-storage/fast/volfile1"

    When I get the log of local storage provisioner for node "<%= node.name %>"
    Then the step should succeed
    And the output should contain:
      | "/mnt/local-storage/fast/volfile1": not a directory nor block device |

  # @author piqin@redhat.com
  # @case_id OCP-15470
  @admin
  Scenario: local volume provisoiner can clean up dot files
    Given I have a StorageClass named "local-fast"

    Given I have a project

    When I run the :patch admin command with:
      | resource      | namespace                                                         |
      | resource_name | <%= project.name %>                                               |
      | p             | {"metadata": {"annotations": {"openshift.io/node-selector": ""}}} |
    Then the step should succeed

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | local-fast              |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/local-storage      |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | cp    | /hello | /mnt/local-storage |
    Then the step should succeed

    When I execute on the pod:
      | touch | /mnt/local-storage/.testfile1 |
    Then the step should succeed

    Given I use the "<%= pod.node_name %>" node
    And I ensure "pod-<%= project.name %>" pod is deleted
    And I run commands on the host:
      |ls -a <%= pv(pvc.volume_name).local_path %> |
    Then the step should succeed
    And the output should contain:
      | hello      |
      | .testfile1 |

    Given I ensure "pvc-<%= project.name %>" pvc is deleted
    And the "<%= pvc.volume_name %>" PV becomes :available within 60 seconds
    And I run commands on the host:
      |ls -a <%= pv(pvc.volume_name).local_path %> |
    Then the step should succeed
    And the output should not contain:
      | hello      |
      | .testfile1 |

  # @author piqin@redhat.com
  # @case_id OCP-15475
  @admin
  @destructive
  Scenario: When node does not have kubernetes.io/hostname label, provisioner pod should report error
    Given I have a StorageClass named "local-fast"

    Given I select a random node's host
    Then evaluation of `node.name` is stored in the :node_name clipboard

    Given the node labels are restored after scenario
    When I run the :label admin command with:
      | resource | node                    |
      | name     | <%= cb.node_name %>     |
      | key_val  | kubernetes.io/hostname- |
    Then the step should succeed

    When I delete the local storage provisioner for node "<%= cb.node_name %>"
    Then the step should succeed

    Given 10 seconds have passed
    When I get the log of local storage provisioner for node "<%= cb.node_name %>"
    Then the step should succeed
    And the output should contain:
      | Node does not have expected label kubernetes.io/hostname |

  # @author piqin@redhat.com
  # @case_id OCP-19117
  @admin
  Scenario: Volume with Block VolumeMode could be used by Pod
    Given I have a StorageClass named "block-devices"

    Given I have a project

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/block/pvc-dynamic.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 100Mi                   |
      | ["spec"]["storageClassName"]                 | block-devices           |
    Then the step should succeed

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod-with-block-volume.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeDevices"][0]["devicePath"]  | /dev/local0             |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | ls | /dev/local0 |
    Then the step should succeed
