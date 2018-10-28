Feature: rolebindingrestriction.feature

  # @author yasun@redhat.com
  Scenario Outline: Restrict making a role binding to other user by default through web console
    When I create a new project via web
    Then the step should succeed
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | <tab_name>          |
      | name         | <name>              |
      | role         | <role>              |
      | save_changes | false               |
    Then the step should succeed
    When I perform the :check_restrict_rolebinding_message_on_membership web console action with:
      | project_name    | <%= project.name %> |
      | name            | <name>              |
      | role            | <role>              |
      | output_word     | <output_word>       |
    Then the step should succeed

  # @case_id OCP-13465
  Examples: Restrict making a role binding to other user by default through web console
    | tab_name      | name                         | role  | output_word |
    | Users         | userA                        | view  | User        |
  # @case_id OCP-13410
  Examples: Restrict making a role binding to other group by default through web console
    | tab_name      | name                         | role  | output_word |
    | System Groups | system:serviceaccout:default | edit  | SystemGroup |
    | Groups        | groupA                       | edit  | Group       |


  # @author yasun@redhat.com
  # @case_id OCP-13806
  Scenario: Restrict making a role binding to service account in other projects by default through web console
    When I create a new project via web
    Then the step should succeed
    When I perform the :add_role_on_membership_with_typed_namespace web console action with:
      | project_name  | <%= project.name %> |
      | tab_name      | Service Accounts    |
      | old_namespace | <%= project.name %> |
      | namespace     | openshift           |
      | name          | default             |
      | role          | basic-user          |
      | save_changes  | false               |
    Then the step should succeed
    When I perform the :check_restrict_rolebinding_message_on_membership web console action with:
      | project_name | <%= project.name %> |
      | name         | default             |
      | role         | basic-user          |
      | output_word  | ServiceAccount      |
    Then the step should succeed

