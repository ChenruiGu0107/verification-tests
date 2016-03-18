Feature: oc attach related scenarios
  # @author yapei@redhat.com
  # @case_id 499954
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
      | See 'oc attach -h' for help and examples |
    When I run the :attach client command with:
      | h ||
    Then the step should succeed
    And the output should contain:
      | Attach to a running container   |
      | Attach the current shell to a remote container, returning output or setting up a full |
      | terminal session. Can be used to debug containers and invoke interactive commands. |
      | Usage:   |
      | oc attach POD -c CONTAINER [options]  |
      | Examples: |
      | # Get output from running pod 123456-7890, using the first container by default |
      | $ oc attach 123456-7890 |
      | # Get output from ruby-container from pod 123456-7890 |
      | $ oc attach 123456-7890 -c ruby-container |
      | # Switch to raw terminal mode, sends stdin to 'bash' in ruby-container from pod 123456-780 |
      | # and sends stdout/stderr from 'bash' back to the client |
      | $ oc attach 123456-7890 -c ruby-container -i -t |
      | -c, --container='': Container name. If omitted, the first container in the pod will be chosen |
      | -i, --stdin=false: Pass stdin to the container |
      | -t, --tty=false: Stdin is a TTY |
    When I run the :attach client command with:
      | pod | <%= cb.pod_name %> |
    Then the step should succeed
    And the output should contain:
      | Started, serving at 8080 |
    When I run the :attach client command with:
      | pod | <%= cb.pod_name %> |
      | c   | hello-openshift-fedora |
    Then the step should succeed
    And the output should contain:
      | serving on 8081 |
      | serving on 8888 |
    When I run the :attach client command with:
      | pod         | <%= cb.pod_name %> |
      | container   | hello-openshift-fedora |
      | tty         | true       |
      | stdin       | true       |
    Then the step should succeed
    And the output should contain:
      | serving on 8081 |
      | serving on 8888 |

  # @author yapei@redhat.com
  # @case_id 499953
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
      
