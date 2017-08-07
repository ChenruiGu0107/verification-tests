Feature: podAffinity
  # @author wjiang@redhat.com
  # @case_id OCP-14696
  Scenario: pod affinity - invalid operator
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-invalid-operator.yaml |
    Then the output should contain:
      | Invalid value: "Equals": not a valid selector operator|
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | pod-affinity-invalid-operator |

  # @author wjiang@redhat.com
  # @case_id OCP_14691
  Scenario: pod affinity - value may not be specified when operator is Exists or DoesNotExist
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-exists-value.yaml |
    Then the output should contain:
		  | Forbidden: may not be specified when `operator` is 'Exists' or 'DoesNotExist' | 
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | pod-affinity-exists-value |
		When I run the :create client command with:
			| f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-doesnotexist-value.yaml |
    Then the output should contain:
      | Forbidden: may not be specified when `operator` is 'Exists' or 'DoesNotExist' |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | pod-affinity-doesnotexist-value |

  # @author wjiang@redhat.com
  # @case_id OCP-14607
  Scenario: pod affinity topologykey cannot be empty
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/podAffinity/pod-pod-affinity-invalid-topologykey-empty.yaml |
    Then the output should contain:
      | Required value: can only be empty for PreferredDuringScheduling pod anti affinity |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | pod-affinity-invalid-topologykey-empty |
