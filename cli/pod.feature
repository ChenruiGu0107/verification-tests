Feature: pods related scenarios

  # @author pruan@redhat.com
  # @case_id OCP-10711
  @admin
  Scenario: Limit to create pod to access hostIPC
    Given I have a project
    And I select a random node's host
    And I obtain test data file "pods/tc509107/hostipc_true.json"
    Then I run the :create client command with:
      | f | hostipc_true.json |
    Then the step should fail
    And I replace content in "hostipc_true.json":
      | "hostIPC": true | "hostIPC": false |
    Then I run the :create client command with:
      | f | hostipc_true.json |
    Then the step should succeed
    Then I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc509107/hostipc_cluster_admin.json |
      | n | <%= project.name %>                                                                                         |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=client-cert |
    When I execute on the "hello-openshift" pod:
      | ipcs | -m |
    Then the step should succeed
    And the output should not contain:
      | 0x    |
      | 57005 |
    When I run commands on the host:
      | ipcmk  -M  57005 |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    When I execute on the "client-cert" pod:
      | ipcs | -m |
    Then the step should succeed
    And the output should contain:
      | 57005 |

  # @author pruan@redhat.com
  # @case_id OCP-11189
  @admin
  Scenario: Limit to create pod to access hostPID
    Given I have a project
    And I obtain test data file "pods/tc509108/hostpid_true.json"
    Then I run the :create client command with:
      | f | hostpid_true.json |
    Then the step should fail
    And I replace content in "hostpid_true.json":
      | "hostPID": true | "hostPID": false |
    Then I run the :create client command with:
      | f | hostpid_true.json |
    Then the step should succeed
    Then I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc509108/hostpid_true_admin.json |
      | n | <%= project.name %>                                                                                      |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=hello-openshift |
    When I execute on the "hello-openshift" pod:
      | bash                            |
      | -c                              |
      | ps aux \| awk '{print $2, $11}' |
    Then the output should match:
      | \d+\s+squid |

  # @author pruan@redhat.com
  # @case_id OCP-11946
  Scenario: Create pod will inherit all "requiredCapabilities" from the SCC that you validate against
    Given I have a project
    And I run the :run client command with:
      | name  | nginx |
      | image | nginx |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    I get project pods as YAML
    the output should contain:
      | drop:        |
      | - KILL       |
      | - MKNOD      |
      | - SETGID     |
      | - SETUID     |
      | - SYS_CHROOT |
    """

  # @author chuyu@redhat.com
  # @case_id OCP-11006
  @admin
  Scenario: PDB create
    Given I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc538208/pdb_negative_absolute_number.yaml |
      | n | <%= project.name %>                                                                                         	       |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc538208/pdb_negative_percentage.yaml      |
      | n | <%= project.name %>                                                                                                        |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc538208/pdb_zero_number.yaml	       |
      | n | <%= project.name %>                                                                                                        |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc538208/pdb_zero_percentage.yaml	       |
      | n | <%= project.name %>                                                                                                        |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc538208/pdb_non_absolute_number.yaml      |
      | n | <%= project.name %>                                                                                                        |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc538208/pdb_non_number_percentage.yaml    |
      | n | <%= project.name %>                                                                                                        |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc538208/pdb_more_than_full_percentage.yaml|
      | n | <%= project.name %>                                                                                                        |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc538208/pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>                                                                                                        |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc538208/pdb_reasonable_percentage.yaml    |
      | n | <%= project.name %>                                                                                                        |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-12897
  @admin
  Scenario: PDB create with beta1
    Given I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/ocp12897/pdb_negative_absolute_number.yaml |
      | n | <%= project.name %>                                                                                                |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/ocp12897/pdb_negative_percentage.yaml |
      | n | <%= project.name %>                                                                                           |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/ocp12897/pdb_zero_number.yaml |
      | n | <%= project.name %>                                                                                   |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/ocp12897/pdb_zero_percentage.yaml |
      | n | <%= project.name %>                                                                                       |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/ocp12897/pdb_non_absolute_number.yaml |
      | n | <%= project.name %>                                                                                           |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/ocp12897/pdb_non_number_percentage.yaml |
      | n | <%= project.name %>                                                                                             |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/ocp12897/pdb_more_than_full_percentage.yaml |
      | n | <%= project.name %>                                                                                                 |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/ocp12897/pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>                                                                                                |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/ocp12897/pdb_reasonable_percentage.yaml |
      | n | <%= project.name %>                                                                                             |
    Then the step should succeed


  # @author chezhang@redhat.com
  # @case_id OCP-11362
  Scenario: Specify safe namespaced kernel parameters for pod with invalid value	
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/sysctls/pod-sysctl-safe-invalid1.yaml |
    Then the step should fail
    And the output should match:
      | Invalid value: "invalid": sysctl "invalid" not of the format sysctl_name |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/sysctls/pod-sysctl-safe-invalid3.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | po |
    Then the output should match:
      | hello-pod.*SysctlForbidden |
    When I run the :describe client command with:
      | resource | po        |
      | name     | hello-pod |
    Then the output should match:
      | Warning\\s+SysctlForbidden.*forbidden sysctl: "invalid" not whitelisted |
    """
    Given I ensure "hello-pod" pod is deleted
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/sysctls/pod-sysctl-safe-invalid2.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | po        |
      | name     | hello-pod |
    Then the output should match:
      | Status:\\s+Pending |
    """

  # @author sijhu@redhat.com
  # @case_id OCP-10962
  Scenario: Specify safe namespaced kernel parameters for pod
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/sysctls/pod-sysctl-safe.yaml  |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I execute on the "hello-pod" pod:
      | cat | /proc/sys/kernel/shm_rmid_forced |
    Then the step should succeed
    Then the output should equal "1"
    When I execute on the "hello-pod" pod:
      | cat | /proc/sys/net/ipv4/ip_local_port_range |
    Then the step should succeed
    And the output should contain:
      | 33768 |
      | 61000 |
    Given I ensure "hello-pod" pod is deleted
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/sysctls/net_ipv4_tcp_syncookies.yaml  |
    Then the step should succeed
    Given the pod named "hello-pod" becomes present
    When I run the :describe client command with:
      | resource | pods      |
      | name     | hello-pod |
    Then the output should match:
      | Status:\\s+Pending |
