Feature: InitContainers

  # @author chezhang@redhat.com
  # @case_id OCP-12911
  Scenario: App container status depends on init containers exit code
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-success.yaml |
    Then the step should succeed
    Given the pod named "init-success" becomes ready
    Given I ensure "init-success" pod is deleted
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/init-containers-fail.yaml |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | po        |
      | resource_name | init-fail |
    Then the output should match:
      | init-fail\\s+0/1\\s+Init:CrashLoopBackOff\\s+2 |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-12914
  Scenario: Init containers with readiness probe
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/init-containers-readiness.yaml |
    Then the step should fail
    And the output should contain:
      | initContainers[0].readinessProbe: Invalid value |

  # @author chezhang@redhat.com
  # @case_id OCP-12893
  Scenario: Init containers with restart policy "Always"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-always-fail.yaml |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | po               |
      | resource_name | init-always-fail |
    Then the output should match:
      | init-always-fail\\s+0/1\\s+Init:CrashLoopBackOff\\s+2 |
    """
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-always-succ.yaml |
    Then the step should succeed
    Given the pod named "init-always-succ" becomes ready

  # @author chezhang@redhat.com
  # @case_id OCP-12896
  Scenario: Init containers with restart policy "Never"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-never-fail.yaml |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | po              |
      | resource_name | init-never-fail |
    Then the output should match:
      | init-never-fail\\s+0/1\\s+Init:Error\\s+0 |
    """
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-never-succ.yaml |
    Then the step should succeed
    Given the pod named "init-never-succ" becomes ready

  # @author chezhang@redhat.com
  # @case_id OCP-12894
  Scenario: Init containers with restart policy "OnFailure"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-onfailure-fail.yaml |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | po                  |
      | resource_name | init-onfailure-fail |
    Then the output should match:
      | init-onfailure-fail\\s+0/1\\s+Init:CrashLoopBackOff\\s+2 |
    """
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-onfailure-succ.yaml |
    Then the step should succeed
    Given the pod named "init-onfailure-succ" becomes ready

  # @author chezhang@redhat.com
  # @case_id OCP-12883
  Scenario: Init container should failed after exceed activeDeadlineSeconds
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-deadline.yaml |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | po            |
      | resource_name | init-deadline |
    Then the output should match:
      | init-deadline\\s+0/1\\s+DeadlineExceeded |
    """
    When I run the :describe client command with:
      | resource | pod           |
      | name     | init-deadline |
    And the output should match:
      | Status:\\s+Failed                                                         |
      | Reason:\\s+DeadlineExceeded                                               |
      | Message:\\s+Pod was active on the node longer than the specified deadline |

  # @author chezhang@redhat.com
  # @case_id OCP-12913
  Scenario: Init containers with volume work fine
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-volume.yaml |
    Then the step should succeed
    And the pod named "init-volume" status becomes :running
    When I run the :exec client command with:
      | pod              | init-volume            |
      | exec_command     | cat                    |
      | exec_command_arg | /init-test/volume-test |
    Then the output should contain:
      | This is OCP test wmeng |

  # @author chezhang@redhat.com
  # @case_id OCP-12916
  @admin
  Scenario: quota apply to pod with init containers
    Given I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/quota.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-quota1.yaml |
    Then the step should succeed
    Given the pod named "init-quota1" status becomes :running
    When I run the :describe client command with:
      | resource | quota             |
      | name     | compute-resources |
    Then the output should match:
      | limits.cpu\\s+500m\\s+2         |
      | limits.memory\\s+400Mi\\s+2Gi   |
      | pods\\s+1\\s+4                  |
      | requests.cpu\\s+400m\\s+1       |
      | requests.memory\\s+300Mi\\s+1Gi |
    Given I ensure "init-quota1" pod is deleted
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-quota2.yaml |
    Then the step should succeed
    Given the pod named "init-quota2" status becomes :running
    When I run the :describe client command with:
      | resource | quota             |
      | name     | compute-resources |
    Then the output should match:
      | limits.cpu\\s+300m\\s+2         |
      | limits.memory\\s+240Mi\\s+2Gi   |
      | pods\\s+1\\s+4                  |
      | requests.cpu\\s+200m\\s+1       |
      | requests.memory\\s+200Mi\\s+1Gi |

  # @author wmeng@redhat.com
  # @case_id OCP-12918
  Scenario: QoS Tier for pod with init containers
  # Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/pod-init-containers-qos.yaml |
    Then the step should succeed
    Given the pod named "init-qos-burstable" becomes ready
    Then I run the :describe client command with:
      | resource | pod                |
      | name     | init-qos-burstable |
    And the output should not match:
      | BestEffort |
      | Guaranteed |
    And the output should match:
      | Burstable  |

  # @author chezhang@redhat.com
  # @case_id OCP-12909
  Scenario: Init containers can be accessed by oc commands
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/Promote_InitContainers/pod-init-containers-loop.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | pod/init-loop |
      | c             | init          |
    Then the step should succeed
    And the output should contain:
      | hello init container |
    """
    When I run the :rsh client command with:
      | c       | init             |
      | pod     | init-loop        |
      | command | cat              |
      | command | /etc/resolv.conf |
    Then the step should succeed
    And the output should contain:
      | options ndots |
    When I run the :rsync client command with:
      | source      | init-loop:/etc/resolv.conf |
      | destination | <%= localhost.workdir %>   |
      | c           | init                       |
    Then the step should succeed
    And the output should contain:
      | resolv.conf |
    When I run the :debug client command with:
      | resource     | pod/init-loop |
      | c            | init          |
      | oc_opts_end  |               |
      | exec_command | /bin/env      |
    Then the step should succeed
    And the output should contain:
      |  Debugging with pod/init-loop-debug |
      |  PATH                               |
      |  HOSTNAME                           |
      |  KUBERNETES                         |
      |  HOME                               |
      |  Removing debug pod                 |
    When I run the :attach client command with:
      | pod      | init-loop |
      | c        | init      |
      | _timeout | 15        |
    Then the step should have timed out
    And the output should contain:
      | hello init container |

