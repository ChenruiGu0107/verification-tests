Feature: containers related features
  # @author pruan@redhat.com
  # @case_id 472856
  Scenario: Choose container to execute command on with '-c' flag
    Given I have a project
    And evaluation of `"doublecontainers"` is stored in the :pod_name clipboard
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/double_containers.json  |
    Then the step should succeed
    And the pod named "doublecontainers" becomes ready
    When I run the :describe client command with:
      | resource | pod       |
      | name | <%= cb.pod_name %> |
    Then the output should contain:
      | Image:		jhou/hello-openshift |
      | Image:		jhou/hello-openshift-fedora |
    When I run the :exec client command with:
      | pod | <%= cb.pod_name %>  |
      #| c | hello-openshift |
      | exec_command | cat  |
      | exec_command_arg |/etc/redhat-release|
    Then the output should contain:
      | CentOS Linux release 7.0.1406 (Core) |
    When I run the :exec client command with:
      | pod | <%= cb.pod_name %>  |
      | c | hello-openshift-fedora |
      | exec_command | cat         |
      | exec_command_arg |/etc/redhat-release|
    Then the output should contain:
      | Fedora release 21 (Twenty One) |