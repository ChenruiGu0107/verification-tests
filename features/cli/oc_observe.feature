Feature: oc observe related tests

  # @author cryan@redhat.com
  # @case_id 535068
  # @bug_id 1388237
  @unix
  Scenario: Negative tests of oc observe
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/oc_observe_scripts/known_resources.sh"
    Then the step should succeed
    Given the "known_resources.sh" file is made executable
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/oc_observe_scripts/add_to_inventory.sh"
    Then the step should succeed
    Given the "add_to_inventory.sh" file is made executable
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/oc_observe_scripts/remove_from_inventory.sh"
    Then the step should succeed
    Given the "remove_from_inventory.sh" file is made executable
    When I run the :observe client command with:
      | resource    | pods                       |
      | names       | ./not-exist.sh             |
      | delete      | ./remove_from_inventory.sh |
      | oc_opts_end |                            |
      | command     | ./add_to_inventory.sh      |
    Then the step should fail
    And the output should contain "no such file or directory"
    Given the "known_resources.sh" file is appended with the following lines:
      |                       |
      | cat not-existing-file |
    When I run the :observe client command with:
      | resource    | pods                       |
      | names       | ./known_resources.sh       |
      | delete      | ./remove_from_inventory.sh |
      | oc_opts_end |                            |
      | command     | ./add_to_inventory.sh      |
    Then the step should fail
    And the output should contain "cat: not-existing-file: No such file or directory"
    When I run the :observe client command with:
      | resource    | pods                       |
      | names       | ./known_resources.sh       |
      | oc_opts_end |                            |
      | command     | ./add_to_inventory.sh      |
    Then the step should fail
    And the output should contain "--delete and --names must both be specified"
    When I run the :observe client command with:
      | resource    | svc                        |
      | delete      | ./remove_from_inventory.sh |
      | oc_opts_end |                            |
      | command     | echo print                 |
      | _timeout    | 30                         |
    Then the step should fail
    And the output should contain:
      | --names command to ensure you don't miss deletions |
      | Sync started                                       |
