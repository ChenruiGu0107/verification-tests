Feature: Persistent Volume Claim binding policies
  # @author lxia@redhat.com
  # @case_id OCP-17734
  Scenario: Pod with overlapped mount points still works
    Given I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc1 |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc2 |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pod-overlap-path.yaml"
    When I run oc create over "pod-overlap-path.yaml" replacing paths:
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
    Given I obtain test data file "storage/nfs/auto/pv-template.json"
    When admin creates a PV from "pv-template.json" where:
      | ["metadata"]["name"]                      | pv-<%= project.name %> |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce          |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Recycle                |
    Then the step should succeed
    Given I obtain test data file "storage/nfs/auto/pvc-template.json"
    When I create a manual pvc from "pvc-template.json" replacing paths:
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
  @admin
  Scenario Outline: PVC should bound the PV with most appropriate access mode and size
    Given I have a project
    And evaluation of `%w{127Mi 128Mi 129Mi 255Mi 256Mi 257Mi}` is stored in the :pv_sizes clipboard
    And evaluation of `%w{1Mi   128Mi 130Mi 258Mi}` is stored in the :pvc_sizes clipboard

    Given I run the steps 6 times:
    """
    Given I obtain test data file "storage/nfs/auto/pv-template.json"
    When admin creates a PV from "pv-template.json" where:
      | ["metadata"]["name"]            | pv-<%= project.name %>-#{cb.i} |
      | ["spec"]["accessModes"][0]      | <access_mode>                  |
      | ["spec"]["capacity"]["storage"] | #{cb.pv_sizes[cb.i-1]}         |
      | ["spec"]["storageClassName"]    | sc-<%= project.name %>         |
    Then the step should succeed
    """
    Given I run the steps 4 times:
    """
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc-#{cb.i}             |
      | ["spec"]["accessModes"][0]                   | <access_mode>             |
      | ["spec"]["resources"]["requests"]["storage"] | #{cb.pvc_sizes[cb.i-1]}   |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>    |
    Then the step should succeed
    """

    Given the "mypvc-1" PVC becomes bound to the "pv-<%= project.name %>-1" PV
    Given the "mypvc-2" PVC becomes bound to the "pv-<%= project.name %>-2" PV
    Given the "mypvc-3" PVC becomes bound to the "pv-<%= project.name %>-4" PV
    Given the "mypvc-4" PVC becomes :pending
    Given the "pv-<%= project.name %>-3" PV status is :available
    Given the "pv-<%= project.name %>-5" PV status is :available
    Given the "pv-<%= project.name %>-6" PV status is :available

    Examples:
      | access_mode   |
      | ReadWriteOnce | # @case_id OCP-27724
      | ReadWriteMany | # @case_id OCP-27723
      | ReadOnlyMany  | # @case_id OCP-27722


  # @author lxia@redhat.com
  # @case_id OCP-10145
  # @bug_id 1337106
  @admin
  Scenario: Pre-bound PVC with invalid PV should have consistent status
    Given I have a project

    Given I obtain test data file "storage/nfs/auto/pv-template.json"
    When admin creates a PV from "pv-template.json" where:
      | ["metadata"]["name"]         | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pv-<%= project.name %>" PV status is :available
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                   |
      | ["spec"]["volumeName"]       | pv1-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "mypvc" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available

  # @author lxia@redhat.com
  # @case_id OCP-12680
  # @bug_id 1337106
  @admin
  Scenario: Pre-bound PV with invalid PVC should have consistent status
    Given I have a project

    Given I obtain test data file "storage/nfs/preboundpv-rwo.yaml"
    When admin creates a PV from "preboundpv-rwo.yaml" where:
      | ["metadata"]["name"]              | pv-<%= project.name %> |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>    |
      | ["spec"]["claimRef"]["name"]      | non-exist-pvc          |
      | ["spec"]["storageClassName"]      | sc-<%= project.name %> |
    Then the step should succeed
    And the "pv-<%= project.name %>" PV status is :available
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
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

    Given I obtain test data file "storage/nfs/nfs-retain-rox.json"
    When admin creates a PV from "nfs-retain-rox.json" where:
      | ["metadata"]["name"]              | pv-<%= project.name %>   |
    Then the step should succeed
    Given I obtain test data file "storage/nfs/claim-rox.json"
    When I create a manual pvc from "claim-rox.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV
    And the expression should be true> pvc.capacity == "5Gi"
    And the expression should be true> pvc.access_modes[0] == "ReadOnlyMany"

  # @author lxia@redhat.com
  # @case_id OCP-10187
  @admin
  Scenario: PV creation negative testing
    Given I obtain test data file "storage/nfs/nfs-default.json"
    When I run the :create admin command with:
      | f | nfs-default.json |
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

    And I wait up to 30 seconds for the steps to pass:
    """
    Given I use the "<%= pod.node_name %>" node
    When I run commands on the host:
      | mount |
    Then the output should not contain:
      | <%= pvc.volume_name %> |
    """


  # @author jhou@redhat.com
  @admin
  Scenario Outline: Volume should be successfully detached if pod is deleted via namespace deletion
    Given admin creates a project with a random schedulable node selector

    # Create storageclass
    Given I obtain test data file "storage/misc/storageClass.yaml"
    When admin creates a StorageClass in the node's zone from "storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %>      |
      | ["provisioner"]      | kubernetes.io/<provisioner> |
    Then the step should succeed

    # Create dynamic pvc
    Given I obtain test data file "storage/misc/pvc-storageClass.json"
    When I create a dynamic pvc from "pvc-storageClass.json" replacing paths:
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
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
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

  # @author lxia@redhat.com
  # @case_id OCP-16190
  # @bug_id 1496256
  Scenario: Deleted in use PVCs will not break the scheduler
    Given I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"] | nfsc |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    Given I obtain test data file "storage/nfs/auto/web-pod.json"
    When I run the :create client command with:
      | f | web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready
    And I ensure "nfsc" pvc is deleted
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]   | nfsc         |
      | ["spec"]["volumeName"] | noneexistone |
    Then the step should succeed
    And the "nfsc" PVC becomes :pending
    Given I switch to the second user
    And I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"] | nfsc |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound
    Given I obtain test data file "storage/nfs/auto/web-pod.json"
    When I run the :create client command with:
      | f | web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready

  # @author piqin@redhat.com
  # @case_id OCP-17550
  @admin
  Scenario: PV with Filesystem VolumeMode and PVC with unspecified VolumeMode should be bound successfully
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]   | pv-<%= project.name %> |
      | ["spec"]["volumeMode"] | Filesystem             |
    Then the step should succeed
    Given I obtain test data file "storage/iscsi/claim.json"
    And I create a manual pvc from "claim.json" replacing paths:
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
    Given I obtain test data file "storage/iscsi/claim.json"
    And I create a manual pvc from "claim.json" replacing paths:
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
    Given I obtain test data file "storage/iscsi/claim.json"
    And I create a manual pvc from "claim.json" replacing paths:
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
    Given I obtain test data file "storage/iscsi/claim.json"
    And I create a manual pvc from "claim.json" replacing paths:
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
  # @author wduan@redhat.com
  @admin
  Scenario Outline: PV and PVC with same VolumeMode, but with other invalid feild should not be bound
    Given I have a project
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]         | pv-<%= project.name %> |
      | ["spec"]["volumeMode"]       | Block                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
      | <pv_key>                     | <pv_value>             |
    Then the step should succeed
    Given I obtain test data file "storage/iscsi/claim.json"
    And I create a dynamic pvc from "claim.json" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["volumeMode"]       | Block                   |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
      | <pvc_key>                    | <pvc_value>             |
    Then the step should succeed
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available

    Examples:
      | pv_key                          | pv_value      | pvc_key                                      | pvc_value     |
      | ["spec"]["capacity"]["storage"] | 1Gi           | ["spec"]["resources"]["requests"]["storage"] | 5Gi           | # @case_id OCP-17561
      | ["spec"]["accessModes"][0]      | ReadWriteOnce | ["spec"]["accessModes"][0]                   | ReadWriteMany | # @case_id OCP-17557


  # @author piqin@redhat.com
  # @author wduan@redhat.com
  # @case_id OCP-17559
  @admin
  Scenario: PV and PVC with the same VolumeMode but different StorageClass could not be bound
    Given I have a project
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]         | pv-<%= project.name %>   |
      | ["spec"]["volumeMode"]       | Block                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>-1 |
    Then the step should succeed
    Given I obtain test data file "storage/iscsi/claim.json"
    And I create a dynamic pvc from "claim.json" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %>  |
      | ["spec"]["volumeMode"]       | Block                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>-2 |
    Then the step should succeed
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available


  # @author piqin@redhat.com
  # @author lxia@redhat.com
  @admin
  Scenario Outline: PV and PVC with different specified VolumeMode should not be bound
    Given I have a project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]         | pv-<%= project.name %> |
      | ["spec"]["volumeMode"]       | <pv_volumeMode>        |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    And I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["volumeMode"]       | <pvc_volumeMode>       |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    Given 30 seconds have passed
    And the "mypvc" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available

    Examples:
      | pv_volumeMode | pvc_volumeMode |
      | Block         | Filesystem     | # @case_id OCP-17551
      | Filesystem    | Block          | # @case_id OCP-17553

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
    Given I obtain test data file "storage/nfs/auto/pv-retain.json"
    When admin creates a PV from "pv-retain.json" where:
      | ["metadata"]["name"] | <%= pvc.volume_name %> |
    Then the step should fail
    And the output should contain:
      | AlreadyExists           |
      | object is being deleted |
