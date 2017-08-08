Feature: podAffinity
  # @author wjiang@redhat.com
  # @case_id OCP-14696
  Scenario: pod affinity - invalid operator
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-invalid-operator.yaml |
    Then the step should fail
    Then the output should match:
      | [Ii]nvalid value.*Equals.*not a valid selector operator |
    And the project should be empty

  # @author wjiang@redhat.com
  # @case_id OCP-14691
  Scenario: pod affinity - value may not be specified when operator is Exists or DoesNotExist
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-exists-value.yaml |
    Then the step should fail
    Then the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' | 
    And the project should be empty
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-doesnotexist-value.yaml |
    Then the step should fail
    Then the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' |
    And the project should be empty

  # @author wjiang@redhat.com
  # @case_id OCP-14607
  Scenario: pod affinity topologykey cannot be empty
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-invalid-topologykey-empty.yaml |
    Then the step should fail
    Then the output should match:
      | [Rr]equired value.*can only be empty for PreferredDuringScheduling pod anti affinity |
    And the project should be empty
