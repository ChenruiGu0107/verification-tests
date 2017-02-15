Feature: oc attach related scenarios
  # @author yapei@redhat.com
  # @case_id OCP-11162
  Scenario: check oc attach functionality
    Given I have a project
    And evaluation of `"doublecontainers"` is stored in the :pod_name clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pod_with_two_containers.json |
    Then the step should succeed
    Given the pod named "<%= cb.pod_name %>" becomes ready
    When I run the :attach client command
    Then the step should fail
    And the output should contain:
      | error: POD is required for attach |
      | 'oc attach -h' for help and examples |
    When I run the :attach client command with:
      | h ||
    Then the step should succeed
    And the output should match:
      | [aA]ttach to a running container   |
    When I run the :attach client command with:
      | pod      | <%= cb.pod_name %> |
      | _timeout | 20                 |
    Then the step should have timed out
    And the output should contain:
      | serving at 8080 |
    When I run the :attach client command with:
      | pod      | <%= cb.pod_name %> |
      | c        | hello-openshift-fedora |
      | _timeout | 20                 |
    Then the step should have timed out
    And the output should contain:
      | serving on 8081 |
      | serving on 8888 |
    When I run the :attach client command with:
      | pod         | <%= cb.pod_name %> |
      | container   | hello-openshift-fedora |
      | tty         | true       |
      | stdin       | true       |
      | _timeout    | 20         |
    Then the step should have timed out
    And the output should contain:
      | serving on 8081 |
      | serving on 8888 |

  # @author yapei@redhat.com
  # @case_id OCP-10672
  Scenario: Negative test for oc attach
    Given I have a project
    And I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | attach |
      | test_do_not_use | -u |
    Then the step should fail
    And the output should contain:
      | Error: unknown shorthand flag: 'u' in -u |
      | Usage:   |
      | oc attach POD -c CONTAINER [options]  |
    When I run the :attach client command with:
      | pod | 123456-7890 |
    Then the step should fail
    And the output should contain:
      | pods "123456-7890" not found |
    When I run the :attach client command with:
      | pod | 123456-7890 |
      | cmd_name | date   |
    Then the step should fail
    And the output should contain:
      | error: expected a single argument: POD, saw 2: [123456-7890 date] |

