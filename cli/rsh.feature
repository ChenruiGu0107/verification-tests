Feature: rsh.feature

  # @author pruan@redhat.com
  # @case_id OCP-11154
  Scenario: Check oc rsh with invalid options
    Given I have a project
    Given I obtain test data file "pods/pod_with_two_containers.json"
    When I run the :create client command with:
      | f | pod_with_two_containers.json |
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

  # @author xiaocwan@redhat.com
  # @case_id OCP-10510
  Scenario: Improved CLI command guide - negative
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg       | rsh              |
    Then the step should fail
    And the output should match:
      | [Ee]rror.*[Pp]od             |
      | oc rsh -h.*help and examples |

    Given I have a project
    When I run the :run client command with:
      | name      | dc                    |
      | image     | aosqe/hello-openshift |
    Then the step should succeed
    Given a pod becomes ready with labels:
      |  deployment=dc-1 |
    # correct order  "oc  rsh  --no-tty pod/dc-1-mtc9m  ls"
    When I run the :rsh client command with:
      | no_tty     |  true               |
      | pod        | <%= pod.name %>     |
      | command    |  ls                 |
    Then the step should succeed
    And the output should contain "home"
    # incorrect order "oc rsh pod/dc-1-iyc7g --no-tty ls"
    # remove to check output for different between 3.4 and 3.5, only to check failed status
    # 3.4 "env: can't execute '--no-tty': No such file or directory"
    # 3.5 "...executable file not found in $PATH"
    When I run the :rsh client command with:
      | pod        | <%= pod.name %>     |
      | command    | --no-tty            |
      | command    | ls                  |
    Then the step should fail
