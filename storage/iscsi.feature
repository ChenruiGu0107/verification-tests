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


  # @author wduan@redhat.com
  # @case_id OCP-27014
  @admin
  @destructive
  Scenario: Two pod reference the same iscsi volume with different readonly option
    Given I have a iSCSI setup in the environment
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    # Create the pod with not read-only volume first, so the filesystem can be created
    Given I obtain test data file "storage/iscsi/pod-direct.json"
    When I run oc create over "pod-direct.json" replacing paths:
      | ["metadata"]["name"]                             | mypod2                        |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]       | ["<%= cb.iscsi_ip%>:3260"]    |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]      | false                         |
      | ["spec"]["volumes"][0]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
    Then the step should succeed
    And the pod named "mypod2" becomes ready

    Given I obtain test data file "storage/iscsi/pod-direct.json"
    When I run oc create over "pod-direct.json" replacing paths:
      | ["metadata"]["name"]                             | mypod1                        |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]       | ["<%= cb.iscsi_ip%>:3260"]    |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]      | true                          |
      | ["spec"]["volumes"][0]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
    Then the step should succeed
    And the pod named "mypod1" becomes ready

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
