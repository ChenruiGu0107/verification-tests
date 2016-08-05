Feature:policy related features on web console

  # @author xiaocwan@redhat.com
  # @case_id 476296
  Scenario: All the users in the deleted project should be removed
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role            | edit                               |
      | user name       | <%= user(1, switch: false).name %> |
      | n               | <%= project.name %>                |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role            | view                               |
      | user name       | <%= user(2, switch: false).name %> |
      | n               | <%= project.name %>                |
    Then the step should succeed

    When I switch to the second user
    And I run the :get client command with:
      | resource | project  |
    Then the step should succeed
    And the output should contain:
      | <%= project.name %> |
    When I switch to the third user
    And I run the :get client command with:
      | resource | project  |
    Then the step should succeed
    And the output should contain:
      | <%= project.name %> |

    Given I switch to the first user
    When I perform the :check_specific_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    Given I switch to the second user
    When I perform the :check_specific_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    Given I switch to the third user
    When I perform the :check_specific_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    Given I switch to the first user
    And the project is deleted
    When I run the :get client command with:
      | resource | project  |
    Then the step should succeed
    And the output should not contain:
      | <%= project.name %> |
    When I switch to the second user
    And I run the :get client command with:
      | resource | project  |
    Then the step should succeed
    And the output should not contain:
      | <%= project.name %> |
    When I switch to the third user
    And I run the :get client command with:
      | resource | project  |
    Then the step should succeed
    And the output should not contain:
      | <%= project.name %> |

  # @author xiaocwan@redhat.com
  # @case_id 478982
  @admin
  @destructive
  Scenario: Cluster-admin can completely disable access to request project.
    Given cluster roles are restored after scenario
    Given as admin I replace resource "clusterrole" named "basic-user":
      | projectrequests\n  verbs:\n  - list\n | projectrequests\n  verbs:\n |
    Then the step should succeed
    When I run the :describe admin command with:
      | resource         | clusterrole     |
      | name             | basic-user      |
    Then the output should not match:
      | list.*projectrequests              |
    Given I login via web console
    When I get the html of the web page
    Then the output should match:
      | cluster admin can create a project for you    |
    ## bug 1262696
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>        |
      | token    | <%= user.get_bearer_token.token %> |
      | insecure | true                               |
      | config   | new.config                         |
    Then the step should succeed
    And the output should not contain:
      | oc new-project                                |