Feature: change the policy of user/service account

  # @author anli@redhat.com
  # @case_id 479042
  @smoke
  @admin
  Scenario: Add/Remove a global role
    Given the first user is cluster-admin
    Given I have a project
    When I run the :get client command with:
      | resource   | pod     |
      | namespace  | default |
    And the output should contain:
      | READY  |
    And the output should not contain:
      | cannot |
    When I run the :oadm_remove_cluster_role_from_user admin command with:
      | role_name  | cluster-admin    |
      | user_name  | <%= user.name %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource   | pod              |
      | namespace  | default          |
    And the output should contain:
      | cannot list pods in project "default" |

  # @author xxing@redhat.com
  # @case_id 467925
  Scenario: User can view ,add, remove and modify roleBinding via admin role user
    Given I have a project
    When I run the :describe client command with:
      | resource | policyBindings |
      | name     | :default       |
    Then the output should match:
      | Role:\\s+admin              |
      | Users:\\s+<%= @user.name %> |
    When I run the :oadm_add_role_to_user client command with:
      | role_name | admin            |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | policyBindings |
      | name     | :default       |
    Then the output should match:
      | Role:\\s+admin                                                  |
      | Users:\\s+<%= @user.name %>, <%= user(1, switch: false).name %> |
    When I run the :oadm_remove_role_from_user client command with:
      | role_name | admin            |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | policyBindings |
      | name     | :default       |
    Then the output should match:
      | Role:\\s+admin              |
      | Users:\\s+<%= @user.name %> |

  # @author wyue@redhat.com
  # @case_id 470304
  @admin
  Scenario: Creation of new project roles when allowed by cluster-admin
    ##cluster admin create a project and add another user as admin
    When admin creates a project
    Then the step should succeed
    When I run the :add_role_to_user admin command with:
      | role            |   admin               |
      | user name       |   <%= user.name %>    |
      | n               |   <%= project.name %> |
    Then the step should succeed

    ## switch user to the test project
    When I use the "<%= project.name %>" project
    Then the step should succeed

    ##create role that only could view service
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/policy/projectviewservice.json|
    Then the step should succeed

    ##no policybinding for this role in project
    When I run the :describe client command with:
      | resource | policybindings |
      | name     | :default       |
    Then the output should not contain:
      | viewservices |

    ##admin try to add one user to the project as vs role
    When I run the :oadm_add_role_to_user client command with:
      | role name       |   viewservices    |
      | user name       |   <%= user.name %>    |
      | role namespace  |   <%= project.name %> |
    Then the step should fail
    And the output should contain:
      | not found |

    ## download json filed for role and update the project name
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/policy/policy.json"
    And I replace lines in "policy.json":
      |"namespace": "wsuntest"|"namespace": "<%= project.name %>"|
    Then the step should succeed

    ##cluster admin create a PolicyBinding
    When I run the :create admin command with:
      |f|policy.json|
    Then the step should succeed

    ##create role again after PolicyBinding is created
    When I run the :delete client command with:
      | object type | roles |
      | all |  |
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/policy/projectviewservice.json|
    Then the step should succeed

    ##admin try to add one user to the project as vs role
    When I run the :oadm_add_role_to_user client command with:
      | role name       |   viewservices    |
      | user name       |   <%= user.name %>    |
      | role namespace  |   <%= project.name %> |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id 470312
  @admin
  Scenario: Could get projects for new role which has permission to get projects
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/policy/clustergetproject.json |
    Then the step should succeed
    #clean-up clusterrole
    And I register clean-up steps:
     | I run the :delete admin command with: |
     |   ! f ! https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/policy/clustergetproject.json ! |
     | the step should succeed               |
    When admin creates a project
    Then the step should succeed
    When I run the :oadm_add_role_to_user admin command with:
      | role_name      | viewproject      |
      | user_name      | <%= user.name %> |
      | n              | <%= project.name %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource | project |
    Then the output should match:
      | <%= project.name %>.*Active |
