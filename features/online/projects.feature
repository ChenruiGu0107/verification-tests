Feature: ONLY ONLINE Projects related feature's scripts in this file

  # @author etrott@redhat.com
  # @case_id 534615
  Scenario: User should be able to switch projects via CLI
    Given I create a new project
    Then I switch to the second user
    Given I create a new project
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                              |
      | user_name | <%= user(0, switch: false).name %> |
      | n         | <%= project.name %>                |
    Then the step should succeed
    Given I switch to the first user
    When I run the :project client command with:
    | project_name | <%= project(0, switch: false).name %> |
    Then the output should contain:
    | project "<%= project(0, switch: false).name %>" on server |
    When I run the :project client command with:
      | project_name | <%= project.name %> |
    Then the output should contain:
      | project "<%= project.name %>" on server |
    And I run the :project client command with:
      | project_name | notaccessible |
    Then the output should contain:
      | error: You are not a member of project "notaccessible". |
      | Your projects are:                                      |
      | * <%= project.name %>                                   |
      | * <%= project(1).name %>                                |

  # @author etrott@redhat.com
  # @case_id 534614
  Scenario: Should use and show the existing projects after the user login
    Given I create a new project
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>         |
      | token    | <%= user.get_bearer_token.token %>  |
      | config   | new_config_file                     |
      | skip_tls_verify | true                         |
    Then the step should succeed
    And the output should contain:
      | You have one project on this server: "<%= project.name %>" |
      | Using project "<%= project.name %>". |
    Then I switch to the second user
    And I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>        |
      | token    | <%= user.get_bearer_token.token %> |
      | config   | new_config_file                    |
      | skip_tls_verify | true                         |
    Then the step should succeed
    And the output should contain:
      | You don't have any projects. You can try to create a new project |
    When I run the :config_view client command with:
      | config   | new_config_file |
    Then the step should succeed
    And the output should match:
      | name: .+/.+/<%= user(0, switch: false).name %> |
      | current-context: /.+/<%= user.name %>          |
    Given I create a new project
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                              |
      | user_name | <%= user(0, switch: false).name %> |
      | n         | <%= project.name %>                |
    Then the step should succeed
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>           |
      | token    | <%= user(0).get_bearer_token.token %> |
    Then the step should succeed
    And the output should contain:
      | You have access to the following projects and can switch between them with 'oc project <projectname>': |
      | * <%= @projects[0].name %>                                                                             |
      | <%= @projects[1].name %>                                                                               |
