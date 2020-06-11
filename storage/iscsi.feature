Feature: ISCSI volume plugin testing
  # @author lxia@redhat.com
  # @case_id OCP-23400
  @admin
  Scenario: Check iSCSI dependencies on the node
    Given I store the schedulable nodes in the :nodes clipboard
    And I repeat the following steps for each :node in cb.nodes:
    """
    And I use the "#{cb.node.name}" node
    When I run commands on the host:
      | rpm -qa \| grep -i iscsi |
    Then the step should succeed
    And the output should contain "iscsi-initiator-utils"
    """


  # @author jhou@redhat.com
  # @case_id OCP-9706
  @admin
  @destructive
  Scenario: ISCSI use default 3260 if port not specified
    Given I have a iSCSI setup in the environment
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    Given I obtain test data file "storage/iscsi/pod-direct.json"
    When I run oc create over "pod-direct.json" replacing paths:
      | ["metadata"]["name"]                             | mypod                         |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>            |
      | ["spec"]["volumes"][0]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
    Then the step should succeed
    And the pod named "mypod" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-10143
  @admin
  @destructive
  Scenario: Multiple iSCSI LUNs with rw and ro mode should ensure the access behavior correctly
    Given I have a iSCSI setup in the environment
    And I have a project

    # Create RW PV/PVC for LUN 0
    Given I obtain test data file "storage/iscsi/pv-read-write.json"
    Given admin creates a PV from "pv-read-write.json" where:
      | ["metadata"]["name"]                      | iscsi-rw-<%= project.name %>  |
      | ["spec"]["iscsi"]["targetPortal"]         | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["iscsi"]["initiatorName"]        | iqn.2016-04.test.com:test.img |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                        |
    Given I obtain test data file "storage/iscsi/pvc-read-write.json"
    And I create a manual pvc from "pvc-read-write.json" replacing paths:
      | ["metadata"]["name"]   | iscsi-rw                     |
      | ["spec"]["volumeName"] | iscsi-rw-<%= project.name %> |
    Then the step should succeed
    And the "iscsi-rw" PVC becomes bound to the "iscsi-rw-<%= project.name %>" PV

    # Create RO PV/PVC for LUN 1
    Given I obtain test data file "storage/iscsi/pv-read-only.json"
    Given admin creates a PV from "pv-read-only.json" where:
      | ["metadata"]["name"]                      | iscsi-ro-<%= project.name %>  |
      | ["spec"]["iscsi"]["targetPortal"]         | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["iscsi"]["initiatorName"]        | iqn.2016-04.test.com:test.img |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                        |
    Given I obtain test data file "storage/iscsi/pvc-read-only.json"
    And I create a manual pvc from "pvc-read-only.json" replacing paths:
      | ["metadata"]["name"]   | iscsi-ro                     |
      | ["spec"]["volumeName"] | iscsi-ro-<%= project.name %> |
    Then the step should succeed
    And the "iscsi-ro" PVC becomes bound to the "iscsi-ro-<%= project.name %>" PV

    # Create the pod with 2 containers mounting RW and RO PVCs
    Given I obtain test data file "storage/iscsi/pod-two-luns.json"
    When I run oc create over "pod-two-luns.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | iscsi-rw |
      | ["spec"]["volumes"][1]["persistentVolumeClaim"]["claimName"] | iscsi-ro |
    Then the step should succeed
    And the pod named "iscsi2luns" becomes ready

    # Should successfully access RW container
    When I run the :exec client command with:
      | pod              | iscsi2luns    |
      | c                | iscsi-rw      |
      | oc_opts_end      |               |
      | exec_command     | touch         |
      | exec_command_arg | /mnt/iscsi/rw |
    Then the step should succeed
    When I run the :exec client command with:
      | pod              | iscsi2luns    |
      | c                | iscsi-rw      |
      | oc_opts_end      |               |
      | exec_command     | ls            |
      | exec_command_arg | /mnt/iscsi/rw |
    Then the step should succeed

    # Should failed to access RO container
     When I run the :exec client command with:
      | pod              | iscsi2luns    |
      | c                | iscsi-ro      |
      | oc_opts_end      |               |
      | exec_command     | touch         |
      | exec_command_arg | /mnt/iscsi/ro |
    Then the step should fail
    And the output should contain:
      | Read-only file system |

  # @author jhou@redhat.com
  # @case_id OCP-13214
  @admin
  @destructive
  Scenario: Mount/Unmount multiple iSCSI volumes over a single session
    Given I have a iSCSI setup in the environment
    And I have a project

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]               | pv1-<%= project.name %>       |
      | ["spec"]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | pvc1                    |
      | ["spec"]["volumeName"] | pv1-<%= project.name %> |
    Then the step should succeed
    And the "pvc1" PVC becomes bound to the "pv1-<%= project.name %>" PV

    # Create 2nd Pod using same session with a different LUN
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]               | pv2-<%= project.name %>       |
      | ["spec"]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
      | ["spec"]["iscsi"]["lun"]           | 1                             |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | pvc2                    |
      | ["spec"]["volumeName"] | pv2-<%= project.name %> |
    Then the step should succeed
    And the "pvc2" PVC becomes bound to the "pv2-<%= project.name %>" PV

    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod1 |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc1   |
    Then the step should succeed
    And the pod named "mypod1" becomes ready

    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod2 |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc2   |
    Then the step should succeed
    And the pod named "mypod2" becomes ready

    # Covering BZ#1419607
    # Delete one of the Pods, the remaining one is still Running
    Given I ensure "mypod1" pod is deleted
    When I get project pod named "mypod2"
    Then the step should succeed
    And the output should contain:
      | Running |

  # @author piqin@redhat.com
  # @case_id OCP-13100
  @admin
  @destructive
  Scenario: Multipath support for iscsi volume plugin
    Given I have a iSCSI setup in the environment
    Given I create a second iSCSI path
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    Given I obtain test data file "storage/iscsi/pod-direct.json"
    When I run oc create over "pod-direct.json" replacing paths:
      | ["metadata"]["name"]                             | mypod                                                  |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip_2 %>:3260                              |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]       | ["<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"] |
      | ["spec"]["volumes"][0]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img                          |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    When I execute on the pod:
      | cp | /hello | /mnt/iscsi |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/iscsi/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

    Given I use the "<%= pod.node_name %>" node
    And I run commands on the host:
      | mount \| grep iscsi |
    Then the step should succeed
    #And the output should contain "/dev/mapper/mpath"

    When I disable the second iSCSI path
    Then the step should succeed
    When I execute on the pod:
      | /mnt/iscsi/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"
    When I execute on the pod:
      | touch | /mnt/iscsi/testfile |
    Then the step should succeed


  # @author wduan@redhat.com
  # @case_id OCP-27014
  @admin
  @destructive
  Scenario: Two pod reference the same iscsi volume with different readonly option
    Given I have a iSCSI setup in the environment
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    Given I obtain test data file "storage/iscsi/pod-direct.json"
    When I run oc create over "pod-direct.json" replacing paths:
      | ["metadata"]["name"]                             | mypod1                        |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]       | ["<%= cb.iscsi_ip%>:3260"]    |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]      | true                          |
      | ["spec"]["volumes"][0]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
    Then the step should succeed
    And the pod named "mypod1" becomes ready

    Given I obtain test data file "storage/iscsi/pod-direct.json"
    When I run oc create over "pod-direct.json" replacing paths:
      | ["metadata"]["name"]                             | mypod2                        |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]       | ["<%= cb.iscsi_ip%>:3260"]    |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]      | false                         |
      | ["spec"]["volumes"][0]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
    Then the step should succeed
    And the pod named "mypod2" becomes ready

    When I execute on the "mypod1" pod:
      | grep | iscsi | /proc/mounts |
    Then the output should contain:
      | ro |
    When I execute on the "mypod1" pod:
      | touch | /mnt/iscsi/testfile-ro |
    Then the step should fail
    And the output should contain:
      | Read-only file system |

    When I execute on the "mypod2" pod:
      | grep | iscsi | /proc/mounts |
    Then the output should contain:
      | rw |
    When I execute on the "mypod2" pod:
      | touch | /mnt/iscsi/testfile-rw |
    Then the step should succeed


  # @author piqin@redhat.com
  # @case_id OCP-13394
  @admin
  @destructive
  Scenario: Two Pod reference the same iscsi volume (ROX)
    Given I have a iSCSI setup in the environment
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    Given I obtain test data file "storage/iscsi/pod-direct.json"
    When I run oc create over "pod-direct.json" replacing paths:
      | ["metadata"]["name"]                             | mypod1                        |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]       | ["<%= cb.iscsi_ip%>:3260"]    |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]      | true                          |
      | ["spec"]["volumes"][0]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
    Then the step should succeed
    And the pod named "mypod1" becomes ready

    Given I obtain test data file "storage/iscsi/pod-direct.json"
    When I run oc create over "pod-direct.json" replacing paths:
      | ["metadata"]["name"]                             | mypod2                        |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]       | ["<%= cb.iscsi_ip%>:3260"]    |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]      | true                          |
      | ["spec"]["volumes"][0]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
    Then the step should succeed
    And the pod named "mypod2" becomes ready

    When I execute on the "mypod1" pod:
      | df | -T | /mnt/iscsi |
    Then the output should contain:
      | ext4 |
    When I execute on the "mypod2" pod:
      | df | -T | /mnt/iscsi |
    Then the output should contain:
      | ext4 |

  # @author jhou@redhat.com
  # @case_id OCP-17467
  @admin
  @destructive
  Scenario: Namespaced iscsi chap secrets
    Given I have a iSCSI setup in the environment

    # Create a namespace to store the secret
    Given I have a project
    And evaluation of `project.name` is stored in the :prj clipboard
    Given I obtain test data file "storage/iscsi/chap-secret-auto.yml"
    When I run the :create client command with:
      | filename  | chap-secret-auto.yml |
    Then the step should succeed

    Given I create a new project
    Given I obtain test data file "storage/iscsi/pv-chap.json"
    When admin creates a PV from "pv-chap.json" where:
      | ["metadata"]["name"]                        | pv-<%= project.name %>        |
      | ["spec"]["iscsi"]["targetPortal"]           | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["iscsi"]["secretRef"]["name"]      | chap-secret                   |
      | ["spec"]["iscsi"]["secretRef"]["namespace"] | <%= cb.prj %>                 |
      | ["spec"]["iscsi"]["initiatorName"]          | iqn.2016-04.test.com:test.img |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | mypvc                  |
      | ["spec"]["volumeName"] | pv-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

    # Create tester pod
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
    Then the step should succeed
    And the pod named "mypod" becomes ready


  # @author jhou@redhat.com
  # @case_id OCP-19110
  @admin
  Scenario: iSCSI block volumeMode support
    Given I have a iSCSI setup in the environment
    Given I have a project
    And admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]               | pv-<%= project.name %>        |
      | ["spec"]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
      | ["spec"]["volumeMode"]             | Block                         |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | mypvc                  |
      | ["spec"]["volumeName"] | pv-<%= project.name %> |
      | ["spec"]["volumeMode"] | Block                  |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

    # Create tester pod
    Given I obtain test data file "storage/misc/pod-with-block-volume.yaml"
    When I run oc create over "pod-with-block-volume.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod      |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc      |
      | ["spec"]["containers"][0]["volumeDevices"][0]["devicePath"]  | /dev/dpath |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    When I execute on the pod:
      | ls | /dev/dpath |
    Then the step should succeed

  # testcase for bug: #1583058
  # @author piqin@redhat.com
  # @author wduan@redhat.com
  # @case_id OCP-19150
  @admin
  Scenario: iSCSI ReadOnly block volume should not be written in Pod
    Given I have a iSCSI setup in the environment
    Given I have a project
    And admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]               | pv-<%= project.name %>        |
      | ["spec"]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
      | ["spec"]["volumeMode"]             | Block                         |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | mypvc                  |
      | ["spec"]["volumeName"] | pv-<%= project.name %> |
      | ["spec"]["volumeMode"] | Block                  |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

    # Create tester pod
    Given I obtain test data file "storage/misc/pod-with-block-volume.yaml"
    When I run oc create over "pod-with-block-volume.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod      |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc      |
      | ["spec"]["containers"][0]["volumeDevices"][0]["devicePath"]  | /dev/dpath |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["readOnly"]  | true       |
    Then the step should succeed
    And the pod named "mypod" becomes ready

    When I execute on the pod:
      | ls | /dev/dpath |
    Then the step should succeed

    When I execute on the pod:
      | /bin/dd | if=/dev/zero | of=/dev/dpath | bs=1M | count=10 |
    Then the step should fail
    And the output should match:
      | (Permission denied\|Operation not permitted) |
