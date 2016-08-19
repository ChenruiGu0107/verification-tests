Feature: NFS Persistent Volume

  # @author lxia@redhat.com
  # @case_id 510432
  @admin
  @destructive
  Scenario: NFS volume failed to mount returns more verbose message
    # Preparations
    Given I have a project
    And I have a NFS service in the project

    # Creating PV and PVC
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
      | ["spec"]["nfs"]["path"]    | /non-exist-path                  |
      | ["spec"]["accessModes"][0] | ReadWriteMany                    |
      | ["metadata"]["name"]       | nfs-<%= project.name %>          |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]     | nfs-<%= project.name %>  |
      | ["spec"]["accessModes"][0] | ReadWriteMany            |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    When I get project pod named "mypod-<%= project.name %>"
    Then the output should not contain:
      | Running |
    And I wait up to 300 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod                       |
      | name     | mypod-<%= project.name %> |
    Then the output should contain:
      | Unable to mount volumes for pod |
    """

  # @author lxia@redhat.com
  # @case_id 508049 508050 508051
  @admin
  @destructive
  Scenario Outline: NFS volume plugin with access mode and reclaim policy
    # Preparations
    Given I have a project
    And I have a NFS service in the project
    When I execute on the pod:
      | chmod | g+w | /mnt/data |
    Then the step should succeed

    # Creating PV and PVC
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0]                | <access_mode>                    |
      | ["spec"]["persistentVolumeReclaimPolicy"] | <reclaim_policy>                 |
      | ["metadata"]["name"]                      | nfs-<%= project.name %>          |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]     | nfs-<%= project.name %>  |
      | ["spec"]["accessModes"][0] | <access_mode>            |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
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

    Given I ensure "mypod-<%= project.name %>" pod is deleted
    And I ensure "nfsc-<%= project.name %>" pvc is deleted
    And the PV becomes :<pv_status> within 300 seconds
    When I execute on the "nfs-server" pod:
      | ls | /mnt/data/test_file |
    Then the step should <step_status>

    Examples:
      | access_mode   | reclaim_policy | pv_status | step_status |
      | ReadOnlyMany  | Retain         | released  | succeed     |
      | ReadWriteMany | Default        | released  | succeed     |
      | ReadWriteOnce | Recycle        | available | fail        |

  # @author jhou@redhat.com
  # @case_id 488980
  @admin
  @destructive
  Scenario: Retain NFS Persistent Volume on release
    Given I have a project
    And I have a NFS service in the project

    And admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound

    # Create tester pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
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
  # @case_id 488981
  @admin
  @destructive
  Scenario: The default reclamation policy should be retain
    Given I have a project
    And I have a NFS service in the project

    And admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto-nfs-default-rwx.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound

    # Create tester pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
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
  # @case_id 519352
  @admin
  @destructive
  Scenario: PV/PVC status should be consistent
    Given I have a project
    And I have a NFS service in the project

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"] | nfs-<%= project.name %>  |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    Given I ensure "nfsc-<%= project.name %>" pvc is deleted
    When I run the :get admin command with:
      | resource | pv/nfs-<%= project.name %> |
    Then the output should not contain:
      | Bound |

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"] | nfs-<%= project.name %>  |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes :bound within 900 seconds
    And the PV becomes :bound

  # @author jhou@redhat.com
  # @case_id 497695
  @admin
  @destructive
  Scenario: Share NFS with multiple pods with ReadWriteMany mode
    Given I have a project
    And I have a NFS service in the project

    # Preparations
    And admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
    And I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-rwx.json" replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    And the PV becomes :bound

    # Create a replication controller
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/rc.yml |
    Then the step should succeed

    # The replication controller creates 2 pods
    Given 2 pods become ready with labels:
      | name=hellopod |

    When I execute on the "<%= pod(-1).name %>" pod:
      | touch | /mnt/nfs/testfile_1 |
    Then the step should succeed

    When I execute on the "<%= pod(-2).name %>" pod:
      | touch | /mnt/nfs/testfile_2 |
    Then the step should succeed

    # Finally verify both files created by each pod are under the same export dir in the nfs-server pod
    When I execute on the "nfs-server" pod:
      | ls | /mnt/data |
    Then the output should contain:
      | testfile_1 |
      | testfile_2 |

  # @author lxia@redhat.com
  # @case_id 510352
  @admin
  @destructive
  Scenario: [storage_private_155] User permission to write to nfs
    Given I have a project
    And I have a NFS service in the project

    # make NFS only accessible to user 1000100001
    When I execute on the pod:
      | chown | -R | 1000100001:root | /mnt/data |
    Then the step should succeed
    When I execute on the pod:
      | chmod | -R | 700 | /mnt/data |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/510532/pod.json" replacing paths:
      | ["metadata"]["name"]                                 | pod1-<%= project.name %>         |
      | ["spec"]["securityContext"]["runAsUser"]             | 1000100001                       |
      | ["spec"]["securityContext"]["supplementalGroups"][0] | 1000100666                       |
      | ["spec"]["volumes"][0]["nfs"]["server"]              | <%= service("nfs-service").ip %> |
      | ["spec"]["volumes"][0]["nfs"]["path"]                | /                                |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/510532/pod.json" replacing paths:
      | ["metadata"]["name"]                                 | pod2-<%= project.name %>         |
      | ["spec"]["securityContext"]["runAsUser"]             | 1000100002                       |
      | ["spec"]["securityContext"]["supplementalGroups"][0] | 1000100666                       |
      | ["spec"]["volumes"][0]["nfs"]["server"]              | <%= service("nfs-service").ip %> |
      | ["spec"]["volumes"][0]["nfs"]["path"]                | /                                |
    Then the step should succeed

    Given 2 pods become ready with labels:
      | name=frontendhttp |

    When I execute on the "pod1-<%= project.name %>" pod:
      | id |
    Then the output should contain:
      | 1000100001 |
    When I execute on the "pod1-<%= project.name %>" pod:
      | ls | -ld | /mnt/nfs |
    Then the output should contain:
      | drwx------ |
    When I execute on the "pod1-<%= project.name %>" pod:
      | touch | /mnt/nfs/pod1 |
    Then the step should succeed

    When I execute on the "pod2-<%= project.name %>" pod:
      | id |
    Then the output should contain:
      | 1000100002 |
    When I execute on the "pod2-<%= project.name %>" pod:
      | ls | -ld | /mnt/nfs |
    Then the output should contain:
      | drwx------ |
    When I execute on the "pod2-<%= project.name %>" pod:
      | touch | /mnt/nfs/pod2 |
    Then the step should fail

    When I execute on the "nfs-server" pod:
      | ls | /mnt/data |
    Then the output should contain:
      | pod1 |
    And the output should not contain:
      | pod2 |

  # @author lxia@redhat.com
  # @case_id 510690
  @admin
  @destructive
  Scenario: [storage_private_155] group permission to write to nfs
    Given I have a project
    And I have a NFS service in the project

    # make NFS only accessible to group 1000100011
    When I execute on the pod:
      | chown | -R | root:1000100011 | /mnt/data |
    Then the step should succeed
    When I execute on the pod:
      | chmod | -R | 070 | /mnt/data |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/510690/pod.json" replacing paths:
      | ["metadata"]["name"]                                 | pod1-<%= project.name %>         |
      | ["spec"]["securityContext"]["runAsUser"]             | 1000100005                       |
      | ["spec"]["securityContext"]["supplementalGroups"][0] | 1000100011                       |
      | ["spec"]["volumes"][0]["nfs"]["server"]              | <%= service("nfs-service").ip %> |
      | ["spec"]["volumes"][0]["nfs"]["path"]                | /                                |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/510532/pod.json" replacing paths:
      | ["metadata"]["name"]                                 | pod2-<%= project.name %>         |
      | ["spec"]["securityContext"]["runAsUser"]             | 1000100005                       |
      | ["spec"]["securityContext"]["supplementalGroups"][0] | 1000100022                       |
      | ["spec"]["volumes"][0]["nfs"]["server"]              | <%= service("nfs-service").ip %> |
      | ["spec"]["volumes"][0]["nfs"]["path"]                | /                                |
    Then the step should succeed

    Given 2 pods become ready with labels:
      | name=frontendhttp |

    When I execute on the "pod1-<%= project.name %>" pod:
      | id |
    Then the output should contain:
      | 1000100011 |
    When I execute on the "pod1-<%= project.name %>" pod:
      | ls | -ld | /mnt/nfs |
    Then the output should contain:
      | d---rwx--- |
    When I execute on the "pod1-<%= project.name %>" pod:
      | touch | /mnt/nfs/pod1 |
    Then the step should succeed

    When I execute on the "pod2-<%= project.name %>" pod:
      | id |
    Then the output should contain:
      | 1000100022 |
    When I execute on the "pod2-<%= project.name %>" pod:
      | ls | -ld | /mnt/nfs |
    Then the output should contain:
      | d---rwx--- |
    When I execute on the "pod2-<%= project.name %>" pod:
      | touch | /mnt/nfs/pod2 |
    Then the step should fail

    When I execute on the "nfs-server" pod:
      | ls | /mnt/data |
    Then the output should contain:
      | pod1 |
    And the output should not contain:
      | pod2 |

  # @author lxia@redhat.com
  # @case_id 528441
  # @bug_id 1332707
  @admin
  @destructive
  Scenario: PVC shows LOST after pv deleted and can be bound again for new pv
    Given I have a project
    And I have a NFS service in the project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]       | pv-nfs-<%= project.name %>       |
      | ["spec"]["accessModes"][0] | ReadWriteMany                    |
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | pvc-nfs-<%= project.name %> |
      | ["spec"]["volumeName"]     | pv-nfs-<%= project.name %>  |
      | ["spec"]["accessModes"][0] | ReadWriteMany               |
    Then the step should succeed
    And the "pvc-nfs-<%= project.name %>" PVC becomes bound to the "pv-nfs-<%= project.name %>" PV
    Given admin ensures "pv-nfs-<%= project.name %>" pv is deleted
    And the "pvc-nfs-<%= project.name %>" PVC becomes :lost within 300 seconds
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["metadata"]["name"]       | pv-nfs-<%= project.name %>       |
      | ["spec"]["accessModes"][0] | ReadWriteMany                    |
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
    Then the step should succeed
    And the "pvc-nfs-<%= project.name %>" PVC becomes bound to the "pv-nfs-<%= project.name %>" PV
