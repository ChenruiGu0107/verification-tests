Feature: pods related scenarios
  # @author chezhang@redhat.com
  # @case_id OCP-11218
  Scenario: kubectl describe pod should show qos tier info when pod without limits and request info
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I run the :describe client command with:
      | resource | pods            |
      | name     | hello-openshift |
    Then the output should match:
      | Status:\\s+Running    |
      | BestEffort            |
      | State:\\s+Running     |

  # @author chezhang@redhat.com
  # @case_id OCP-11527
  Scenario: kubectl describe pod should show qos tier info
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notbesteffort.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod-bad.json |
    Then the step should succeed
    Given the pod named "pod-notbesteffort" becomes ready
    When I run the :describe client command with:
      | resource | pods              |
      | name     | pod-notbesteffort |
    Then the output should match:
      | Status:\\s+Running |
      | Burstable          |
      | Limits:            |
      | cpu:\\s+500m       |
      | memory:\\s+256Mi   |
      | Requests:          |
      | cpu:\\s+200m       |
      | memory:\\s+256Mi   |
      | State:\\s+Running  |
    When I run the :describe client command with:
      | resource | pods              |
      | name     | hello-openshift   |
    Then the output should match:
      | Status:\\s+Pending |
      | BestEffort         |
      | State:\\s+Waiting  |

  # @author chezhang@redhat.com
  # @case_id OCP-10729
  Scenario: Implement supplemental groups for pod
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc510724/pod-supplementalGroups.yaml |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I run the :exec client command with:
      | pod          | hello-openshift |
      | exec_command | id              |
    Then the step should succeed
    And the output should contain:
      | groups=1234,5678, |
    Given I ensure "hello-openshift" pod is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc510724/pod-supplementalGroups-multi-cotainers.yaml |
    Then the step should succeed
    Given the pod named "multi-containers" becomes ready
    When I run the :rsh client command with:
      | c        | hello-openshift     |
      | pod      | multi-containers    |
      | command  | id                  |
      | _timeout | 20                  |
    Then the step should succeed
    And the output should contain:
      | groups=1234,5678, |
    When I run the :rsh client command with:
      | c        | nfs-server          |
      | pod      | multi-containers    |
      | command  | id                  |
      | _timeout | 20                  |
    Then the step should succeed
    And the output should contain:
      | groups=1234,5678, |
    Given I ensure "multi-containers" pod is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc510724/pod-supplementalGroups-invalid.yaml |
    Then the step should fail
    And the output should contain 2 times:
      | nvalid value |

  # @author chezhang@redhat.com
  # @case_id OCP-11753
  Scenario: Pod should be immediately deleted if it's not scheduled even if graceful termination period is set
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/graceful-delete/10.json |
    Then the step should succeed
    Given the pod named "grace10" becomes ready
    When I run the :delete client command with:
      | object_type       | pods    |
      | object_name_or_id | grace10 |
    Then the step should succeed
    Given the pod named "grace10" becomes terminating
    Then I wait for the resource "pod" named "grace10" to disappear within 30 seconds

  # @author pruan@redhat.com
  # @case_id OCP-10711
  @admin
  Scenario: Limit to create pod to access hostIPC
    Given I have a project
    And I select a random node's host
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc509107/hostipc_true.json"
    Then I run the :create client command with:
      | f | hostipc_true.json |
    Then the step should fail
    And I replace content in "hostipc_true.json":
      | "hostIPC": true | "hostIPC": false |
    Then I run the :create client command with:
      | f | hostipc_true.json |
    Then the step should succeed
    Then I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc509107/hostipc_cluster_admin.json |
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
    And I select a random node's host
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc509108/hostpid_true.json"
    Then I run the :create client command with:
      | f | hostpid_true.json |
    Then the step should fail
    And I replace content in "hostpid_true.json":
      | "hostPID": true | "hostPID": false |
    Then I run the :create client command with:
      | f | hostpid_true.json |
    Then the step should succeed
    Then I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc509108/hostpid_true_admin.json |
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

  # @author cryan@redhat.com
  # @case_id OCP-10813
  # @bug_id 1324396
  Scenario: Update ActiveDeadlineSeconds for pod
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc521546/hello-pod.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pod                                    |
      | resource_name | hello-openshift                        |
      | p             | {"spec":{"activeDeadlineSeconds":101}} |
    Then the step should fail
    And the output should contain "must be less than or equal to previous value"
    When I run the :patch client command with:
      | resource      | pod                                    |
      | resource_name | hello-openshift                        |
      | p             | {"spec":{"activeDeadlineSeconds":0}}   |
    Then the step should fail
    And the output should contain "Invalid value: 0"
    When I run the :patch client command with:
      | resource      | pod                                    |
      | resource_name | hello-openshift                        |
      | p             | {"spec":{"activeDeadlineSeconds":5.5}} |
    Then the step should fail
    And the output should match "(fractional integer|cannot convert float64 to int64)"
    When I run the :patch client command with:
      | resource      | pod                                    |
      | resource_name | hello-openshift                        |
      | p             | {"spec":{"activeDeadlineSeconds":-5}}  |
    Then the step should fail
    And the output should contain "Invalid value: -5"

  # @author chuyu@redhat.com
  # @case_id OCP-11006
  @admin
  Scenario: PDB create
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc538208/pdb_negative_absolute_number.yaml |
      | n | <%= project.name %>                                                                                         	       |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc538208/pdb_negative_percentage.yaml      |
      | n | <%= project.name %>                                                                                                        |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc538208/pdb_zero_number.yaml	       |
      | n | <%= project.name %>                                                                                                        |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc538208/pdb_zero_percentage.yaml	       |
      | n | <%= project.name %>                                                                                                        |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc538208/pdb_non_absolute_number.yaml      |
      | n | <%= project.name %>                                                                                                        |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc538208/pdb_non_number_percentage.yaml    |
      | n | <%= project.name %>                                                                                                        |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc538208/pdb_more_than_full_percentage.yaml|
      | n | <%= project.name %>                                                                                                        |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc538208/pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>                                                                                                        |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc538208/pdb_reasonable_percentage.yaml    |
      | n | <%= project.name %>                                                                                                        |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-10986
  Scenario: Oauth provider info should be consumed in a pod
    Given the master version >= "3.4"
    Given I have a project
    When I run the :new_app client command with:
      | docker_image 	 | aosqe/ruby-ex	|
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=ruby-ex      |
    When I run the :rsh client command with:
      | pod          | <%= pod.name %> |
      | _stdin       | curl https://openshift.default.svc/.well-known/oauth-authorization-server -k |
    Then the step should succeed
    And the output should contain:
      | implicit		|
      | user:list-projects	|


  # @author qwang@redhat.com
  # @case_id OCP-11055
  Scenario: /dev/shm can be automatically shared among all of a pod's containers
    Given I have a project
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pod_with_two_containers.json
    Then the step should succeed
    When the pod named "doublecontainers" becomes ready
    # Enter container 1 and write files
    When I run the :exec client command with:
      | pod              | doublecontainers        |
      | container        | hello-openshift         |
      | oc_opts_end      |                         |
      | exec_command     | sh                      |
      | exec_command_arg | -c                      |
      | exec_command_arg | echo "hi" > /dev/shm/c1 |
    Then the step should succeed
    When I run the :exec client command with:
      | pod              | doublecontainers |
      | container        | hello-openshift  |
      | exec_command     | cat              |
      | exec_command_arg | /dev/shm/c1      |
    Then the step should succeed
    And the output should contain "hi"
    # Enter container 2 and check whether it can share the files under directory /dev/shm
    When I run the :exec client command with:
      | pod              | doublecontainers       |
      | container        | hello-openshift-fedora |
      | exec_command     | cat                    |
      | exec_command_arg | /dev/shm/c1            |
    Then the step should succeed
    And the output should contain "hi"
    # Write files in container 2 and check container 1
    When I run the :exec client command with:
      | pod              | doublecontainers           |
      | container        | hello-openshift-fedora     |
      | oc_opts_end      |                            |
      | exec_command     | sh                         |
      | exec_command_arg | -c                         |
      | exec_command_arg | echo "hello" > /dev/shm/c2 |
    Then the step should succeed
    When I run the :exec client command with:
      | pod              | doublecontainers |
      | container        | hello-openshift  |
      | exec_command     | cat              |
      | exec_command_arg | /dev/shm/c2      |
    Then the step should succeed
    And the output should contain "hello"
  
  
  # @author chuyu@redhat.com
  # @case_id OCP-12897
  @admin
  Scenario: PDB create with beta1
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/ocp12897/pdb_negative_absolute_number.yaml |
      | n | <%= project.name %>                                                                                                |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/ocp12897/pdb_negative_percentage.yaml |
      | n | <%= project.name %>                                                                                           |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/ocp12897/pdb_zero_number.yaml |
      | n | <%= project.name %>                                                                                   |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/ocp12897/pdb_zero_percentage.yaml |
      | n | <%= project.name %>                                                                                       |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/ocp12897/pdb_non_absolute_number.yaml |
      | n | <%= project.name %>                                                                                           |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/ocp12897/pdb_non_number_percentage.yaml |
      | n | <%= project.name %>                                                                                             |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/ocp12897/pdb_more_than_full_percentage.yaml |
      | n | <%= project.name %>                                                                                                 |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/ocp12897/pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>                                                                                                |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/ocp12897/pdb_reasonable_percentage.yaml |
      | n | <%= project.name %>                                                                                             |
    Then the step should succeed


  # @author chezhang@redhat.com
  # @case_id OCP-11362
  Scenario: Specify safe namespaced kernel parameters for pod with invalid value	
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/sysctls/pod-sysctl-safe-invalid1.yaml |
    Then the step should fail
    And the output should match:
      | Invalid value: "invalid": sysctl "invalid" not of the format sysctl_name |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/sysctls/pod-sysctl-safe-invalid3.yaml |
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
      | Warning\\s+SysctlForbidden\\s+forbidden sysctl: "invalid" not whitelisted |
    """
    Given I ensure "hello-pod" pod is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/sysctls/pod-sysctl-safe-invalid2.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | po        |
      | name     | hello-pod |
    Then the output should match:
      | Warning.*Error syncing pod.*shm_rmid_forced: invalid argument |
    """

  # @author sijhu@redhat.com
  # @case_id OCP-10962
  Scenario: Specify safe namespaced kernel parameters for pod
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/sysctls/pod-sysctl-safe.yaml  |
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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/sysctls/net_ipv4_tcp_syncookies.yaml  |
    Then the step should succeed
    Given the pod named "hello-pod" is present
    When I run the :describe client command with:
      | resource | pods      |
      | name     | hello-pod |
    Then the output should match:
      | Status:\\s+Pending |
      | open /proc/sys/net/ipv4/tcp_syncookies: no such file or directory |
