Feature: podAffinity
  # @author wjiang@redhat.com
  # @case_id OCP-14696
  Scenario: pod affinity - invalid operator
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-invalid-operator.yaml |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid value.*Equals.*not a valid selector operator |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | pod-affinity-invalid-operator |

  # @author wjiang@redhat.com
  # @case_id OCP-14691
  Scenario: pod affinity - value may not be specified when operator is Exists or DoesNotExist
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-exists-value.yaml |
    Then the step should fail
    And the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' | 
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | pod-affinity-exists-value |
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-doesnotexist-value.yaml |
    Then the step should fail
    And the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | pod-affinity-doesnetexist-value |

  # @author wjiang@redhat.com
  # @case_id OCP-14607
  Scenario: pod affinity topologykey cannot be empty
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-invalid-topologykey-empty.yaml |
    Then the step should fail
    And the output should match:
      | [Rr]equired value.*can only be empty for PreferredDuringScheduling pod anti affinity |
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | pod-affinity-invalid-topologykey-empty |
