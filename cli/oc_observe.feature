Feature: oc observe related tests

  # @author cryan@redhat.com
  # @case_id OCP-10290
  # @bug_id 1388237
  @unix
  Scenario: Negative tests of oc observe
    Given I have a project
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    When I run the :new_app client command with:
      | file | application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    Given I obtain test data file "cli/oc_observe_scripts/known_resources.sh"
    Then the step should succeed
    Given the "known_resources.sh" file is made executable
    And I obtain test data file "cli/oc_observe_scripts/add_to_inventory.sh"
    Then the step should succeed
    Given the "add_to_inventory.sh" file is made executable
    And I obtain test data file "cli/oc_observe_scripts/remove_from_inventory.sh"
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

  # @author cryan@redhat.com
  # @case_id OCP-10289
  @unix
  Scenario: Use oc observe to watch resources with misc flags
    Given I have a project
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    When I run the :new_app client command with:
      | file | application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    Given I wait for the "frontend" dc to appear
    Given I wait for the "database" dc to appear
    When I run the :observe client command with:
      | resource       | dc         |
      | maximum_errors | 1          |
      | oc_opts_end    |            |
      | command        | /bin/false |
    Then the step should fail
    And the output should contain "reached maximum error limit of 1"
    When I run the :observe client command with:
      | resource    | dc    |
      | no_headers  | true  |
      | oc_opts_end |       |
      | command     | touch |
      | _timeout    | 10    |
    Then the output should not contain "Sync"
    When I run the :observe client command with:
      | resource    | dc         |
      | once        | true       |
      | oc_opts_end |            |
      | command     | echo print |
    Then the step should succeed
    And the output should contain:
      | "echo print" <%= project.name %> database |
      | "echo print" <%= project.name %> frontend |
      | Sync ended                                |
    Given I obtain test data file "cli/oc_observe_scripts/known_resources.sh"
    Given I obtain test data file "cli/oc_observe_scripts/remove_from_inventory.sh"
    Given I obtain test data file "cli/oc_observe_scripts/add_to_inventory.sh"
    When I run the :observe client command with:
      | resource      | dc                                                      |
      | resync_period | 10s                                                     |
      | names         | <%= localhost.absolutize("known_resources.sh") %>       |
      | delete        | <%= localhost.absolutize("remove_from_inventory.sh") %> |
      | oc_opts_end   |                                                         |
      | command       | <%= localhost.absolutize("add_to_inventory.sh") %>      |
      | _timeout      | 25                                                      |
    Then the output should match 3 times:
      | ync.*./add_to_inventory.sh <%= project.name %> database |
      | ync.*./add_to_inventory.sh <%= project.name %> frontend |

  # @author xxia@redhat.com
  # @case_id OCP-10288
  Scenario: Use oc observe to watch resource and execute corresponding action upon resource change
    Given I have a project
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    When I run the :new_app client command with:
      | file | application-template-stibuild-without-customize-route.json |
    Then the step should succeed

    Given evaluation of `Gem.win_platform? ? "bat" : "sh"` is stored in the :ext clipboard
    Given I obtain test data file "cli/oc_observe_scripts/known_resources.<%= cb.ext %>"
    Given I obtain test data file "cli/oc_observe_scripts/remove_from_inventory.<%= cb.ext %>"
    Given I obtain test data file "cli/oc_observe_scripts/add_to_inventory.<%= cb.ext %>"
    When I run the :observe background client command with:
      | resource    | service                             |
      | a           | {.spec.clusterIP}                   |
      | names       | known_resources.<%= cb.ext %>       |
      | delete      | remove_from_inventory.<%= cb.ext %> |
      | oc_opts_end |                                     |
      | command     | add_to_inventory.<%= cb.ext %>      |
    Then the step should succeed
    When I run the :label client command with:
      | resource | service  |
      | name     | database |
      | key_val  | lab=any  |
    Then the step should succeed
    Given evaluation of `service("database").ip(user: user)` is stored in the :database_ip clipboard
    And evaluation of `service("frontend").ip(user: user)` is stored in the :frontend_ip clipboard
    When I run the :delete client command with:
      | object_type       | service  |
      | object_name_or_id | database |
    Then the step should succeed
    # Stop oc observe
    When I terminate last background process
    Then the output should match:
      | Sync.*add_to_inventory.*<%= project.name %> database <%= cb.database_ip %>    |
      | Sync.*add_to_inventory.*<%= project.name %> frontend <%= cb.frontend_ip %>    |
      | Updated.*add_to_inventory.*<%= project.name %> database <%= cb.database_ip %> |
      | Deleted.*remove_from_inventory.*<%= project.name %> database                  |

    # Resource change occurs when oc observe is stopped
    When I run the :delete client command with:
      | object_type       | service  |
      | object_name_or_id | frontend |
    Then the step should succeed
    # Run oc observe again
    When I run the :observe background client command with:
      | resource    | service                               |
      | a           | {.spec.clusterIP}                     |
      | names       | ./known_resources.<%= cb.ext %>       |
      | delete      | ./remove_from_inventory.<%= cb.ext %> |
      | oc_opts_end |                                       |
      | command     | ./add_to_inventory.<%= cb.ext %>      |
    Then the step should succeed
    Given I obtain test data file "services/multi-portsvc.json"
    When I run the :create client command with:
      | f | multi-portsvc.json |
    Then the step should succeed
    And I wait for the "multi-portsvc" service to appear
    When I terminate last background process
    Then the output by order should match:
      | Deleted.*remove_from_inventory.*<%= project.name %> frontend |
      | Added.*add_to_inventory.*<%= project.name %> multi-portsvc   |
