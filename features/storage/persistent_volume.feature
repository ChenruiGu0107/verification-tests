Feature: Persistent Volume Claim binding policies
  # @author lxia@redhat.com
  # @case_id OCP-10925
  @admin
  Scenario: describe pv should show messages and events
    Given I have a project
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]                      | pv-<%= project.name %> |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce          |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Recycle                |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | pvc-<%= project.name %> |
      | ["spec"]["volumeName"]     | pv-<%= project.name %>  |
      | ["spec"]["accessModes"][0] | ReadWriteOnce           |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

    Given I ensure "pvc-<%= project.name %>" pvc is deleted
    And I wait up to 600 seconds for the steps to pass:
    """
    When I run the :describe admin command with:
      | resource | pv                     |
      | name     | pv-<%= project.name %> |
    Then the step should succeed
    And the output should match:
      | Message:\s+Recycle failed |
      | Events:                   |
    """

  # @author jhou@redhat.com
  # @author wehe@redhat.com
  # @author chaoyang@redhat.com
  @admin
  @destructive
  Scenario Outline: PVC with one accessMode can bind PV with all accessMode
    # Preparations
    Given I have a project

    # Create 2 PVs
    # Create PV with all accessMode
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template-all-access-modes.json" where:
      | ["metadata"]["name"] | nfs-<%= project.name %> |
    Then the step should succeed
    # Create PV without accessMode3
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv.json" where:
      | ["metadata"]["name"]       | nfs1-<%= project.name %> |
      | ["spec"]["accessModes"][0] | <accessMode1>            |
      | ["spec"]["accessModes"][1] | <accessMode2>            |
    Then the step should succeed

    # Create PVC with accessMode3
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["spec"]["accessModes"][0] | <accessMode3> |
    Then the step should succeed

    # First PV can bound
    And the "nfsc" PVC becomes bound to the "nfs-<%= project.name %>" PV
    # Second PV can not bound
    And the "nfs1-<%= project.name %>" PV status is :available

    Examples:
      | accessMode1   | accessMode2   | accessMode3   |
      | ReadOnlyMany  | ReadWriteMany | ReadWriteOnce | # @case_id OCP-9702
      | ReadOnlyMany  | ReadWriteOnce | ReadWriteMany | # @case_id OCP-10680
      | ReadWriteMany | ReadWriteOnce | ReadOnlyMany  | # @case_id OCP-11168

  # @author yinzhou@redhat.com
  # @case_id OCP-11933
  Scenario: deployment hook volume inheritance -- with persistentvolumeclaim Volume
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | nfsc |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/510610/hooks-with-nfsvolume.json |
    Then the step should succeed
  ## mount should be correct to the pod, no-matter if the pod is completed or not, check the case checkpoint
    And I wait for the steps to pass:
    """
    When I get project pod named "hooks-1-hook-pre" as YAML
    Then the output by order should match:
      | - mountPath: /opt1     |
      | name: v1               |
      | persistentVolumeClaim: |
      | claimName: nfsc        |
    """

  # @author wehe@redhat.com
  # @author chaoyang@redhat.com
  # @case_id OCP-9931
  @admin
  @destructive
  Scenario: PV can not bind PVC which request more storage and mismatched accessMode
    Given I have a project
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]       | pv-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadOnlyMany           |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadOnlyMany             |
      | ["spec"]["resources"]["requests"]["storage"] | 10Gi                     |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc2-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce            |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc3-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteMany            |
    Then the step should succeed
    And the "pvc1-<%= project.name %>" PVC becomes :pending
    And the "pvc2-<%= project.name %>" PVC becomes :pending
    And the "pvc3-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available
    Given I ensure "pvc1-<%= project.name %>" pvc is deleted
    And I ensure "pvc2-<%= project.name %>" pvc is deleted
    And I ensure "pvc3-<%= project.name %>" pvc is deleted
    And admin ensures "pv-<%= project.name %>" pv is deleted

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]       | pv-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce          |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce            |
      | ["spec"]["resources"]["requests"]["storage"] | 10Gi                     |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc2-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadOnlyMany             |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc3-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteMany            |
    Then the step should succeed
    And the "pvc1-<%= project.name %>" PVC becomes :pending
    And the "pvc2-<%= project.name %>" PVC becomes :pending
    And the "pvc3-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available
    Given I ensure "pvc1-<%= project.name %>" pvc is deleted
    And I ensure "pvc2-<%= project.name %>" pvc is deleted
    And I ensure "pvc3-<%= project.name %>" pvc is deleted
    And admin ensures "pv-<%= project.name %>" pv is deleted

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]       | pv-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteMany          |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany            |
      | ["spec"]["resources"]["requests"]["storage"] | 10Gi                     |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc2-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce            |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc3-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadOnlyMany             |
    Then the step should succeed
    And the "pvc1-<%= project.name %>" PVC becomes :pending
    And the "pvc2-<%= project.name %>" PVC becomes :pending
    And the "pvc3-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @case_id OCP-9937
  @admin
  @destructive
  Scenario: PV and PVC bound and unbound many times
    Given I have a project
    And I have a NFS service in the project

    #Create 20 pv
    Given I run the steps 20 times:
    """
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/tc522215/pv.json" where:
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
    Then the step should succeed
    """

    Given 20 PVs become :available within 20 seconds with labels:
      | usedFor=tc522215 |

    #Loop 5 times about pv and pvc bound and unbound
    Given I run the steps 5 times:
    """
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/tc522215/pvc-20.json |
    Given 20 PVCs become :bound within 50 seconds with labels:
      | usedFor=tc522215 |
    Then I run the :delete client command with:
      | object_type | pvc |
      | all         | all |
    Given 20 PVs become :available within 500 seconds with labels:
      | usedFor=tc522215 |
    """

  # @author lxia@redhat.com
  # @case_id OCP-10782
  @admin
  @destructive
  Scenario: [public_storage_70] Persistent volume attach should not be race when starting pods
    Given I have a project
    And I have a NFS service in the project

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]                      | nfs-<%= project.name %>          |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce                    |
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Recycle                          |
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]     | nfs-<%= project.name %>  |
      | ["spec"]["accessModes"][0] | ReadWriteOnce            |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    Given I run the steps 100 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I run the :describe client command with:
      | resource | pod                       |
      | name     | mypod-<%= project.name %> |
    Then the output should not contain:
      | not all containers have started |
      | 0 != 1                          |
    When I execute on the pod:
      | mountpoint | -d | /mnt |
    Then the step should succeed
    When I execute on the pod:
      | bash                  |
      | -c                    |
      | date >> /mnt/testfile |
    Then the step should succeed
    Given I ensure "mypod-<%= project.name %>" pod is deleted
    """

  # @author lxia@redhat.com
  # @case_id OCP-9928
  @admin
  @destructive
  Scenario: PVC should bound the PV with most appropriate access mode and size
    Given default storage class is deleted
    Given I have a project
    And I have a NFS service in the project
    And I register clean-up steps:
      | I run the :delete admin command with: |
      | ! object_type ! pv               !    |
      | ! l           ! usedFor=tc522127 !    |
      | the step should succeed               |

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/pv-template.json"
    Then I replace lines in "pv-template.json":
      | #NS#             | <%= project.name %>              |
      | #NFS-Service-IP# | <%= service("nfs-service").ip %> |
    Then I run the :new_app admin command with:
      | file | pv-template.json |
    Then the step should succeed

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/pvc-template.json"
    Then I replace lines in "pvc-template.json":
      | #NS# | <%= project.name %> |
    Then I run the :new_app client command with:
      | file | pvc-template.json |
    Then the step should succeed

    Given the "pvcname-1m-rox-<%= project.name %>" PVC becomes bound to the "pvname-127m-rox-<%= project.name %>" PV
    And the "pvcname-128m-rox-<%= project.name %>" PVC becomes bound to the "pvname-128m-rox-<%= project.name %>" PV
    And the "pvcname-130m-rox-<%= project.name %>" PVC becomes bound to the "pvname-255m-rox-<%= project.name %>" PV
    And the "pvname-129m-rox-<%= project.name %>" PV status is :available
    And the "pvname-256m-rox-<%= project.name %>" PV status is :available
    And the "pvname-257m-rox-<%= project.name %>" PV status is :available
    And the "pvcname-258m-rox-<%= project.name %>" PVC becomes :pending

    Given the "pvcname-1m-rwo-<%= project.name %>" PVC becomes bound to the "pvname-127m-rwo-<%= project.name %>" PV
    And the "pvcname-128m-rwo-<%= project.name %>" PVC becomes bound to the "pvname-128m-rwo-<%= project.name %>" PV
    And the "pvcname-130m-rwo-<%= project.name %>" PVC becomes bound to the "pvname-255m-rwo-<%= project.name %>" PV
    And the "pvname-129m-rwo-<%= project.name %>" PV status is :available
    And the "pvname-256m-rwo-<%= project.name %>" PV status is :available
    And the "pvname-257m-rwo-<%= project.name %>" PV status is :available
    And the "pvcname-258m-rwo-<%= project.name %>" PVC becomes :pending

    Given the "pvcname-1m-rwx-<%= project.name %>" PVC becomes bound to the "pvname-127m-rwx-<%= project.name %>" PV
    And the "pvcname-128m-rwx-<%= project.name %>" PVC becomes bound to the "pvname-128m-rwx-<%= project.name %>" PV
    And the "pvcname-130m-rwx-<%= project.name %>" PVC becomes bound to the "pvname-255m-rwx-<%= project.name %>" PV
    And the "pvname-129m-rwx-<%= project.name %>" PV status is :available
    And the "pvname-256m-rwx-<%= project.name %>" PV status is :available
    And the "pvname-257m-rwx-<%= project.name %>" PV status is :available
    And the "pvcname-258m-rwx-<%= project.name %>" PVC becomes :pending

  # @author lxia@redhat.com
  # @case_id OCP-10145
  # @bug_id 1337106
  @admin
  @destructive
  Scenario: Pre-bound PVC with invalid PV should have consistent status
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"] | pv-<%= project.name %> |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | pvc-<%= project.name %> |
      | ["spec"]["volumeName"] | pv1-<%= project.name %> |
    Then the step should succeed
    And the "pv-<%= project.name %>" PV status is :available
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available

  # @author lxia@redhat.com
  # @case_id OCP-12680
  # @bug_id 1337106
  @admin
  @destructive
  Scenario: Pre-bound PV with invalid PVC should have consistent status
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/preboundpv-rwo.yaml" where:
      | ["metadata"]["name"]              | pv-<%= project.name %>   |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>      |
      | ["spec"]["claimRef"]["name"]      | pvc1-<%= project.name %> |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwx.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pv-<%= project.name %>" PV status is :available
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available

  # @author wehe@redhat.com
  # @case_id OCP-10172
  @admin
  Scenario: Check the pvc capacity
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/nfs-retain-rox.json" where:
      | ["metadata"]["name"]              | pv-<%= project.name %>   |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rox.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV
    When I get project pvc named "pvc-<%= project.name %>"
    Then the output should contain:
      | ROX |
      | 5Gi |

  # @author lxia@redhat.com
  # @case_id OCP-10187
  @admin
  Scenario: PV creation negative testing
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/nfs-default.json |
    Then the step should fail
    And the output should contain:
      | Unsupported value: "Default" |

  # @author lzhou@redhat.com
  # @author jhou@redhat.com
  @admin
  Scenario Outline: Volume should be successfully detached if pod is deleted via namespace deletion
    Given admin creates a project with a random schedulable node selector

    # Create storageclass
    When admin creates a StorageClass in the node's zone from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %>      |
      | ["provisioner"]      | kubernetes.io/<provisioner> |
    Then the step should succeed

    # Create dynamic pvc
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                                                   | dynamic-pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce                   |
      | ["spec"]["resources"]["requests"]["storage"]                           | 1Gi                             |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>          |
    Then the step should succeed
    And the "dynamic-pvc-<%= project.name %>" PVC becomes :bound
    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | dynamic-pvc-<%= project.name %> |

    # Create pod using above pvc
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %>       |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/<platform>                 |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready

    # Check mount point on the node
    Given I use the "<%= node.name %>" node
    When I run commands on the host:
      | mount |
    Then the output should contain:
      | <%= pvc.volume_name(user: user) %> |

    # Read and write to the mounted storage on pod
    When I execute on the pod:
      | ls    | /mnt/<platform>/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/<platform>/testfile |
    Then the step should succeed

    # Delete the project, the pv will be deleted then
    Given I switch to cluster admin pseudo user
    Given I ensure "<%= project.name %>" project is deleted
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: user) %>" to disappear

    # Check mount point on the node
    Given I use the "<%= node.name %>" node
    When I run commands on the host:
      | mount |
    Then the output should not contain:
      | <%= pvc.volume_name(user: user) %> |

    Examples:
      | provisioner    | platform |
      | cinder         | cinder   | # @case_id OCP-13358
      | gce-pd         | gce      | # @case_id OCP-13384
      | aws-ebs        | aws      | # @case_id OCP-13383
      | azure-disk     | azure    | # @case_id OCP-13385
      | vsphere-volume | vsphere  | # @case_id OCP-13392

  # @author wehe@redhat.com
  # @case_id OCP-16094
  # @bug_id 1496256 
  @admin
  @destructive
  Scenario: Deleted in use PVCs cannot break the scheduler 
    Given I have a project
    And I have a NFS service in the project
    And evaluation of `service("nfs-service").ip` is stored in the :nfs_ip clipboard
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %> |
      | ["spec"]["nfs"]["server"] | <%= cb.nfs_ip %>        |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready
    And I ensure "nfsc" pvc is deleted
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | noneexistone |
    Then the step should succeed
    And the "nfsc" PVC becomes :pending
    Given I create a new project
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %> |
      | ["spec"]["nfs"]["server"] | <%= cb.nfs_ip %>        |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready

  # @author lxia@redhat.com
  # @case_id OCP-16190
  # @bug_id 1496256
  Scenario: Deleted in use PVCs will not break the scheduler
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | nfsc |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready
    And I ensure "nfsc" pvc is deleted
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]   | nfsc         |
      | ["spec"]["volumeName"] | noneexistone |
    Then the step should succeed
    And the "nfsc" PVC becomes :pending
    Given I switch to the second user
    And I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | nfsc |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready

  # @author wehe@redhat.com
  # @case_id OCP-16531
  @admin
  Scenario: Two pods work well on different node with access mode ReadWriteMany
    Given I have a project
    And environment has at least 2 schedulable nodes
    And I have a NFS service in the project
    Given I store the schedulable nodes in the clipboard
    And label "accessmodes=rwx1" is added to the "<%= cb.nodes[0].name %>" node
    And label "accessmodes=rwx2" is added to the "<%= cb.nodes[1].name %>" node
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes bound to the "nfs-<%= project.name %>" PV
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["metadata"]["name"]               | mypod1                |
      | ["spec"]["containers"][0]["image"] | aosqe/hello-openshift |
      | ["spec"]["nodeSelector"]           | accessmodes: rwx1     |
    Then the step should succeed
    Given the pod named "mypod1" becomes ready
    When I execute on the pod:
      | touch | /mnt/mypod1 |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["metadata"]["name"]               | mypod2                |
      | ["spec"]["containers"][0]["image"] | aosqe/hello-openshift |
      | ["spec"]["nodeSelector"]           | accessmodes: rwx2     |
    Then the step should succeed
    Given the pod named "mypod2" becomes ready
    When I execute on the pod:
      | touch | /mnt/mypod2 |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/ |
    Then the output should contain:
      | mypod1 |
      | mypod2 |
    Given I ensure "mypod1" pod is deleted
    Given I ensure "mypod2" pod is deleted

  # @author wehe@redhat.com
  # @case_id OCP-16607
  @admin
  Scenario: Two pods compete the same ReadWriteOnce volume 
    Given I have a project
    And environment has at least 2 schedulable nodes
    Given I store the schedulable nodes in the clipboard
    And label "accessmodes=rwo1" is added to the "<%= cb.nodes[0].name %>" node
    And label "accessmodes=rwo2" is added to the "<%= cb.nodes[1].name %>" node
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | nfsc |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["metadata"]["name"]               | mypod1                |
      | ["spec"]["containers"][0]["image"] | aosqe/hello-openshift |
      | ["spec"]["nodeSelector"]           | accessmodes: rwo1     |
    Then the step should succeed
    Given the pod named "mypod1" becomes ready
    When I execute on the pod:
      | touch | /mnt/mypod1 |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["metadata"]["name"]               | mypod2                |
      | ["spec"]["containers"][0]["image"] | aosqe/hello-openshift |
      | ["spec"]["nodeSelector"]           | accessmodes: rwo2     |
    Then the step should succeed
    Given the pod named "mypod2" status becomes :pending 
    When I run the :describe client command with:
      | resource | pod    |
      | name     | mypod2 |
    Then the output should contain:
      | Multi-Attach error for volume |
    Given I ensure "mypod1" pod is deleted
    And the pod named "mypod2" becomes ready
    When I execute on the pod:
      | touch | /mnt/mypod2 |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/ |
    Then the output should contain:
      | mypod1 |
      | mypod2 |
