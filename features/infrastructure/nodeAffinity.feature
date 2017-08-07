Feature: nodeAffinity
  # @author wjiang@redhat.com
  # @case_id OCP-14581
  Scenario: node affinity preferred invalid weight values
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-preferred-weight-fraction.yaml |
    Then the output should contain:
      | fractional integer |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | node-affinity-preferred-weight-fraction |
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-preferred-weight-0.yaml |
    Then the output should contain:
      | Invalid value: 0: must be in the range 1-100 |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | node-affinity-preferred-weight-0 |   
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-preferred-weight-101.yaml |
    Then the output should contain:
      | Invalid value: 101: must be in the range 1-100 |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | node-affinity-preferred-weight-101 |

  # @author wjiang@redhat.com
  # @case_id OCP-14580
  Scenario: node affinity invalid value - value must be single value
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-value-lt.yaml |
    Then the output should contain:
      | Required value: must be specified single value when `operator` is 'Lt' or 'Gt' |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | node-affinity-invalid-value-lt |

  # @author wjiang@redhat.com
  # @case_id OCP-14579
  Scenario: node affinity invalid value - value required
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-value-empty.yaml |
    Then the output should contain:
      | Required value: must be specified when `operator` is 'In' or 'NotIn' |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | node-affinity-invalid-value-empty |

  # @author wjiang@redhat.com
  # @case_id OCP-14578
  Scenario: node affinity invalid value - key name must be non-empty
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-key-empty.yaml |
    Then the output should contain:
      | Invalid value: "": name part must be non-empty |
      | Invalid value: "": name part must consist of alphanumeric characters, '-', '_' or '.', and must start and end with an alphanumeric character (e.g. 'MyName',  or 'my.name',  or '123-abc', regex used for validation is '([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9]') |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | node-affinity-preferred-invalid-key-empty |

  # @author wjiang@redhat.com
  # @case_id OCP-14538
  Scenario: node affinity values forbidden when operator is DoesNotExist
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-doesnotexist.yaml |
    Then the output should contain:
      | Forbidden: may not be specified when `operator` is 'Exists' or 'DoesNotExist' |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | node-affinity-invalid-doesnotexist |

  # @author wjiang@redhat.com
  # @case_id OCP-14536
  Scenario: node affinity values forbidden when operator is Exists
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-exists.yaml |
    Then the output should contain:
      | Forbidden: may not be specified when `operator` is 'Exists' or 'DoesNotExist' |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | node-affinity-invalid-exists | 

  # @author wjiang@redhat.com
  # @case_id OCP-14533
  Scenario: node affinity invalid operator Equals
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/pods/nodeAffinity/pod-node-affinity-invalid-operator-equals.yaml |
    Then the output should contain:
      | Invalid value: "Equals": not a valid selector operator |
    When I run the :get client command with:
      | resource | pods |
    Then the output should not contain:
      | node-affinity-preferred-invalid-operator-equals |
