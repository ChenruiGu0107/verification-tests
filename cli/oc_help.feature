Feature: oc related features
  # @author pruan@redhat.com
  # @case_id OCP-12362
  Scenario: Check the help page of oc edit
    When I run the :edit client command with:
      | help | true |
    Then the output should contain:
      | Edit a resource from the default editor |
      | The edit command allows you to directly edit any API resource you can retrieve via the |
      | command line tools. It will open the editor defined by your OC_EDITOR, GIT_EDITOR,     |
      | or EDITOR environment variables, or fall back to 'vi' for Linux or 'notepad' for Windows. |
      | Usage:                                                                                    |
      | oc edit (RESOURCE/NAME \| -f FILENAME) [options] |

  # @author cryan@redhat.com
  # @case_id OCP-9577
  Scenario: Check --list/-L option for new-app
    When I run the :new_app client command with:
      |help||
    Then the output should contain:
      | oc new-app --list |
      | -L, --list=false  |

  # @author xxia@redhat.com
  Scenario Outline: Use explain to see detailed documentation of resources
    When I run the :explain client command with:
      | _tool     | <tool>    |
      | resource  | po        |
    Then the step should succeed
    And the output should contain:
      | DESCRIPTION |
      | Pod is a collection of containers |
      | FIELDS      |
      | apiVersion  |
    When I run the :explain client command with:
      | _tool     | <tool>               |
      | resource  | pods.spec.containers |
    Then the step should succeed
    And the output should contain:
      | RESOURCE: containers |
      | DESCRIPTION |
      | List of containers belonging to the pod |
      | FIELDS      |
      | securityContext  |
    When I run the :explain client command with:
      | _tool     | <tool>    |
      | resource  | svc       |
    Then the step should succeed
    When I run the :explain client command with:
      | _tool     | <tool>    |
      | resource  | pvc       |
    Then the step should succeed
    When I run the :explain client command with:
      | _tool     | <tool>           |
      | resource  | rc.spec.selector |
    Then the step should succeed

    When I run the :explain client command with:
      | _tool     | <tool>    |
      | resource  | dc        |
    Then the step should succeed
    # Check the links in the oc explain output are valid
    # The links look like https://git.k8s.io/community/contributors/devel/api-conventions.md#resources
    When I open web server via the "<%= URI.extract(@result[:response], %w{http https})[0] %>" url
    Then the step should succeed
    When I run the :explain client command with:
      | _tool     | <tool>  |
      | resource  | no-this |
    Then the step should fail
    When I run the :explain client command with:
      | _tool     | <tool>  |
      | resource  | rc,no   |
    Then the step should fail
    And the output should contain:
      | rc,no |

    Examples:
      | tool     |
      | oc       | # @case_id OCP-11202
      | kubectl  | # @case_id OCP-21115

  # @author xiaocwan@redhat.com
  # @case_id OCP-11836
  Scenario: oc help command to guide user to get help info for subcommands
    When I run the :help client command with:
      | command_name       | set             |
    Then the step should succeed
    And the output should match:
      | Configure application resources      |
      | oc set COMMAND                       |
      | route-backends                       |
      | Use.*oc set <command> --help.*for    |
      | Use.*oc options.*for                 |
    When I run the :help client command with:
      | command_name       | set             |
      | command_name       | route-backends  |
    Then the step should succeed
    And the output should match:
      | oc set route-backends ROUTENAME      |
      | oc set route-backends web            |
      | Use.*oc options.*for                 |
