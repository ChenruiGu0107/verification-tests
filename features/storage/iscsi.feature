Feature: ISCSI volume plugin testing

  # @author jhou@redhat.com
  # @case_id OCP-9638
  @admin
  @destructive
  Scenario: ISCCI volume security test
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | iscsi-<%= project.name %>     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-iscsi-<%= project.name %> |
    Then the step should succeed
    And the pod named "iscsi-<%= project.name %>" becomes ready

    # Verify uid and gid are correct
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
    Then the output should contain:
      | 123456               |
      | svirt_sandbox_file_t |
      | s0:c2,c13            |

    # Verify created file belongs to supplemental group
    Given I execute on the "iscsi-<%= project.name %>" pod:
      | touch | /mnt/iscsi/iscsi_testfile |
    When I execute on the "iscsi-<%= project.name %>" pod:
      | ls | -l | /mnt/iscsi/iscsi_testfile |
    Then the output should contain:
      | 123456 |
    When I execute on the pod:
      | cp | /hello | /mnt/iscsi |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/iscsi/hello |
    Then the step should succeed

  # @author jhou@redhat.com
  # @case_id OCP-9706
  @admin
  @destructive
  Scenario: ISCSI use default 3260 if port not specified
    Given I have a iSCSI setup in the environment
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod-direct.json" replacing paths:
      | ["metadata"]["name"]                            | iscsi-<%= project.name %> |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip %>        |
    Then the step should succeed
    And the pod named "iscsi-<%= project.name %>" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-10143
  @admin
  @destructive
  Scenario: Multiple iSCSI LUNs with rw and ro mode should ensure the access behavior correctly
    Given I have a iSCSI setup in the environment
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    # Create RW PV/PVC for LUN 0
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/iscsi/pv-read-write.json" where:
      | ["metadata"]["name"]                      | iscsi-rw-<%= project.name %> |
      | ["spec"]["iscsi"]["targetPortal"]         | <%= cb.iscsi_ip %>:3260      |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                       |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/iscsi/pvc-read-write.json" replacing paths:
      | ["metadata"]["name"]   | iscsi-rw-<%= project.name %> |
      | ["spec"]["volumeName"] | iscsi-rw-<%= project.name %> |
    Then the step should succeed
    And the "iscsi-rw-<%= project.name %>" PVC becomes bound to the "iscsi-rw-<%= project.name %>" PV

    # Create RO PV/PVC for LUN 1
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/iscsi/pv-read-only.json" where:
      | ["metadata"]["name"]                      | iscsi-ro-<%= project.name %> |
      | ["spec"]["iscsi"]["targetPortal"]         | <%= cb.iscsi_ip %>:3260      |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                       |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/iscsi/pvc-read-only.json" replacing paths:
      | ["metadata"]["name"]   | iscsi-ro-<%= project.name %> |
      | ["spec"]["volumeName"] | iscsi-ro-<%= project.name %> |
    Then the step should succeed
    And the "iscsi-ro-<%= project.name %>" PVC becomes bound to the "iscsi-ro-<%= project.name %>" PV

    # Create the pod with 2 containers mounting RW and RO PVCs
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/iscsi/pod-two-luns.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | iscsi-rw-<%= project.name %>   |
      | ["spec"]["volumes"][1]["persistentVolumeClaim"]["claimName"] | iscsi-ro-<%= project.name %>   |
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
      | ["metadata"]["name"]              | pv-iscsi-<%= project.name %> |
      | ["spec"]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip %>:3260      |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | pvc-iscsi-<%= project.name %> |
      | ["spec"]["volumeName"] | pv-iscsi-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-iscsi-<%= project.name %>" PVC becomes bound to the "pv-iscsi-<%= project.name %>" PV

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | iscsi-<%= project.name %>     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-iscsi-<%= project.name %> |
    Then the step should succeed
    And the pod named "iscsi-<%= project.name %>" becomes ready

    # Create 2nd Pod using same session with a different LUN
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]              | pv1-iscsi-<%= project.name %> |
      | ["spec"]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["iscsi"]["lun"]          | 1                             |
    And I switch to the default user
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | pvc1-iscsi-<%= project.name %> |
      | ["spec"]["volumeName"] | pv1-iscsi-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-iscsi-<%= project.name %>" PVC becomes bound to the "pv-iscsi-<%= project.name %>" PV

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | iscsi1-<%= project.name %>     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc1-iscsi-<%= project.name %> |
    Then the step should succeed
    And the pod named "iscsi1-<%= project.name %>" becomes ready

    # Covering BZ#1419607
    # Delete one of the Pods, the remaining one is still Running
    Given I ensure "iscsi1-<%= project.name %>" pod is deleted
    When I get project pod named "iscsi-<%= project.name %>"
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

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod-direct.json" replacing paths:
      | ["metadata"]["name"]                            | iscsi-<%= project.name %>                                |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip_2 %>:3260                                |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]      | {"<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"}   |
    Then the step should succeed
    And the pod named "iscsi-<%= project.name %>" becomes ready
    When I execute on the pod:
      | cp | /hello | /mnt/iscsi|
    Then the step should succeed
    When I execute on the pod:
      | /mnt/iscsi/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

    When I disable the second iSCSI path
    Then the step should succeed
    When I execute on the pod:
      | /mnt/iscsi/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"
    When I execute on the pod:
      | touch | /mnt/iscsi/testfile |
    Then the step should succeed
