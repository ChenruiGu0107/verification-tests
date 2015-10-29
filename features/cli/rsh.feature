Feature: rsh.feature

  # @author cryan@redhat.com
  # @case_id 497699
  Scenario: Check oc rsh for simpler access to a remote shell
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pod_with_two_containers.json |
    Then the step should succeed
    When I run the :rsh client command
    Then the step should fail
    And the output should contain "error: rsh requires a single Pod to connect to"
    When I run the :rsh client command with:
      | help ||
    Then the output should contain "Open a remote shell session to a container"
    Given all pods in the project are ready
    When I run the :rsh client command with:
      | pod | doublecontainers |
    Then the step should succeed
