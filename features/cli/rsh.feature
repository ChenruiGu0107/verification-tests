Feature: rsh.feature

  # @author cryan@redhat.com
  # @case_id 497699
  Scenario: Check oc rsh for simpler access to a remote shell
    Given I have a project
    Given I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | myapp                |
    Then the step should succeed
    When I run the :rsh client command
    Then the step should fail
    And the output should contain "error: rsh requires a single POD to connect to"
    When I run the :rsh client command with:
      | help ||
    Then the output should contain "Open a remote shell session to a container"
    When I run the :get client command with:
      | pods||
    When I run the :rsh client command with:
      | app_name | myapp |
    Then the step should succeed
