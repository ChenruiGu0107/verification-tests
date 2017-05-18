Feature: rolebindingrestriction.feature
  # @author zhaliu@redhat.com
  Scenario Outline: Restrict making a role binding to user except project admin by default
    Given I have a project
    When I run the :get client command with:
      | resource      | rolebindingrestriction   |
      | resource_name | match-project-admin-user |
      | o             | json                     |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["userrestriction"]["users"].include? user.name

    When I run the :policy_add_role_to_user client command with:
      | role      | edit       |
      | user_name | <username> |
    Then the step should <result>
    And the output should match:
      | <output> |
    Examples:
      | username         | output                                               | result  |
      | userA            | .*"edit".*forbidden:.*"userA".*"<%= project.name %>" | fail    | # @case_id OCP-13120
      | <%= user.name %> | role "edit" added: "<%= user.name %>"                | succeed | # @case_id OCP-13146

  # @author zhaliu@redhat.com
  Scenario Outline: Restrict making a role binding to service accounts except in own project by default
    Given I have a project
    When I run the :get client command with:
      | resource      | rolebindingrestriction     |
      | resource_name | match-own-service-accounts |
      | o             | json                       |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["serviceaccountrestriction"]["namespaces"].include? project.name

    When I run the :policy_add_role_to_user client command with:
      | role              | view             |
      | serviceaccountraw | <serviceaccount> |
    Then the step should <result>
    And the output should match:
      | <output> |
    Examples:
      | serviceaccount                                     | output                                                    | result  |
      | system:serviceaccount:openshift:deployer           | .*"view".*forbidden:.*".*deployer".*"<%= project.name %>" | fail    | # @case_id OCP-13805
      | system:serviceaccount:<%= project.name %>:deployer | role "view" added: ".*deployer"                           | succeed | # @case_id OCP-13115


  # @author zhaliu@redhat.com
  Scenario Outline: Restrict making a role binding to groups except system group built in own project by default
    Given I have a project
    When I run the :get client command with:
      | resource      | rolebindingrestriction          |
      | resource_name | match-own-service-account-group |
      | o             | json                            |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["grouprestriction"]["groups"].include? "system:serviceaccounts:#{project.name}"

    When I run the :policy_add_role_to_group client command with:
      | role       | view         |
      | group_name | <group_name> |
    Then the step should <result>
    And the output should match:
      | <output> |
    # @case_id OCP-13121
    Examples: Restrict making a role binding to the groups
      | group_name                       | output                                                                          | result |
      | groupA                           | .*"view".*forbidden:.*"groupA".*"<%= project.name %>"                           | fail   |
      | system:serviceaccounts           | .*"view".*forbidden:.*"system:serviceaccounts".*"<%= project.name %>"           | fail   |
      | system:serviceaccounts:openshift | .*"view".*forbidden:.*"system:serviceaccounts:openshift".*"<%= project.name %>" | fail   |
    # @case_id OCP-13795
    Examples: Allow to make a role binding to the system service account group
      | group_name                                 | output                                                          | result  |
      | system:serviceaccounts:<%= project.name %> | role "view" added: "system:serviceaccounts:<%= project.name %>" | succeed |

  # @author yasun@redhat.com
  Scenario Outline: Restrict making a role binding to other user by default through web console
    When I create a new project via web
    Then the step should succeed
    When I perform the :add_role_on_membership web console action with:
      | project_name | <%= project.name %> |
      | tab_name     | <tab_name>          |
      | name         | <name>              |
      | role         | <role>              |
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
    Then the step should succeed
    When I perform the :check_restrict_rolebinding_message_on_membership web console action with:
      | project_name | <%= project.name %> |
      | name         | default             |
      | role         | basic-user          |
      | output_word  | ServiceAccount      |
    Then the step should succeed
