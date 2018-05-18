Feature: volumeMounts should be able to use subPath
  # @author jhou@redhat.com
  # @case_id OCP-14087
  @admin
  Scenario: Subpath should receive right permissions - emptyDir
    Given I have a project
    When I run the :create admin command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/emptydir/subpath.yml |
        | n | <%= project.name %>                                                                                        |
    Then the step should succeed
    Given the pod named "subpath" becomes ready

    When admin executes on the pod:
      | ls | -ld | /mnt/direct |
    Then the output should contain:
      | drwxrwsrwx |
    When admin executes on the pod:
      | ls | -ld | /mnt/subpath |
    Then the output should contain:
      | drwxrwsrwx |

    When admin executes on the pod:
      | touch | /mnt/subpath/testfile |
    Then the step should succeed

  # @author jhou@redhat.com
  # @case_id OCP-18302
  Scenario: Subpath with secret volume
    Given I have a project
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/secret.yaml |
        | n | <%= project.name %>                                                                                       |
    Then the step should succeed

    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/secret-subpath.json |
        | n | <%= project.name %>                                                                                               |
    Then the step should succeed
    And the pod named "subpath" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18303
  Scenario: Subpath with configmap volume
    Given I have a project
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/configmap.yaml |
        | n | <%= project.name %>                                                                                          |
    Then the step should succeed

    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/configmap-subpath.yaml |
        | n | <%= project.name %>                                                                                                  |
    Then the step should succeed
    And the pod named "configmap" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18304
  Scenario: Subpath with downwardAPI volume
    Given I have a project
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/downwardApi-subpath.yaml |
        | n | <%= project.name %>                                                                                                    |
    Then the step should succeed
    And the pod named "pod-dapi-volume" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18305
  Scenario: Subpath with projected volume
    Given I have a project
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/secret.yaml |
        | n | <%= project.name %>                                                                                       |
    Then the step should succeed
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/configmap.yaml |
        | n | <%= project.name %>                                                                                          |
    Then the step should succeed

    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/projected-subpath.yaml |
        | n | <%= project.name %>                                                                                                  |
    Then the step should succeed
    And the pod named "volume-test" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18407
  @admin
  @destructive
  Scenario: Subpath with NFS volume
    Given I have a project
    And I have a NFS service in the project

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0]                | ReadWriteMany                    |
      | ["spec"]["capacity"]["storage"]           | 1Gi                              |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                           |
      | ["metadata"]["name"]                      | nfs-<%= project.name %>          |
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]                         | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | nfs-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                      |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany            |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/nfs-subpath.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | ls | -ld | /mnt/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/test_file |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

  # @author jhou@redhat.com
  # @case_id OCP-18408
  @admin
  @destructive
  Scenario: Subpath with iSCSI volume
    Given I have a iSCSI setup in the environment
    And I have a project

    And admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]              | pv-iscsi-<%= project.name %> |
      | ["spec"]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip %>:3260      |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | pvc-iscsi-<%= project.name %> |
      | ["spec"]["volumeName"] | pv-iscsi-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-iscsi-<%= project.name %>" PVC becomes bound to the "pv-iscsi-<%= project.name %>" PV

    # Create tester pod
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/iscsi-subpath.json" replacing paths:
      | ["metadata"]["name"]                                         | iscsi-<%= project.name %>     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-iscsi-<%= project.name %> |
    Then the step should succeed
    And the pod named "iscsi-<%= project.name %>" becomes ready

    When I execute on the "iscsi-<%= project.name %>" pod:
      | id | -u |
    Then the output should contain:
      | 101010 |
    When I execute on the "iscsi-<%= project.name %>" pod:
      | id | -G |
    Then the output should contain:
      | 123456 |

    # Verify mount directory has supplemental groups set properly
    # Verify SELinux context is set properly
    When I execute on the "iscsi-<%= project.name %>" pod:
      | ls | -lZd | /mnt/iscsi |
    Then the output should match:
      | 123456                                   |
      | (svirt_sandbox_file_t\|container_file_t) |
      | s0:c2,c13                                |

    When I execute on the pod:
      | touch | /mnt/iscsi/testfile |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/iscsi/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

  # @author jhou@redhat.com
  # @case_id OCP-18424
  @admin
  Scenario: Subpath with glusterfs volume
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/gluster/dynamic-provisioning/claim.yaml" replacing paths:
        | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
        | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | glusterprovisioner      |
        | ["spec"]["resources"]["requests"]["storage"]                           | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/glusterfs-subpath.json" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | ls | -ld | /mnt/gluster/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/gluster/testfile |
    Then the step should succeed
    When I execute on the "pod-<%= project.name %>" pod:
      | /mnt/gluster/hello |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift Storage |

  # @author jhou@redhat.com
  # @case_id OCP-18425
  @admin
  Scenario: Subpath with gluster-block volume
    Given I have a StorageClass named "gluster-block"
    And I have a project

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/gluster/dynamic-provisioning/claim.yaml" replacing paths:
        | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
        | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | gluster-block           |
        | ["spec"]["resources"]["requests"]["storage"]                           | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/glusterfs-subpath.json" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | ls | -ld | /mnt/gluster/ |
    Then the output should contain:
      | drwxr-sr-x |
    When I execute on the pod:
      | touch | /mnt/gluster/testfile |
    Then the step should succeed
    When I execute on the "pod-<%= project.name %>" pod:
      | /mnt/gluster/hello |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift Storage |

  # @author jhou@redhat.com
  # @case_id OCP-18423
  @admin
  Scenario: Subpath with rbd volume
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project
    And I have a project

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/rbd/dynamic-provisioning/claim.yaml" replacing paths:
        | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
        | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | cephrbdprovisioner      |
        | ["spec"]["resources"]["requests"]["storage"]                           | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound

    # Create tester pod
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/rbd-subpath.json" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the "pod-<%= project.name %>" pod:
      | id | -u |
    Then the output should contain:
      | 101010 |
    When I execute on the "pod-<%= project.name %>" pod:
      | id | -G |
    Then the output should contain:
      | 123456 |
    When I execute on the "pod-<%= project.name %>" pod:
      | ls | -ld | /mnt/rbd |
    Then the output should contain:
      | 123456     |
      | drwxr-sr-x |
    When I execute on the pod:
      | touch | /mnt/rbd/testfile |
    Then the step should succeed
    When I execute on the "pod-<%= project.name %>" pod:
      | /mnt/rbd/hello |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift Storage |

  # @author jhou@redhat.com
  # @case_id OCP-18426
  @admin
  Scenario: Subpath with CephFS volume
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project
    And I have a project

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/cephfs/pv-retain.json" where:
      | ["metadata"]["name"]                         | pv-cephfs-server-<%= project.name %>                |
      | ["spec"]["cephfs"]["monitors"][0]            | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["spec"]["cephfs"]["secretRef"]["name"]      | cephrbd-secret                                      |
      | ["spec"]["cephfs"]["secretRef"]["namespace"] | default                                             |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/cephfs/pvc-cephfs.json" replacing paths:
      | ["metadata"]["name"]   | pvc-cephfs-<%= project.name %>       |
      | ["spec"]["volumeName"] | pv-cephfs-server-<%= project.name %> |
    Then the step should succeed
    And the "pvc-cephfs-<%= project.name %>" PVC becomes bound to the "pv-cephfs-server-<%= project.name %>" PV

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/cephfs-subpath.json" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %>        |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-cephfs-<%= project.name %> |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18426
  @admin
  Scenario Outline: Subpath with cloud volumes
    Given I have a project

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"]                           | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/common-subpath.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/iaas               |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the "pod-<%= project.name %>" pod:
      | touch | /mnt/iaas/testfile |
    Then the step should succeed
    When I execute on the "pod-<%= project.name %>" pod:
      | ls | /mnt/iaas/ |
    Then the output should contain:
      | testfile |

    When I execute on the "pod-<%= project.name %>" pod:
      | ls | -ld | /mnt/iaas/ |
    Then the output should contain:
      | drwxr-sr-x |
    When I execute on the "pod-<%= project.name %>" pod:
      | /mnt/iaas/hello |
    Then the output should contain:
      | Hello OpenShift Storage |

    Examples:
      | provisioner    |
      | vsphere-volume | # @case_id OCP-18422
      | gce-pd         | # @case_id OCP-18419
      | aws-ebs        | # @case_id OCP-18418
      | cinder         | # @case_id OCP-18421
      | azure-disk     | # @case_id OCP-18420

  # @author chaoyang@redhat.com
  # @case_id OCP-18429
  @admin
  Scenario: Subpath with EFS volume
    Given I have a project
    And I have a efs-provisioner in the project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/class.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | openshift.org/aws-efs  |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | efspvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>     |
    Then the step should succeed
    And the "efspvc-<%= project.name %>" PVC becomes :bound within 60 seconds

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/subpath/nfs-subpath.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | efspvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %>  |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | ls | -ld | /mnt/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/test_file |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

