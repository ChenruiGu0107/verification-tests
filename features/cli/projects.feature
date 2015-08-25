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

  # @author pruan@redhat.com
  # @case_id 478983
  @admin
  Scenario: A user could create a project successfully via CLI
    Given I have a project
    When I run the :get client command with:
      | resource | project |
    Then the step should succeed
    Then the output should contain:
      | <%= project.name %> |
      | Active              |
   And I register clean-up steps:
     | I run the :oadm_add_cluster_role_to_group admin command with: |
     |   ! role_name  ! self-provisioner     !                       |
     |   ! group_name ! system:authenticated !                       |
    When I run the :oadm_remove_cluster_role_from_group admin command with:
      | role_name | self-provisioner |
      | group_name | system:authenticated |
    Then the step should succeed
    When I create a new project
    Then the step should fail
    And the output should contain:
      | You may not request a new project via this API |
