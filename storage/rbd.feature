Feature: Storage of Ceph plugin testing

  # @author wehe@redhat.com
  # @case_id OCP-9933
  @admin
  @destructive
  Scenario: Ceph persistent volume with invalid monitors
    Given I have a project

    #Create a invalid pv with rbd of wrong monitors
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/rbd-secret.yaml |
    Then the step should succeed
    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/pv-retain.json"
    And I replace content in "pv-retain.json":
      | /\d{3}/ | 000 |
    When admin creates a PV from "pv-retain.json" where:
      | ["metadata"]["name"] | rbd-<%= project.name %> |
    Then the step should succeed

    #Create ceph pvc
    When I create a manual pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"] | rbdc |
    Then the step should succeed
    And the PV becomes :bound

    Given SCC "privileged" is added to the "default" user
    And SCC "privileged" is added to the "system:serviceaccounts" group

    #Create the pod
    And I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/pod.json |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pods  |
      | name     | rbdpd |
    Then the output should contain:
      | Connection timed out |
    """

  # @author jhou@redhat.com
  # @case_id OCP-9701
  @admin
  Scenario: Ceph rbd security testing
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project

    Given I have a project

    And I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-rbd-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | cephrbdprovisioner          |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                         |
    Then the step should succeed
    And the "pvc-rbd-<%= project.name %>" PVC becomes :bound within 120 seconds

    # Switch to admin to bypass scc
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/auto/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | rbd-<%= project.name %>     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-rbd-<%= project.name %> |
    Then the step should succeed
    And the pod named "rbd-<%= project.name %>" becomes ready

    # Verify uid and gid are correct
    When I execute on the "rbd-<%= project.name %>" pod:
      | id | -u |
    Then the output should contain:
      | 101010 |
    When I execute on the "rbd-<%= project.name %>" pod:
      | id | -G |
    Then the output should contain:
      | 123456 |

    # Verify mount directory has supplemental groups set properly
    # Verify SELinux context is set properly
    When I execute on the "rbd-<%= project.name %>" pod:
      | ls | -lZd | /mnt/rbd |
    Then the output should match:
      | 123456                                   |
      | (svirt_sandbox_file_t\|container_file_t) |
      | s0:c2,c13                                |

    # Verify created file belongs to supplemental group
    Given I execute on the "rbd-<%= project.name %>" pod:
      | touch | /mnt/rbd/rbd_testfile |
    When I execute on the "rbd-<%= project.name %>" pod:
      | ls | -l | /mnt/rbd/rbd_testfile |
    Then the output should contain:
      | 123456 |

    # Testing execute permission
    Given I execute on the "rbd-<%= project.name %>" pod:
      | cp | /hello | /mnt/rbd/hello |
    When I execute on the "rbd-<%= project.name %>" pod:
      | /mnt/rbd/hello |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift Storage |

  # @author jhou@redhat.com
  # @case_id OCP-9635
  @admin
  Scenario: Create Ceph rbd pod which reference the rbd server directly from pod template
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project

    Given I have a project

    And I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1               |
      | ["spec"]["storageClassName"]                 | cephrbdprovisioner |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound within 120 seconds

    # Copy secret to user namespace
    Given I run the :get admin command with:
      | resource      | secret         |
      | resource_name | cephrbd-secret |
      | namespace     | default        |
      | o             | yaml           |
    And evaluation of `@result[:parsed]["data"]["key"]` is stored in the :secret_key clipboard
    And I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/user_secret.yaml" replacing paths:
      | ["data"]["key"] | <%= cb.secret_key %> |
    Then the step should succeed

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name %>" in the :image clipboard
    # Switch to admin to bypass scc
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/pod-inline.json" replacing paths:
      | ["spec"]["volumes"][0]["rbd"]["monitors"][0] | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["spec"]["volumes"][0]["rbd"]["image"]       | <%= cb.image %>                                     |
    Then the step should succeed
    And the pod named "rbd" becomes ready

  # @author lxia@redhat.com
  # @case_id OCP-9693
  @admin
  Scenario: [storage_201] Only one pod with rbd volume can be scheduled when NoDiskConflicts policy is enabled
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project

    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>                   |
      | node_selector | <%= cb.proj_name %>=labelForTC510534  |
      | admin         | <%= user.name %>                      |
    Then the step should succeed

    Given I store the ready and schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=labelForTC510534" is added to the "<%= cb.nodes[0].name %>" node

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project

    And I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1               |
      | ["spec"]["storageClassName"]                 | cephrbdprovisioner |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound within 120 seconds

    # Copy secret to user namespace
    Given I run the :get admin command with:
      | resource      | secret         |
      | resource_name | cephrbd-secret |
      | namespace     | default        |
      | o             | yaml           |
    And evaluation of `@result[:parsed]["data"]["key"]` is stored in the :secret_key clipboard
    And I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/user_secret.yaml" replacing paths:
      | ["data"]["key"] | <%= cb.secret_key %> |
    Then the step should succeed

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name %>" in the :image clipboard
    # Switch to admin to bypass scc
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project


    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/pod-inline.json" replacing paths:
      | ["metadata"]["name"]                         | rbd-pod1-<%= project.name %>                        |
      | ["spec"]["volumes"][0]["rbd"]["monitors"][0] | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["spec"]["volumes"][0]["rbd"]["image"]       | <%= cb.image %>                                     |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-rbd/master/pod-direct.json" replacing paths:
      | ["metadata"]["name"]                         | rbd-pod2-<%= project.name %>                        |
      | ["spec"]["volumes"][0]["rbd"]["monitors"][0] | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["spec"]["volumes"][0]["rbd"]["image"]       | <%= cb.image %>                                     |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | pod                          |
      | name     | rbd-pod2-<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | Pending          |
      | FailedScheduling |
      | NoDiskConflict   |

    When I get project events
    Then the step should succeed
    And the output should contain:
      | FailedScheduling |
      | NoDiskConflict   |

  # @author jhou@redhat.com
  # @case_id OCP-10269
  @admin
  Scenario: Reclaim a dynamically provisioned Ceph RBD volumes
    Given I have a StorageClass named "cephrbdprovisioner"
    # CephRBD provisioner needs secret, verify secret and StorageClass both exists
    And admin checks that the "cephrbd-secret" secret exists in the "default" project
    And I have a project

    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | cephrbdprovisioner      |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Delete"

    # Test auto deleting PV
    Given I run the :delete client command with:
      | object_type       | pvc                     |
      | object_name_or_id | pvc-<%= project.name %> |
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 60 seconds

  # @author lizhou@redhat.com
  # @case_id OCP-13621
  @admin
  Scenario: rbd volumes should be accessible by multiple pods with readonly permission
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project

    Given admin creates a project with a random schedulable node selector
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1               |
      | ["spec"]["storageClassName"]                 | cephrbdprovisioner |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound within 120 seconds
    And I save volume id from PV named "<%= pvc('pvc1').volume_name %>" in the :image clipboard

    Given I run the :get admin command with:
      | resource      | secret         |
      | resource_name | cephrbd-secret |
      | namespace     | default        |
      | o             | yaml           |
    And evaluation of `@result[:parsed]["data"]["key"]` is stored in the :secret_key clipboard
    And I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/user_secret.yaml" replacing paths:
      | ["data"]["key"] | <%= cb.secret_key %> |
    Then the step should succeed

    # If a volume has no disk format, it can not be mounted readOnly. Ref: https://github.com/kubernetes/kubernetes/blob/master/pkg/util/mount/mount_linux.go#L503
    # Create a Pod here to have the disk formatted.
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc1                    |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/rbd                |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready
    And I ensure "pod-<%= project.name %>" pod is deleted

    Given I run the steps 2 times:
    """
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/pod-inline.json" replacing paths:
      | ["metadata"]["name"]                                 | rbd-pod#{cb.i}-<%= project.name %>                  |
      | ["spec"]["volumes"][0]["rbd"]["monitors"][0]         | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["spec"]["volumes"][0]["rbd"]["image"]               | <%= cb.image %>                                     |
      | ["spec"]["volumes"][0]["rbd"]["readOnly"]            | true                                                |
    Then the step should succeed
    And the pod named "rbd-pod#{cb.i}-<%= project.name %>" becomes ready
    """

    # Check mount point and mount options on the node
    Given I use the "<%= node.name %>" node
    When I run commands on the host:
      | mount |
    Then the output should match:
      | .*rbd.*ro.* |

  # @author jhou@redhat.com
  # @case_id OCP-15839
  @admin
  Scenario: Supporting features parameter in rbd StorageClass
    Given I have a StorageClass named "cephrbdprovisioner"
    And I have a project

    When admin creates a StorageClass from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/storageclass_with_features.yaml" where:
      | ["metadata"]["name"]            | sc-<%= project.name %>                              |
      | ["parameters"]["monitors"]      | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["parameters"]["imageFormat"]   | 1                                                   |
      | ["parameters"]["imageFeatures"] | layering                                            |
    Then the step should succeed

    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

  # @author jhou@redhat.com
  @admin
  @destructive
  Scenario Outline: Supporting fstype parameter in rbd StorageClass
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project
    And evaluation of `secret.raw_value_of("key")` is stored in the :secret_key clipboard

    Given I have a project
    When admin creates a StorageClass from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/storageclass_with_fstype.yaml" where:
      | ["metadata"]["name"]          | sc-<%= project.name %>                              |
      | ["parameters"]["monitors"]    | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["parameters"]["fstype"]      | <fstype>                                            |
      | ["parameters"]["imageFormat"] | 1                                                   |
    Then the step should succeed

    Given I have a project
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    Given I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/user_secret.yaml" replacing paths:
      | ["metadata"]["name"] | cephrbd-secret       |
      | ["data"]["key"]      | <%= cb.secret_key %> |
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/rbd                |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | df | -T | /mnt/rbd |
    Then the step should succeed
    And the output should contain:
      | <fstype> |

    Examples:
      | fstype |
      | xfs    | # @case_id OCP-16123

  # @author jhou@redhat.com
  # @case_id OCP-17275
  @admin
  Scenario: Configure 'Retain' reclaim policy for CephRBD
    Given I have a StorageClass named "cephrbdprovisioner"
    And I have a project

    When admin creates a StorageClass from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/storageclass_retain.yaml" where:
      | ["metadata"]["name"]          | sc-<%= project.name %>                              |
      | ["parameters"]["monitors"]    | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["parameters"]["imageFormat"] | 1                                                   |
      | ["reclaimPolicy"]             | Retain                                              |
    Then the step should succeed

    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Retain"

    When I ensure "pvc-<%= project.name %>" pvc is deleted
    Given I run the :get admin command with:
      | resource      | pv             |
      | resource_name | <%= pv.name %> |
    Then the output should contain:
      | Released |
    And admin ensures "<%= pv.name %>" pv is deleted

  # @author jhou@redhat.com
  # @case_id OCP-17261
  @admin
  Scenario: Using mountOptions for Ceph RBD StorageClass
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project
    And evaluation of `secret.raw_value_of("key")` is stored in the :secret_key clipboard

    Given I have a project
    When admin creates a StorageClass from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/storageclass_mount_optins.yaml" where:
      | ["metadata"]["name"]          | sc-<%= project.name %>                              |
      | ["parameters"]["monitors"]    | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["parameters"]["imageFormat"] | 1                                                   |
      | ["mountOptions"][0]           | discard                                             |
      | ["mountOptions"][1]           | noatime                                             |
    Then the step should succeed

    Given I have a project
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    Given I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/user_secret.yaml" replacing paths:
      | ["metadata"]["name"] | cephrbd-secret       |
      | ["data"]["key"]      | <%= cb.secret_key %> |
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/rbd                |
    Then the step should succeed

    Given the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | grep | rbd | /etc/mtab | /proc/mounts |
    Then the output should contain:
      | discard |
      | noatime |
    Given I ensure "pod-<%= project.name %>" pod is deleted
    And I ensure "pvc-<%= project.name %>" pvc is deleted

  # @author jhou@redhat.com
  # @case_id OCP-19116
  @admin
  Scenario: RBD block volumeMode support
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project

    And admin creates a project with a random schedulable node selector

    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1               |
      | ["spec"]["storageClassName"]                 | cephrbdprovisioner |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound within 120 seconds

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name %>" in the :image clipboard

    When admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/block/pv.json" where:
      | ["metadata"]["name"]                 | pv-<%= project.name %>                              |
      | ["spec"]["accessModes"][0]           | ReadWriteOnce                                       |
      | ["spec"]["volumeMode"]               | Block                                               |
      | ["spec"]["rbd"]["monitors"][0]       | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["spec"]["rbd"]["image"]             | <%= cb.image %>                                     |
    Then the step should succeed
    When I create a manual pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/block/pvc.json" replacing paths:
      | ["metadata"]["name"]       | pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce           |
      | ["spec"]["volumeMode"]     | Block                   |
      | ["spec"]["volumeName"]     | pv-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/rbd/block/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeDevices"][0]["devicePath"]  | /dev/rbd5               |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the "pod-<%= project.name %>" pod:
      | ls | /dev/rbd5 |
    Then the step should succeed

  # @author jhou@redhat.com
  # @case_id OCP-19187
  @admin
  Scenario: Dynamically provision RBD volume with block volumeMode
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project
    And I have a project

    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1               |
      | ["spec"]["storageClassName"]                 | cephrbdprovisioner |
      | ["spec"]["volumeMode"]                       | Block              |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound within 120 seconds

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod-with-block-volume.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc1                    |
      | ["spec"]["containers"][0]["volumeDevices"][0]["devicePath"]  | /dev/block              |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the "pod-<%= project.name %>" pod:
      | ls | /dev/block |
    Then the step should succeed

