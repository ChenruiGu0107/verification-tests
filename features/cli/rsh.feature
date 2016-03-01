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

  # @author pruan@redhat.com
  # @case_id 497700
  Scenario: Check oc rsh with invalid options
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pod_with_two_containers.json |
    Then the step should succeed
    When I run the :rsh client command with:
      | options | -l |
    Then the step should fail
    And the output should contain "Error: unknown shorthand flag: 'l'"
    When I run the :rsh client command with:
      | app_name | double_containers |
      | options | -b |
    Then the step should fail
    And the output should contain "Error: unknown shorthand flag: 'b'"
        When I run the :rsh client command with:
      | app_name | double_containers |
      | options | --label=hello-openshift |
    Then the step should fail
    And the output should contain "Error: unknown flag: --label"
