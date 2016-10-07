Feature: pods related scenarios
  # @author chezhang@redhat.com
  # @case_id 515450
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
  # @case_id 509049
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
  # @case_id 510724
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc510724/pod-supplementalGroups-invalid.yaml |
    Then the step should fail
    And the output should contain 2 times:
      | nvalid value |

  # @author chezhang@redhat.com
  # @case_id 509043
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
    Then I wait for the resource "pod" named "grace10" to disappear within 12 seconds

  # @author pruan@redhat.com
  # @case_id 509107
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
  # @case_id 509108
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
  # @case_id 518946
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
  # @case_id 521546
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
    And the output should contain "must be greater than 0"
    When I run the :patch client command with:
      | resource      | pod                                    |
      | resource_name | hello-openshift                        |
      | p             | {"spec":{"activeDeadlineSeconds":5.5}} |
    Then the step should fail
    And the output should contain "fractional integer"
    When I run the :patch client command with:
      | resource      | pod                                    |
      | resource_name | hello-openshift                        |
      | p             | {"spec":{"activeDeadlineSeconds":-5}}  |
    Then the step should fail
    And the output should contain "must be greater than 0"
