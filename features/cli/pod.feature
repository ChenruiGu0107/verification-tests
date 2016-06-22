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
      | QoS Tier:             |
      | cpu:\\s+BestEffort    |
      | memory:\\s+BestEffort |
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
      | Status:\\s+Running    |
      | QoS Tier:             |
      | cpu:\\s+Burstable     |
      | memory:\\s+Guaranteed |
      | Limits:               |
      | cpu:\\s+500m          |
      | memory:\\s+256Mi      |
      | Requests:             |
      | cpu:\\s+200m          |
      | memory:\\s+256Mi      |
      | State:\\s+Running     |
    When I run the :describe client command with:
      | resource | pods              |
      | name     | hello-openshift   |
    Then the output should match:
      | Status:\\s+Pending    |
      | QoS Tier:             |
      | cpu:\\s+BestEffort    |
      | memory:\\s+BestEffort |
      | State:\\s+Waiting     |

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
