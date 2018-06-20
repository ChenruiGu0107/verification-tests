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
    Then the output should match:
      | 123456                                   |
      | (svirt_sandbox_file_t\|container_file_t) |
      | s0:c2,c13                                |

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
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/pv-read-write.json" where:
      | ["metadata"]["name"]                      | iscsi-rw-<%= project.name %> |
      | ["spec"]["iscsi"]["targetPortal"]         | <%= cb.iscsi_ip %>:3260      |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                       |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/pvc-read-write.json" replacing paths:
      | ["metadata"]["name"]   | iscsi-rw-<%= project.name %> |
      | ["spec"]["volumeName"] | iscsi-rw-<%= project.name %> |
    Then the step should succeed
    And the "iscsi-rw-<%= project.name %>" PVC becomes bound to the "iscsi-rw-<%= project.name %>" PV

    # Create RO PV/PVC for LUN 1
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/pv-read-only.json" where:
      | ["metadata"]["name"]                      | iscsi-ro-<%= project.name %> |
      | ["spec"]["iscsi"]["targetPortal"]         | <%= cb.iscsi_ip %>:3260      |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                       |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/pvc-read-only.json" replacing paths:
      | ["metadata"]["name"]   | iscsi-ro-<%= project.name %> |
      | ["spec"]["volumeName"] | iscsi-ro-<%= project.name %> |
    Then the step should succeed
    And the "iscsi-ro-<%= project.name %>" PVC becomes bound to the "iscsi-ro-<%= project.name %>" PV

    # Create the pod with 2 containers mounting RW and RO PVCs
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/pod-two-luns.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | iscsi-rw-<%= project.name %> |
      | ["spec"]["volumes"][1]["persistentVolumeClaim"]["claimName"] | iscsi-ro-<%= project.name %> |
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
      | ["metadata"]["name"]                            | iscsi-<%= project.name %>                              |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip_2 %>:3260                              |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]      | {"<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"} |
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

  # @author piqin@redhat.com
  # @case_id OCP-13395
  @admin
  @destructive
  Scenario: Two Pod reference the same iscsi volume with different accessmode RO and RW
    Given I have a iSCSI setup in the environment
    Given I create a second iSCSI path
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod-direct.json" replacing paths:
      | ["metadata"]["name"]                            | iscsi-1-<%= project.name %>                            |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip_2 %>:3260                              |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]      | {"<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"} |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]     | true                                                   |
    Then the step should succeed
    And the pod named "iscsi-1-<%= project.name %>" becomes ready

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod-direct.json" replacing paths:
      | ["metadata"]["name"]                            | iscsi-2-<%= project.name %>                            |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip_2 %>:3260                              |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]      | {"<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"} |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]     | false                                                  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod                         |
      | name     | iscsi-2-<%= project.name %> |
    Then the step should succeed
    And the output should match:
      | FailedScheduling                    |
      | (NoDiskConflict\|no available disk) |

  # @author piqin@redhat.com
  # @case_id OCP-13394
  @admin
  @destructive
  Scenario: Two Pod reference the same iscsi volume (ROX)
    Given I have a iSCSI setup in the environment
    Given I create a second iSCSI path
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod-direct.json" replacing paths:
      | ["metadata"]["name"]                            | iscsi-1-<%= project.name %>                            |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip_2 %>:3260                              |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]      | {"<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"} |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]     | true                                                   |
    Then the step should succeed
    And the pod named "iscsi-1-<%= project.name %>" becomes ready

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod-direct.json" replacing paths:
      | ["metadata"]["name"]                            | iscsi-2-<%= project.name %>                            |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip_2 %>:3260                              |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]      | {"<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"} |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]     | true                                                   |
    Then the step should succeed
    And the pod named "iscsi-2-<%= project.name %>" becomes ready

    When I execute on the "iscsi-1-<%= project.name %>" pod:
      | df | -T |
    Then the output should contain:
      | ext4       |
      | /mnt/iscsi |
    When I execute on the "iscsi-2-<%= project.name %>" pod:
      | df | -T |
    Then the output should contain:
      | ext4       |
      | /mnt/iscsi |

  # @author piqin@redhat.com
  # @case_id OCP-13398
  @admin
  @destructive
  Scenario: A pod with multiple containers reference the same iscsi volume (ROX and ROW)
    Given I have a iSCSI setup in the environment
    Given I create a second iSCSI path
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod-with-multicontainer.yaml" replacing paths:
      | ["metadata"]["name"]                            | iscsi-<%= project.name %>                              |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip_2 %>:3260                              |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]      | {"<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"} |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]     | true                                                   |
      | ["spec"]["volumes"][1]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip_2 %>:3260                              |
      | ["spec"]["volumes"][1]["iscsi"]["portals"]      | {"<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"} |
      | ["spec"]["volumes"][1]["iscsi"]["readOnly"]     | false                                                  |
    Then the step should succeed

    And I wait up to 120 seconds for the steps to pass:
    """

    When I run the :rsh client command with:
      | c        | iscsipd-ro                |
      | pod      | iscsi-<%= project.name %> |
      | command  | mount                     |
      | _timeout | 20                        |
    Then the step should succeed
    And the output should contain:
      | ext4         |
      | /mnt/iscsipd |
    """
    When I run the :rsh client command with:
      | c        | iscsipd-rw                |
      | pod      | iscsi-<%= project.name %> |
      | command  | mount                     |
      | _timeout | 20                        |
    Then the step should fail

  # @author piqin@redhat.com
  # @case_id OCP-13397
  @admin
  @destructive
  Scenario: A pod with multiple containers reference the same iscsi volume (ROX)
    Given I have a iSCSI setup in the environment
    Given I create a second iSCSI path
    And I have a project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pod-with-multicontainer.yaml" replacing paths:
      | ["metadata"]["name"]                            | iscsi-<%= project.name %>                              |
      | ["spec"]["volumes"][0]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip_2 %>:3260                              |
      | ["spec"]["volumes"][0]["iscsi"]["portals"]      | {"<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"} |
      | ["spec"]["volumes"][0]["iscsi"]["readOnly"]     | true                                                   |
      | ["spec"]["volumes"][1]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip_2 %>:3260                              |
      | ["spec"]["volumes"][1]["iscsi"]["portals"]      | {"<%= cb.iscsi_ip_2%>:3260", "<%= cb.iscsi_ip%>:3260"} |
      | ["spec"]["volumes"][1]["iscsi"]["readOnly"]     | true                                                   |
    Then the step should succeed
    And the pod named "iscsi-<%= project.name %>" becomes ready

    When I run the :rsh client command with:
      | c        | iscsipd-ro                |
      | pod      | iscsi-<%= project.name %> |
      | command  | mount                     |
      | _timeout | 20                        |
    Then the step should succeed
    And the output should contain:
      | ext4         |
      | /mnt/iscsipd |
    When I run the :rsh client command with:
      | c        | iscsipd-rw                |
      | pod      | iscsi-<%= project.name %> |
      | command  | mount                     |
      | _timeout | 20                        |
    Then the step should succeed
    And the output should contain:
      | ext4         |
      | /mnt/iscsipd |

  # @author jhou@redhat.com
  # @case_id OCP-17467
  @admin
  @destructive
  Scenario: Namespaced iscsi chap secrets
    Given I have a iSCSI setup in the environment

    # Create a namespace to store the secret
    Given I create a new project
    And evaluation of `project.name` is stored in the :prj clipboard

    Given I use the "<%= cb.prj %>" project
    When I run the :create client command with:
      | filename  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/chap-secret-auto.yml |
    Then the step should succeed

    # Create PV/PVC
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/pv-chap.json" where:
      | ["metadata"]["name"]                        | pv-iscsi-<%= cb.prj %>  |
      | ["spec"]["iscsi"]["targetPortal"]           | <%= cb.iscsi_ip %>:3260 |
      | ["spec"]["iscsi"]["secretRef"]["name"]      | chap-secret             |
      | ["spec"]["iscsi"]["secretRef"]["namespace"] | <%= cb.prj %>           |
    Then the step should succeed

    Given I create a new project
    And evaluation of `project.name` is stored in the :prj_new clipboard
    And I switch to cluster admin pseudo user
    And I use the "<%= cb.prj_new %>" project

    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | pvc-iscsi-<%= cb.prj_new %> |
      | ["spec"]["volumeName"] | pv-iscsi-<%= cb.prj %>      |
    Then the step should succeed
    And the "pvc-iscsi-<%= cb.prj_new %>" PVC becomes bound to the "pv-iscsi-<%= cb.prj %>" PV

    # Create tester pod
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/iscsi/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | iscsi-<%= cb.prj_new %>     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-iscsi-<%= cb.prj_new %> |
    Then the step should succeed
    And the pod named "iscsi-<%= cb.prj_new %>" becomes ready
