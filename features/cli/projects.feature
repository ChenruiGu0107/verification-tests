Feature: projects related features via cli
  # @author pruan@redhat.com
  # @case_id 479238
  Scenario: There is annotation instead of 'Display name' for project info
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
      | display_name | <%= cb.proj_name %> |
    Then the step should succeed
    And I run the :get client command with:
      | resource | project |
      |  o       | json    |
    Then the output should contain:
      | display-name": "<%= cb.proj_name %>" |
    And the output should not contain:
      | displayName |

  # @author pruan@redhat.com
  # @case_id 494759
  Scenario: Could not create the project with invalid name via CLI
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | new-project  |
    Then the step should fail
    And the output should contain:
      | Create a new project for yourself |
      | oc new-project NAME [--display-name=DISPLAYNAME] [--description=DESCRIPTION] [options] |
      | error: must have exactly one argument                                                  |
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    Given a 64 character random string of type :dns is stored into the :proj_name_3 clipboard
    And evaluation of `"xyz-"` is stored in the :proj_name_4 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should fail
    And the output should contain:
      | project "<%= cb.proj_name %>" already exists |
    When I run the :new_project client command with:
      | project_name | q |
    Then the step should fail
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name_3 %> |
    Then the step should fail
    When I run the :new_project client command with:
      | project_name | ALLUPERCASE |
    Then the step should fail
    Then the output should contain:
      | invalid value 'ALLUPERCASE': must be a DNS label (at most 63 characters, matching regex [a-z0-9]([-a-z0-9]*[a-z0-9])?): e.g. "my-name |
    When I run the :new_project client command with:
      | project_name | -abc |
    Then the step should fail
    And the output should contain:
      | unknown shorthand flag: 'a' in -abc |
    When I run the :new_project client command with:
      | project_name | xyz- |
    Then the step should fail
    And the output should contain:
      | invalid value 'xyz-': must be a DNS label (at most 63 characters, matching regex [a-z0-9]([-a-z0-9]*[a-z0-9])?): e.g. "my-name" |

    When I run the :new_project client command with:
      | project_name | $pe#cial& |
    Then the step should fail
    And the output should contain:
      | invalid value '$pe#cial&': must be a DNS label (at most 63 characters, matching regex [a-z0-9]([-a-z0-9]*[a-z0-9])?): e.g. "my-name" |
