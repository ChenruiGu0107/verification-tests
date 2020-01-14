Feature: Persistent Volume Claim binding policies
  # @author lxia@redhat.com
  # @case_id OCP-17734
  Scenario: Pod with overlapped mount points still works
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc1 |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc2 |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod-overlap-path.yaml" replacing paths:
      | ["metadata"]["name"] | mypod |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    And the "pvc1" PVC becomes :bound
    And the "pvc2" PVC becomes :bound
    When I execute on the pod:
      | touch | /mnt/openshift/file-in-mount-path1 |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/openshift/ocp/file-in-mount-path2 |
    Then the step should succeed
    When I execute on the pod:
      | ls | -aR | /mnt/openshift |
    Then the output should contain:
      | file-in-mount-path1 |
      | file-in-mount-path2 |

  # @author lxia@redhat.com
  # @case_id OCP-10925
  @admin
  Scenario: describe pv should show messages and events
    Given I have a project
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]                      | pv-<%= project.name %> |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce          |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Recycle                |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pvc-template.json" replacing paths:
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

  # @author lxia@redhat.com
  # @case_id OCP-10782
  @admin
  @destructive
  Scenario: [public_storage_70] Persistent volume attach should not be race when starting pods
    Given I have a project
    And I have a NFS service in the project

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]                      | nfs-<%= project.name %>          |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce                    |
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Recycle                          |
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]     | nfs-<%= project.name %>  |
      | ["spec"]["accessModes"][0] | ReadWriteOnce            |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    Given I run the steps 100 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json" replacing paths:
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
    Given I have a project
    And I have a NFS service in the project
    And I register clean-up steps:
      | I run the :delete admin command with: |
      | ! object_type ! pv               !    |
      | ! l           ! usedFor=tc522127 !    |
      | the step should succeed               |

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/pv-template.json"
    Then I replace lines in "pv-template.json":
      | #NS#             | <%= project.name %>              |
      | #NFS-Service-IP# | <%= service("nfs-service").ip %> |
    Then I run the :new_app admin command with:
      | file | pv-template.json |
    Then the step should succeed

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/pvc-template.json"
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

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"] | pv-<%= project.name %> |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pvc-template.json" replacing paths:
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
  Scenario: Pre-bound PV with invalid PVC should have consistent status
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/preboundpv-rwo.yaml" where:
      | ["metadata"]["name"]              | pv-<%= project.name %> |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>    |
      | ["spec"]["claimRef"]["name"]      | non-exist-pvc          |
      | ["spec"]["storageClassName"]      | sc-<%= project.name %> |
    Then the step should succeed
    And the "pv-<%= project.name %>" PV status is :available
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available

  # @author wehe@redhat.com
  # @case_id OCP-10172
  @admin
  Scenario: Check the pvc capacity
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/nfs-retain-rox.json" where:
      | ["metadata"]["name"]              | pv-<%= project.name %>   |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/claim-rox.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV
    And the expression should be true> pvc.capacity == "5Gi"
    And the expression should be true> pvc.access_modes[0] == "ReadOnlyMany"

  # @author lxia@redhat.com
  # @case_id OCP-10187
  @admin
  Scenario: PV creation negative testing
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/nfs-default.json |
    Then the step should fail
    And the output should contain:
      | Unsupported value: "Default" |

  # @author lxia@redhat.com
  # @case_id OCP-12972
  @admin
  Scenario: PV volume is unmounted and detached without failure if PV is deleted before pod referencing the volume
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And the "mysql" PVC becomes :bound
    And a pod becomes ready with labels:
      | name=mysql |

    Given I use the "<%= pod.node_name %>" node
    When I run commands on the host:
      | mount |
    Then the output should contain:
      | <%= pvc.volume_name %> |

    Given admin ensures "<%= pvc.volume_name %>" pv is deleted
    And I ensure "<%= project.name %>" project is deleted

    Given I use the "<%= pod.node_name %>" node
    When I run commands on the host:
      | mount |
    Then the output should not contain:
      | <%= pvc.volume_name %> |

  # @author lxia@redhat.com
  # @case_id OCP-12973
  @admin
  Scenario: PV volume is unmounted and detached without failure if PVC is deleted before pod referencing the volume
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And the "mysql" PVC becomes :bound
    And a pod becomes ready with labels:
      | name=mysql |

    Given I use the "<%= pod.node_name %>" node
    When I run commands on the host:
      | mount |
    Then the output should contain:
      | <%= pvc.volume_name %> |

    Given I ensure "<%= pvc.name %>" pvc is deleted
    And I ensure "<%= pod.name %>" pod is deleted

    Given I use the "<%= pod.node_name %>" node
    When I run commands on the host:
      | mount |
    Then the output should not contain:
      | <%= pvc.volume_name %> |

  # @author lxia@redhat.com
  # @case_id OCP-12974
  @admin
  Scenario: PV volume is unmounted and detached without failure if the namespace of PVC and pod is deleted
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And the "mysql" PVC becomes :bound
    And a pod becomes ready with labels:
      | name=mysql |

    Given I use the "<%= pod.node_name %>" node
    When I run commands on the host:
      | mount |
    Then the output should contain:
      | <%= pvc.volume_name %> |

    Given I ensure "<%= project.name %>" project is deleted

    Given I use the "<%= pod.node_name %>" node
    When I run commands on the host:
      | mount |
    Then the output should not contain:
      | <%= pvc.volume_name %> |

  # @author jhou@redhat.com
  @admin
  Scenario Outline: Volume should be successfully detached if pod is deleted via namespace deletion
    Given admin creates a project with a random schedulable node selector

    # Create storageclass
    When admin creates a StorageClass in the node's zone from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %>      |
      | ["provisioner"]      | kubernetes.io/<provisioner> |
    Then the step should succeed

    # Create dynamic pvc
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce                   |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                             |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>          |
    Then the step should succeed
    And the "dynamic-pvc-<%= project.name %>" PVC becomes :bound
    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | dynamic-pvc-<%= project.name %> |

    # Create pod using above pvc
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
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
      | <%= pvc.volume_name %> |

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
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear

    # Check mount point on the node
    Given I use the "<%= node.name %>" node
    When I run commands on the host:
      | mount |
    Then the output should not contain:
      | <%= pvc.volume_name %> |

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
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %> |
      | ["spec"]["nfs"]["server"] | <%= cb.nfs_ip %>        |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready
    And I ensure "nfsc" pvc is deleted
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | noneexistone |
    Then the step should succeed
    And the "nfsc" PVC becomes :pending
    Given I create a new project
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %> |
      | ["spec"]["nfs"]["server"] | <%= cb.nfs_ip %>        |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready

  # @author lxia@redhat.com
  # @case_id OCP-16190
  # @bug_id 1496256
  Scenario: Deleted in use PVCs will not break the scheduler
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | nfsc |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready
    And I ensure "nfsc" pvc is deleted
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]   | nfsc         |
      | ["spec"]["volumeName"] | noneexistone |
    Then the step should succeed
    And the "nfsc" PVC becomes :pending
    Given I switch to the second user
    And I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | nfsc |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready

  # @author wehe@redhat.com
  # @case_id OCP-16531
  @admin
  Scenario: Two pods work well on different node with access mode ReadWriteMany
    Given admin creates a project with:
      | node_selector |                  |
      | admin         | <%= user.name %> |
    And I use the "<%= project.name %>" project
    And environment has at least 2 schedulable nodes
    And I have a NFS service in the project

    Given I store the ready and schedulable nodes in the clipboard
    And label "accessmodes=rwx1" is added to the "<%= cb.nodes[0].name %>" node
    And label "accessmodes=rwx2" is added to the "<%= cb.nodes[1].name %>" node
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes bound to the "nfs-<%= project.name %>" PV
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json" replacing paths:
      | ["metadata"]["name"]               | mypod1                |
      | ["spec"]["containers"][0]["image"] | aosqe/hello-openshift |
      | ["spec"]["nodeSelector"]           | accessmodes: rwx1     |
    Then the step should succeed
    Given the pod named "mypod1" becomes ready
    When I execute on the pod:
      | touch | /mnt/mypod1 |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json" replacing paths:
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
    Given I store the ready and schedulable nodes in the clipboard
    And label "accessmodes=rwo1" is added to the "<%= cb.nodes[0].name %>" node
    And label "accessmodes=rwo2" is added to the "<%= cb.nodes[1].name %>" node
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | nfsc |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json" replacing paths:
      | ["metadata"]["name"]               | mypod1                |
      | ["spec"]["containers"][0]["image"] | aosqe/hello-openshift |
      | ["spec"]["nodeSelector"]           | accessmodes: rwo1     |
    Then the step should succeed
    Given the pod named "mypod1" becomes ready
    When I execute on the pod:
      | touch | /mnt/mypod1 |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json" replacing paths:
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

  # @author piqin@redhat.com
  # @case_id OCP-17550
  @admin
  Scenario: PV with Filesystem VolumeMode and PVC with unspecified VolumeMode should be bound successfully
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]   | pv-<%= project.name %> |
      | ["spec"]["volumeMode"] | Filesystem             |
    Then the step should succeed
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/claim.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author piqin@redhat.com
  # @case_id OCP-17552
  @admin
  Scenario: PV with Block VolumeMode and PVC with unspecified VolumeMode could not be bound
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]   | pv-<%= project.name %> |
      | ["spec"]["volumeMode"] | Block                  |
    Then the step should succeed
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/claim.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available
    When I run the :describe client command with:
      | resource | pvc                     |
      | name     | pvc-<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | FailedBinding                   |
      | no persistent volumes available |

  # @author piqin@redhat.com
  # @case_id OCP-17554
  @admin
  Scenario: PV with unspecified VolumeMode and PVC with Filesystem VolumeMode should be bound successfully
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"] | pv-<%= project.name %> |
    Then the step should succeed
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/claim.json" replacing paths:
      | ["metadata"]["name"]   | pvc-<%= project.name %> |
      | ["spec"]["volumeMode"] | Filesystem              |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author piqin@redhat.com
  # @case_id OCP-17555
  @admin
  Scenario: PV with unspecified VolumeMode and PVC with Block VolumeMode could not be bound
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]         | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/claim.json" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["volumeMode"]       | Block                   |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available
    When I run the :describe client command with:
      | resource | pvc                     |
      | name     | pvc-<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | FailedBinding                   |
      | no persistent volumes available |

  # @author piqin@redhat.com
  # @case_id OCP-17558
  @admin
  @destructive
  Scenario: PV's spec.VolumeMode field should be dropped when feature gate BlockVolume is not enabled
    Given feature gate "BlockVolume" is disabled

    Given I have a project
    And I have a NFS service in the project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]            | pv-<%= project.name %>           |
      | ["spec"]["nfs"]["server"]       | <%= service("nfs-service").ip %> |
      | ["spec"]["capacity"]["storage"] | 5Gi                              |
      | ["spec"]["volumeMode"]          | Block                            |
      | ["spec"]["accessModes"][0]      | ReadWriteMany                    |
    Then the step should succeed
    And the expression should be true> pv("pv-<%= project.name %>").volume_mode != "Block"
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/claim.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["volumeMode"]                       | Block                   |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany           |
      | ["spec"]["resources"]["requests"]["storage"] | 5Gi                     |
    Then the step should succeed
    And the expression should be true> pvc("pvc-<%= project.name %>").volume_mode != "Block"
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["containers"][0]["image"]                           | aosqe/hello-openshift     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>   |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | touch | /mnt/test_file |
    Then the step should succeed

  # @author piqin@redhat.com
  # @case_id OCP-17562
  @admin
  @destructive
  Scenario: Pod's spec.[init]containers.VolumeDevices field should be dropped when feature gate BlockVolume is not enabled
    Given feature gate "BlockVolume" is disabled

    Given I have a project
    And I have a NFS service in the project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]            | pv-<%= project.name %>           |
      | ["spec"]["nfs"]["server"]       | <%= service("nfs-service").ip %> |
      | ["spec"]["capacity"]["storage"] | 5Gi                              |
      | ["spec"]["accessModes"][0]      | ReadWriteMany                    |
    Then the step should succeed
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/claim.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany           |
      | ["spec"]["resources"]["requests"]["storage"] | 5Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/initcontainer-blockvolume-pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>   |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I get project pod named "mypod-<%= project.name %>" as YAML
    Then the output by order should not contain:
      | volumeDevices:          |
      | - devicePath: /dev/xvda |

  # @author piqin@redhat.com
  @admin
  Scenario Outline: PV and PVC with same VolumeMode, but with other invalid feild should not be bound
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]   | pv-<%= project.name %> |
      | ["spec"]["volumeMode"] | Block                  |
      | <pv_key>               | <pv_value>             |
    Then the step should succeed
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/claim.json" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["volumeMode"]       | Block                   |
      | <pvc_key>                    | <pvc_value>             |
    Then the step should succeed
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available
    When I run the :describe client command with:
      | resource | pvc                     |
      | name     | pvc-<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | FailedBinding                   |
      | no persistent volumes available |

    Examples:
      | pv_key                          | pv_value      | pvc_key                                      | pvc_value     |
      | ["spec"]["capacity"]["storage"] | 1Gi           | ["spec"]["resources"]["requests"]["storage"] | 5Gi           | # @case_id OCP-17561
      | ["spec"]["accessModes"][0]      | ReadWriteOnce | ["spec"]["accessModes"][0]                   | ReadWriteMany | # @case_id OCP-17557
      | ["spec"]["storageClassName"]    | sc-1          | ["spec"]["storageClassName"]                 | sc-2          | # @case_id OCP-17559

  # @author piqin@redhat.com
  @admin
  Scenario Outline: PV and PVC with different specified VolumeMode should not be bound
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]   | pv-<%= project.name %> |
      | ["spec"]["volumeMode"] | <pv_volumeMode>        |
    Then the step should succeed
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/claim.json" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["volumeMode"]       | <pvc_volumeMode>        |
    Then the step should succeed
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available
    When I run the :describe client command with:
      | resource | pvc                     |
      | name     | pvc-<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | FailedBinding                   |
      | no persistent volumes available |

    Examples:
      | pv_volumeMode | pvc_volumeMode |
      | Block         | Filesystem     | # @case_id OCP-17551
      | Filesystem    | Block          | # @case_id OCP-17553

  # @author lxia@redhat.com
  # @case_id OCP-18282
  @admin
  @destructive
  Scenario: Volume is detached after restart node service
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | dynamic-pvc |
    Then the step should succeed
    And the "dynamic-pvc" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc |
      | ["metadata"]["name"]                                         | mypod       |
    Then the step should succeed
    And the pod named "mypod" becomes ready

    Given I save volume id from PV named "<%= pvc.volume_name %>" in the :vid clipboard
    And I use the "<%= pod.node_name %>" node
    And the node service is restarted on the host after scenario
    And the node service is stopped
    When I run the :delete client command with:
      | object_type       | pod   |
      | object_name_or_id | mypod |
    Then the step should succeed
    And the pod named "mypod" becomes terminating

    Given the node service is restarted
    And I wait for the resource "pod" named "mypod" to disappear
    When I run commands on the host:
      | mount \| grep "<%= cb.vid %>" |
    Then the step should fail

  # @author lxia@redhat.com
  # @case_id OCP-18527
  @admin
  @destructive
  Scenario: Volume could be successfully unmounted when Pod is force deleted during kubelet downtime
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | dynamic-pvc |
    Then the step should succeed
    And the "dynamic-pvc" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc |
      | ["metadata"]["name"]                                         | mypod       |
    Then the step should succeed
    And the pod named "mypod" becomes ready

    Given I save volume id from PV named "<%= pvc.volume_name %>" in the :vid clipboard
    And I use the "<%= pod.node_name %>" node
    And the node service is restarted on the host after scenario
    And the node service is stopped
    When I run the :delete client command with:
      | object_type       | pod   |
      | object_name_or_id | mypod |
      | force             | true  |
    Then the step should succeed
    And the pod named "mypod" becomes terminating

    Given the node service is restarted
    And I wait for the resource "pod" named "mypod" to disappear
    When I run commands on the host:
      | mount \| grep "<%= cb.vid %>" |
    Then the step should fail

  # @author lxia@redhat.com
  # @case_id OCP-18797
  @admin
  Scenario: Recreate pv when pv is in pv-protection state should fail
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And the "mysql" PVC becomes :bound

    When I run the :delete admin command with:
      | object_type       | pv                     |
      | object_name_or_id | <%= pvc.volume_name %> |
      | wait              | false                  |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"] | <%= pvc.volume_name %> |
    Then the step should fail
    And the output should contain:
      | AlreadyExists           |
      | object is being deleted |
