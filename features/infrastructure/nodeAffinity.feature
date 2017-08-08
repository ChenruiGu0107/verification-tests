Feature: nodeAffinity
  # @author wjiang@redhat.com
  # @case_id OCP-14581
  Scenario: node affinity preferred invalid weight values
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-preferred-weight-fraction.yaml |
    Then the step should fail
    Then the output should match:
      | fractional integer |
    And the project should be empty
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-preferred-weight-0.yaml |
    Then the step should fail
    Then the output should match:
      | [Ii]nvalid value.*0.*must be in the range 1-100 |
    And the project should be empty
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-preferred-weight-101.yaml |
    Then the step should fail
    Then the output should match:
      | [Ii]nvalid value.*101.*must be in the range 1-100 |
    And the project should be empty

  # @author wjiang@redhat.com
  # @case_id OCP-14580
  Scenario: node affinity invalid value - value must be single value
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-value-lt.yaml |
    Then the step should fail
    Then the output should match:
      | [Rr]equired value.*must be specified single value when `operator` is 'Lt' or 'Gt' |
    And the project should be empty

  # @author wjiang@redhat.com
  # @case_id OCP-14579
  Scenario: node affinity invalid value - value required
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-value-empty.yaml |
    Then the step should fail
    Then the output should match:
      | [Rr]equired value.*must be specified when `operator` is 'In' or 'NotIn' |
    And the project should be empty

  # @author wjiang@redhat.com
  # @case_id OCP-14578
  Scenario: node affinity invalid value - key name must be non-empty
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-key-empty.yaml |
    Then the step should fail
    Then the output should match:
      | [Ii]nvalid value.*name part must be non-empty |
      | [Ii]nvalid value.*name part must consist of alphanumeric characters, '-', '_' or '.', and must start and end with an alphanumeric character |
    And the project should be empty

  # @author wjiang@redhat.com
  # @case_id OCP-14538
  Scenario: node affinity values forbidden when operator is DoesNotExist
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-doesnotexist.yaml |
    Then the step should fail
    Then the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' |
    And the project should be empty

  # @author wjiang@redhat.com
  # @case_id OCP-14536
  Scenario: node affinity values forbidden when operator is Exists
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-exists.yaml |
    Then the step should fail
    Then the output should match:
      | [Ff]orbidden.*may not be specified when `operator` is 'Exists' or 'DoesNotExist' |
    And the project should be empty

  # @author wjiang@redhat.com
  # @case_id OCP-14533
  Scenario: node affinity invalid operator Equals
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-operator-equals.yaml |
    Then the step should fail
    Then the output should match:
      | [Ii]nvalid value.*"Equals": not a valid selector operator |
    And the project should be empty
