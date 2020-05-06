Feature: NFS Persistent Volume

  # @author lxia@redhat.com
  # @case_id OCP-12671
  @admin
  Scenario: NFS volume failed to mount returns more verbose message
    # Preparations
    Given I have a project
    And I have a NFS service in the project

    # Creating PV and PVC
    Given admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]       | <%= service("nfs-service").ip %> |
      | ["spec"]["nfs"]["path"]         | /non-exist-path                  |
      | ["spec"]["capacity"]["storage"] | 5Gi                              |
      | ["spec"]["accessModes"][0]      | ReadWriteMany                    |
      | ["metadata"]["name"]            | nfs-<%= project.name %>          |
      | ["spec"]["storageClassName"]    | sc-<%= project.name %>           |
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]                         | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | nfs-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 5Gi                      |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany            |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>   |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    When I get project pod named "mypod-<%= project.name %>"
    Then the output should not contain:
      | Running |
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod                       |
      | name     | mypod-<%= project.name %> |
    Then the output should match:
      | (Unable to mount volumes for pod\|FailedMount) |
    """

  # @author lxia@redhat.com
  @admin
  Scenario Outline: NFS volume plugin with access mode and reclaim policy
    # Preparations
    Given I have a project
    And I have a NFS service in the project
    When I execute on the pod:
      | chmod | g+w | /mnt/data |
    Then the step should succeed

    # Creating PV and PVC
    Given admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0]                | <access_mode>                    |
      | ["spec"]["capacity"]["storage"]           | 5Gi                              |
      | ["spec"]["storageClassName"]              | sc-<%= project.name %>           |
      | ["spec"]["persistentVolumeReclaimPolicy"] | <reclaim_policy>                 |
      | ["metadata"]["name"]                      | nfs-<%= project.name %>          |
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc                   |
      | ["spec"]["volumeName"]                       | nfs-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 5Gi                     |
      | ["spec"]["accessModes"][0]                   | <access_mode>           |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
      | ["metadata"]["name"]                                         | mypod |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/ |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | id |
    Then the step should succeed
    When I execute on the pod:
      | ls | -ld | /mnt/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/test_file |
    Then the step should succeed
    And the output should not contain "Permission denied"
    When I execute on the pod:
      | cp | /hello | /mnt |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

    Given I ensure "mypod" pod is deleted
    And I ensure "mypvc" pvc is deleted
    And the PV becomes :<pv_status> within 300 seconds
    When I execute on the "nfs-server" pod:
      | ls | /mnt/data/test_file |
    Then the step should <step_status>

    Examples:
      | access_mode   | reclaim_policy | pv_status | step_status |
      | ReadOnlyMany  | Retain         | released  | succeed     | # @case_id OCP-12656
      | ReadWriteMany | Default        | released  | succeed     | # @case_id OCP-12657
      | ReadWriteOnce | Recycle        | available | fail        | # @case_id OCP-12653

  # @author jhou@redhat.com
  # @case_id OCP-11128
  @admin
  @destructive
  Scenario: Retain NFS Persistent Volume on release
    Given I have a project
    And I have a NFS service in the project

    And admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |

    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound

    # Create tester pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/web-pod.json |
    Then the step should succeed

    Given the pod named "nfs" becomes ready
    And I execute on the "nfs" pod:
      | touch | /mnt/created_testfile |
    Then the step should succeed

    # Delete pod and PVC to release the PV
    Given I ensure "nfs" pod is deleted
    And I ensure "nfsc" pvc is deleted
    And the PV becomes :released

    # After PV is released, verify the created file in nfs export is reserved.
    When I execute on the "nfs-server" pod:
      | ls | /mnt/data/ |
    Then the output should contain:
      | created_testfile |
    And the PV status is :released

  # @author wehe@redhat.com
  # @case_id OCP-11491
  @admin
  @destructive
  Scenario: The default reclamation policy should be retain
    Given I have a project
    And I have a NFS service in the project

    And admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto-nfs-default-rwx.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound

    # Create tester pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/web-pod.json |
    Then the step should succeed

    Given the pod named "nfs" becomes ready
    And I execute on the "nfs" pod:
      | touch | /mnt/created_testfile |
    Then the step should succeed

    # Delete pod and PVC to release the PV
    Given I ensure "nfs" pod is deleted
    And I ensure "nfsc" pvc is deleted

    # After PV is released, verify the created file in nfs export is reserved.
    When I execute on the "nfs-server" pod:
      | ls | /mnt/data/ |
    Then the output should contain:
      | created_testfile |
    And the PV status is :released

  # @author lxia@redhat.com
  # @case_id OCP-9846
  @admin
  Scenario: PV/PVC status should be consistent
    Given I have a project
    And I have a NFS service in the project

    Given admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto-nfs-recycle-rwo.json" where:
      | ["spec"]["nfs"]["server"]     | <%= service("nfs-service").ip %> |
      | ["metadata"]["name"]          | pv-<%= project.name %>           |
      | ["spec"]["storageClassName"]  | sc-<%= project.name %>           |
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["volumeName"]       | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

    Given I ensure "mypvc" pvc is deleted
    And the PV becomes :available within 60 seconds

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["volumeName"]       | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound within 900 seconds
    And the PV becomes :bound

  # @author lxia@redhat.com
  # @case_id OCP-12672
  @admin
  Scenario: User permission to write to nfs
    Given I have a project
    And I have a NFS service in the project

    # make NFS only accessible to user 1000100001
    When I execute on the pod:
      | chown | -R | 1000100001:root | /mnt/data |
    Then the step should succeed
    When I execute on the pod:
      | chmod | -R | 700 | /mnt/data |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/cases/510532/pod.json" replacing paths:
      | ["metadata"]["name"]                                 | pod1                             |
      | ["spec"]["securityContext"]["runAsUser"]             | 1000100001                       |
      | ["spec"]["securityContext"]["supplementalGroups"][0] | 1000100666                       |
      | ["spec"]["volumes"][0]["nfs"]["server"]              | <%= service("nfs-service").ip %> |
      | ["spec"]["volumes"][0]["nfs"]["path"]                | /                                |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/cases/510532/pod.json" replacing paths:
      | ["metadata"]["name"]                                 | pod2                             |
      | ["spec"]["securityContext"]["runAsUser"]             | 1000100002                       |
      | ["spec"]["securityContext"]["supplementalGroups"][0] | 1000100666                       |
      | ["spec"]["volumes"][0]["nfs"]["server"]              | <%= service("nfs-service").ip %> |
      | ["spec"]["volumes"][0]["nfs"]["path"]                | /                                |
    Then the step should succeed

    Given 2 pods become ready with labels:
      | name=frontendhttp |

    When I execute on the "pod1" pod:
      | id |
    Then the output should contain:
      | 1000100001 |
    When I execute on the "pod1" pod:
      | ls | -ld | /mnt/nfs |
    Then the output should contain:
      | drwx------ |
    When I execute on the "pod1" pod:
      | cp | /proc/cpuinfo | /mnt/nfs/from-pod1 |
    Then the step should succeed

    When I execute on the "pod2" pod:
      | id |
    Then the output should contain:
      | 1000100002 |
    When I execute on the "pod2" pod:
      | ls | -ld | /mnt/nfs |
    Then the output should contain:
      | drwx------ |
    When I execute on the "pod2" pod:
      | cp | /proc/cpuinfo | /mnt/nfs/from-pod2 |
    Then the step should fail

    When I execute on the "nfs-server" pod:
      | ls | /mnt/data |
    Then the output should not contain:
      | from-pod2 |
    And the output should contain:
      | from-pod1 |

  # @author lxia@redhat.com
  # @case_id OCP-12673
  @admin
  Scenario: group permission to write to nfs
    Given I have a project
    And I have a NFS service in the project

    # make NFS only accessible to group 1000100011
    When I execute on the pod:
      | chown | -R | root:1000100011 | /mnt/data |
    Then the step should succeed
    When I execute on the pod:
      | chmod | -R | 070 | /mnt/data |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/cases/510690/pod.json" replacing paths:
      | ["metadata"]["name"]                                 | pod1                             |
      | ["spec"]["securityContext"]["runAsUser"]             | 1000100005                       |
      | ["spec"]["securityContext"]["supplementalGroups"][0] | 1000100011                       |
      | ["spec"]["volumes"][0]["nfs"]["server"]              | <%= service("nfs-service").ip %> |
      | ["spec"]["volumes"][0]["nfs"]["path"]                | /                                |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/cases/510532/pod.json" replacing paths:
      | ["metadata"]["name"]                                 | pod2                             |
      | ["spec"]["securityContext"]["runAsUser"]             | 1000100005                       |
      | ["spec"]["securityContext"]["supplementalGroups"][0] | 1000100022                       |
      | ["spec"]["volumes"][0]["nfs"]["server"]              | <%= service("nfs-service").ip %> |
      | ["spec"]["volumes"][0]["nfs"]["path"]                | /                                |
    Then the step should succeed

    Given 2 pods become ready with labels:
      | name=frontendhttp |

    When I execute on the "pod1" pod:
      | id |
    Then the output should contain:
      | 1000100011 |
    When I execute on the "pod1" pod:
      | ls | -ld | /mnt/nfs |
    Then the output should contain:
      | d---rwx--- |
    When I execute on the "pod1" pod:
      | cp | /proc/cpuinfo | /mnt/nfs/from-pod1 |
    Then the step should succeed

    When I execute on the "pod2" pod:
      | id |
    Then the output should contain:
      | 1000100022 |
    When I execute on the "pod2" pod:
      | ls | -ld | /mnt/nfs |
    Then the output should contain:
      | d---rwx--- |
    When I execute on the "pod2" pod:
      | cp | /proc/cpuinfo | /mnt/nfs/from-pod1 |
    Then the step should fail

    When I execute on the "nfs-server" pod:
      | ls | /mnt/data |
    Then the output should not contain:
      | from-pod2 |
    And the output should contain:
      | from-pod1 |

  # @author wehe@redhat.com
  # @case_id OCP-10146
  @admin
  @destructive
  Scenario: New pod could be running after nfs server lost connection
    Given I have a project
    And I have a NFS service in the project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/image/db-templates/auto-nfs-pv.json" where:
      | ["metadata"]["name"]       | pv-nfs-<%= project.name %>       |
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And the "mysql" PVC becomes bound to the "pv-nfs-<%= project.name %>" PV
    Given a pod becomes ready with labels:
      | app=mysql-persistent |
    And I ensure "nfs-server" pod is deleted
    And I ensure "nfs-service" service is deleted
    And I ensure "mysql" dc is deleted
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" status becomes :running
    Given all existing pods die with labels:
      | app=mysql-persistent |

  # @author wehe@redhat.com
  # @case_id OCP-12880
  @admin
  Scenario: External provisioner of NFS dynamic provisioning testing
    Given I have a project
    And I have a nfs-provisioner pod in the project
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/nfs-provisioner/nfsdyn-pvc.yaml" replacing paths:
      | ["spec"]["storageClassName"] | nfs-provisioner-<%= project.name %> |
    Then the step should succeed
    Given the "nfsdynpvc" PVC becomes :bound within 120 seconds
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/nfs-provisioner/nfsdyn-pod.yaml |
    Then the step should succeed
    Given the pod named "nfsdynpod" becomes ready
    When I execute on the pod:
      | touch | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    Given I ensure "nfsdynpod" pod is deleted
    And I ensure "nfsdynpvc" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

  # @author wehe@redhat.com
  # @case_id OCP-12878
  @admin
  Scenario: Two NFS provisioner competing for provisioning test
    Given I have a project
    And I have a nfs-provisioner pod in the project
    Then the step should succeed
    # Create another provisioner pod
    When I run oc create over "https://raw.githubusercontent.com/kubernetes-incubator/nfs-provisioner/master/deploy/kube-config/pod-sa.yaml" replacing paths:
      | ["metadata"]["name"] | nfs-provisioner-<%= project.name %> |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/nfs-provisioner/nfsdyn-pvc.yaml" replacing paths:
      | ["spec"]["storageClassName"] | nfs-provisioner-<%= project.name %> |
    Then the step should succeed
    Given the "nfsdynpvc" PVC becomes :bound within 120 seconds
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/nfs-provisioner/nfsdyn-pod.yaml |
    Then the step should succeed
    Given the pod named "nfsdynpod" becomes ready
    When I execute on the pod:
      | touch | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    Given I ensure "nfsdynpod" pod is deleted
    And I ensure "nfsdynpvc" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

  # @author wehe@redhat.com
  # @case_id OCP-12903
  @admin
  Scenario: NFS provisioner reclaim a provisioned volume
    Given I have a project
    And I have a nfs-provisioner pod in the project
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/nfs-provisioner/nfsdyn-pvc.yaml" replacing paths:
      | ["spec"]["storageClassName"] | nfs-provisioner-<%= project.name %> |
    Then the step should succeed
    Given the "nfsdynpvc" PVC becomes :bound within 120 seconds
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Delete"
    Given I run the :delete client command with:
      | object_type       | pvc       |
      | object_name_or_id | nfsdynpvc |
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 60 seconds

  # @author wehe@redhat.com
  # @case_id OCP-13708
  @admin
  Scenario: NFS provisioner's provision volume should have correct capacity
    Given I have a project
    And I have a nfs-provisioner pod in the project
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/nfs-provisioner/nfsdyn-pvc.yaml" replacing paths:
      | ["spec"]["storageClassName"] | nfs-provisioner-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"]                           | 6Gi                                 |
    Then the step should succeed
    Given the "nfsdynpvc" PVC becomes :bound within 120 seconds
    And admin ensures "<%= pvc('nfsdynpvc').volume_name %>" pv is deleted after scenario
    And the expression should be true> pvc.capacity == "6Gi"

  # @author wehe@redhat.com
  # @case_id OCP-12891
  @admin
  Scenario: NFS dynamic provisioner with deployment testing
    Given I have a project
    And I have a nfs-provisioner service in the project
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/nfs-provisioner/nfsdyn-pvc.yaml" replacing paths:
      | ["spec"]["storageClassName"] | nfs-provisioner-<%= project.name %> |
    Then the step should succeed
    Given the "nfsdynpvc" PVC becomes :bound within 120 seconds
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/nfs-provisioner/nfsdyn-pod.yaml |
    Then the step should succeed
    Given the pod named "nfsdynpod" becomes ready
    When I execute on the pod:
      | touch | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    Given I ensure "nfsdynpod" pod is deleted
    And I ensure "nfsdynpvc" pvc is deleted
    When I run the :delete client command with:
      | object_type       | deployment      |
      | object_name_or_id | nfs-provisioner |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | service         |
      | object_name_or_id | nfs-provisioner |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

  # @author wehe@redhat.com
  # @case_id OCP-12899
  @admin
  Scenario: NFS dynamic provisioner lost and recovering test
    Given I have a project
    And I have a nfs-provisioner service in the project
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/nfs-provisioner/nfsdyn-pvc.yaml" replacing paths:
      | ["spec"]["storageClassName"] | nfs-provisioner-<%= project.name %> |
    Then the step should succeed
    Given the "nfsdynpvc" PVC becomes :bound within 120 seconds
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/nfs-provisioner/nfsdyn-pod.yaml |
    Then the step should succeed
    Given the pod named "nfsdynpod" becomes ready
    When I execute on the pod:
      | touch | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    Given I run the :scale client command with:
      | resource | deployment      |
      | name     | nfs-provisioner |
      | replicas | 0               |
    And all existing pods die with labels:
      | app=nfs-provisioner |
    When I execute on the pod:
      | ls | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed
    Given I run the :scale client command with:
      | resource | deployment      |
      | name     | nfs-provisioner |
      | replicas | 1               |
    When I execute on the pod:
      | ls | /mnt/nfs/nfs-<%= project.name %> |
    Then the step should succeed

  # @author jhou@redhat.com
  # @case_id OCP-13912
  @admin
  Scenario: Setting NFS read-only mount option in PV's annotation
    Given I have a project
    And I have a NFS service in the project

    # Set read-only mount option
    Given admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/pv-mount-option.yaml" where:
      | ["spec"]["nfs"]["server"]                                              | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce                    |
      | ["spec"]["capacity"]["storage"]                                        | 1Gi                              |
      | ["metadata"]["name"]                                                   | nfs-<%= project.name %>          |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/mount-options"] | ro,nfsvers=4                     |
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]                         | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | nfs-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                      |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce            |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["containers"][0]["image"]                           | aosqe/hello-openshift     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | ls | /mnt |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/test_file |
    Then the step should fail
    And the output should contain:
      | Read-only file system |
    When I execute on the pod:
      | mount |
    Then the output should contain:
      | ro     |
      | vers=4 |

  # @author jhou@redhat.com
  # @case_id OCP-14282
  @admin
  Scenario: Setting NFS noexec mount option in PV annotation
    Given I have a project
    And I have a NFS service in the project

    # Set read-only mount option
    Given admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/pv-mount-option.yaml" where:
      | ["spec"]["nfs"]["server"]                                              | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce                    |
      | ["spec"]["capacity"]["storage"]                                        | 1Gi                              |
      | ["metadata"]["name"]                                                   | nfs-<%= project.name %>          |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/mount-options"] | rw,nfsvers=4,noexec              |
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]                         | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | nfs-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                      |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce            |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["containers"][0]["image"]                           | aosqe/hello-openshift     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | cp | /hello | /mnt/hello |
    Then the step should succeed
    When I execute on the pod:
      | mount |
    Then the output should contain:
      | noexec |
      | vers=4 |
    When I execute on the pod:
      | /mnt/hello |
    Then the step should fail
    And the output should contain:
      | ermission denied |

  # @author jhou@redhat.com
  # @case_id OCP-14280
  @admin
  Scenario: Setting NFS mount options in PV annotation
    Given I have a project
    And I have a NFS service in the project

    # Set read-only mount option
    Given admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/pv-mount-option.yaml" where:
      | ["spec"]["nfs"]["server"]                                              | <%= service("nfs-service").ip %>     |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce                        |
      | ["spec"]["capacity"]["storage"]                                        | 1Gi                                  |
      | ["metadata"]["name"]                                                   | nfs-<%= project.name %>              |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/mount-options"] | nfsvers=4.1,hard,timeo=600,retrans=2 |
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]                         | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | nfs-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                      |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce            |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["containers"][0]["image"]                           | aosqe/hello-openshift     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | mount |
    Then the output should contain:
      | vers=4.1  |
      | retrans=2 |
      | hard      |
      | timeo=600 |

  # @author wehe@redhat.com
  # @case_id OCP-17279
  @admin
  @destructive
  Scenario: Configure 'Retain' reclaim policy for nfs
    Given I have a project
    And I have a nfs-provisioner pod in the project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/class.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["reclaimPolicy"]    | Retain                 |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And admin ensures "<%= pv(pvc.volume_name).name %>" pv is deleted after scenario
    And the expression should be true> pv.reclaim_policy == "Retain"

    When I ensure "<%= pvc.name %>" pvc is deleted
    Given I run the :get admin command with:
      | resource      | pv             |
      | resource_name | <%= pv.name %> |
    Then the output should contain:
      | Released |

  # @author lxia@redhat.com
  # @case_id OCP-12221
  @admin
  Scenario: Volume should re-attached with correct mode when pod is re-created with different read-write mode
    Given I have a project
    And I have a NFS service in the project

    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/pv-mount-option.yaml" where:
      | ["spec"]["nfs"]["server"]                                              | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0]                                             | ReadOnlyMany                     |
      | ["spec"]["capacity"]["storage"]                                        | 5Gi                              |
      | ["metadata"]["name"]                                                   | ro-<%= project.name %>           |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/mount-options"] | ro,nfsvers=4                     |
    Then the step should succeed
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | ro-<%= project.name %> |
      | ["spec"]["volumeName"]     | ro-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadOnlyMany           |
    Then the step should succeed
    And the "ro-<%= project.name %>" PVC becomes bound to the "ro-<%= project.name %>" PV
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | podname                |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | ro-<%= project.name %> |
    Then the step should succeed
    Given the pod named "podname" becomes ready

    When I execute on the pod:
      | grep | <%= service("nfs-service").ip %> | /proc/mounts |
    Then the step should succeed
    And the output should contain "ro"

    Given I ensure "podname" pod is deleted
    And I ensure "ro-<%= project.name %>" pvc is deleted

    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]       | rw-<%= project.name %>           |
      | ["spec"]["accessModes"][0] | ReadWriteOnce                    |
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
    Then the step should succeed
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | rw-<%= project.name %> |
      | ["spec"]["volumeName"]     | rw-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce          |
    Then the step should succeed
    And the "rw-<%= project.name %>" PVC becomes bound to the "rw-<%= project.name %>" PV
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | podname                |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | rw-<%= project.name %> |
    Then the step should succeed
    Given the pod named "podname" becomes ready

    When I execute on the pod:
      | grep | <%= service("nfs-service").ip %> | /proc/mounts |
    Then the step should succeed
    And the output should contain "rw"

  # @author wehe@redhat.com
  # @case_id OCP-17750
  @admin
  Scenario: Using mountOptions for NFS StorageClass
    Given I have a project
    And I have a nfs-provisioner pod in the project
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-mountOptions.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | example.com/nfs        |
      | ["mountOptions"][0]  | ro                     |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And admin ensures "<%= pv(pvc.volume_name).name %>" pv is deleted after scenario
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | grep | ocp_pv | /proc/self/mountinfo |
    Then the step should succeed
    And the output should contain:
      | ro |
    Given I ensure "pod-<%= project.name %>" pod is deleted
    And I ensure "pvc-<%= project.name %>" pvc is deleted
