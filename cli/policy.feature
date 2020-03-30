Feature: change the policy of user/service account

  # @author anli@redhat.com
  # @case_id OCP-10609
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
    When I run the :oadm_policy_remove_cluster_role_from_user admin command with:
      | role_name  | cluster-admin    |
      | user_name  | <%= user.name %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource   | pod              |
      | namespace  | default          |
    And the output should contain:
      | cannot list pods in project "default" |

  # @author wyue@redhat.com
  # @case_id OCP-12238
  @admin
  Scenario: Creation of new project roles when allowed by cluster-admin
    ##cluster admin create a project and add another user as admin
    When admin creates a project
    Then the step should succeed
    When I run the :policy_add_role_to_user admin command with:
      | role            |   admin               |
      | user name       |   <%= user.name %>    |
      | n               |   <%= project.name %> |
    Then the step should succeed

    ## switch user to the test project
    When I use the "<%= project.name %>" project
    Then the step should succeed

    ##create role that only could view service
    When I run the :create client command with:
      |f|<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/projectviewservice.json|
    Then the step should succeed

    ##no policybinding for this role in project
    When I run the :get client command with:
      | resource | rolebinding |
    Then the output should not contain:
      | viewservices |

    ##admin try to add one user to the project as vs role
    When I run the :oadm_policy_add_role_to_user admin command with:
      | role name       |   viewservices    |
      | user name       |   <%= user.name %>    |
      | role namespace  |   <%= project.name %> |
    Then the step should fail
    And the output should contain:
      | not found |

    ## download json filed for role and update the project name
    When I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/policy.json"
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
      |f|<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/projectviewservice.json|
    Then the step should succeed

    ##admin try to add one user to the project as vs role
    When I run the :oadm_policy_add_role_to_user client command with:
      | role name       |   viewservices    |
      | user name       |   <%= user.name %>    |
      | role namespace  |   <%= project.name %> |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-12634
  @admin
  Scenario: [origin_platformexp_239] The page should have error notification popup when got error during archiving resources of project from server
    Given admin creates a project

    When I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/getlistwatch_projNamespace.json"
    And I replace lines in "getlistwatch_projNamespace.json":
      |   vsp          |       <%= project.name %>            |
    Then the step should succeed
    When I run the :create admin command with:
      | f               | getlistwatch_projNamespace.json     |
    Then the step should succeed
    And the output should contain:
      | created |
    And I register clean-up steps:
      | I run the :delete admin command with:                 |
      | ! object_type       !        clusterrole            ! |
      | ! object_name_or_id !   <%= project.name %>         ! |
      | the step should succeed                               |

    Given cluster role "<%= project.name %>" is added to the "first" user
    When I perform the :check_error_list_project_resources web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-12354
  @admin
  Scenario: [origin_platformexp_386][origin_platformexp_279]Both global policy bindings and project policy bindings work
    Given I have a project
    When I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/policy.json"
    And I replace lines in "policy.json":
      | wsuntest | <%= project.name %> |
    Then the step should succeed
    And I run the :create admin command with:
      | f        | policy.json         |
    Then the step should succeed
    And the output should contain:
      | policybinding |

    When I switch to the first user
    And I run the :create client command with:
      | f        | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/deleteservices.json |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | role |
    When I run the :policy_add_role_to_user admin command with:
      | role      |   view                               |
      | user name |   <%= user(1,switch: false).name %>  |
    Then the step should succeed
    And I register clean-up steps:
      | I run the :policy_remove_role_from_user admin command with: |
      |! role      ! view !          |
      |! user name !  <%= user(1,switch: false).name %>! |
      | the step should succeed                          |

    When I run the :policy_add_role_to_user client command with:
      | role            |   deleteservices                  |
      | user name       | <%= user(1,switch: false).name %> |
      | role_namespace  | <%= project.name %>               |
    Then the step should succeed

    When I switch to the second user
    And I run the :get client command with:
      | resource          | service |
      | n                 | default |
    Then the step should succeed
    When I run the :policy_who_can admin command with:
      | verb                   | delete   |
      | resource               | services |
      | n           | <%= project.name %> |
    Then the output should contain:
      | <%= user(1).name %> |

  # @author xiaocwan@redhat.com
  # @case_id OCP-12380
  @admin
  Scenario: Project bindings only work against the intended project
    Given a 5 characters random string of type :dns is stored into the :project_1 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.project_1 %> |
    Then the step should succeed

    When I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/policy.json"
    And I replace lines in "policy.json":
      | wsuntest | <%= cb.project_1 %> |
    Then the step should succeed
    And I run the :create admin command with:
      | f        | policy.json         |
    Then the step should succeed

    When I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/deleteservices.json"
    And I replace lines in "deleteservices.json":
      | deleteservices | <%= cb.project_1 %>     |
      | "delete"   | "watch","list","get"        |
      | "services" | "resourcegroup:exposedkube" |
    And I run the :create client command with:
      | f        | deleteservices.json |
      | n        | <%= cb.project_1 %> |
    Then the step should succeed
    And the output should contain:
      | role |

    When I run the :policy_add_role_to_user client command with:
      | role            |   <%= cb.project_1 %>             |
      | user name       | <%= user(1,switch: false).name %> |
      | role_namespace  | <%= cb.project_1 %>               |
    Then the step should succeed

    Given a 5 characters random string of type :dns is stored into the :project_2 clipboard
    When I run the :new_project admin command with:
      | project_name | <%= cb.project_2 %> |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role            |   <%= cb.project_2 %>                  |
      | user name       | <%= user(2,switch: false).name %> |
      | role_namespace  | <%= cb.project_2 %>               |
    Then the step should fail

  # @author xiaocwan@redhat.com
  # @case_id OCP-11904
  @admin
  Scenario: [origin_platformexp_340]The builder service account only has get/update access to image streams in its own project
    Given a 5 characters random string of type :dns is stored into the :proj1 clipboard
    When I run the :new_project client command with:
      | project_name  | <%= cb.proj1 %>      |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    Then the step should succeed
    When I run the :policy_who_can client command with:
      | verb     |  get                        |
      | resource |  imagestreams/layers        |
    Then the step should succeed
    And the output should contain:
      | system:serviceaccount:<%= cb.proj1 %>:builder  |
      | system:serviceaccounts:<%= cb.proj1 %>         |
    When I run the :policy_who_can client command with:
      | verb     |  update                     |
      | resource |  imagestreams/layers        |
    Then the step should succeed
    And the output should contain:
      | system:serviceaccount:<%= cb.proj1 %>:builder  |
    When I create a new project
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    Then the step should succeed
    When I run the :policy_who_can client command with:
      | verb     |  get                        |
      | resource |  imagestreams/layers        |
    Then the step should succeed
    And the output should not contain:
      | system:serviceaccount:<%= cb.proj1 %>:builder  |
      | system:serviceaccounts:<%= cb.proj1 %>         |
    When I run the :policy_who_can client command with:
      | verb     |  update                     |
      | resource |  imagestreams/layers        |
    Then the step should succeed
    And the output should not contain:
      | system:serviceaccount:<%= cb.proj1 %>:builder  |
    When I run the :oadm_policy_who_can admin command with:
      | verb     |  get                        |
      | resource |  imagestreams               |
      | all_namespaces | false                 |
    Then the step should succeed
    And the output should contain:
      | Namespace: default  |
    When I run the :oadm_policy_who_can admin command with:
      | verb     |  get                        |
      | resource |  imagestreams               |
      | all_namespaces | true                  |
    Then the step should succeed
    And the output should contain:
      | Namespace: <all>  |

  # @author anli@redhat.com
  # @case_id OCP-12119
  @admin
  Scenario: Cluster admin could delegate the administration of a project to a project admin
    Given a 5 characters random string of type :dns is stored into the :proj1 clipboard
    When admin creates a project with:
      | project_name | <%= cb.proj1 %> |
      | admin | <%= user.name %> |
    Then the step should succeed
    Given I use the "<%= cb.proj1 %>" project
    When I run the :policy_add_role_to_user client command with:
      | role  | view     |
      | user_name |  <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role  | edit     |
      | user_name |  <%= user(2, switch: false).name %> |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role  | admin     |
      | user_name |  <%= user(1, switch: false).name %> |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-10802
  Scenario: Check registry-viewer permission
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role        | registry-viewer      |
      | user_name   |  <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :policy_who_can client command with:
      | verb         | get                 |
      | resource     | imagestreamimages   |
    Then the output should contain:
      | <%= user(1).name %> |
    When I run the :policy_who_can client command with:
      | verb         | list                |
      | resource     | imagestreamimports  |
    Then the output should contain:
      | <%= user(1).name %> |
    When I run the :policy_who_can client command with:
      | verb         | get                 |
      | resource     | imagestreamtags     |
    Then the output should contain:
      | <%= user(1).name %> |
    When I run the :create client command with:
      | f |https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json|
    Then the step should fail
    When I run the :policy_add_role_to_user client command with:
      | role        | registry-viewer      |
      | user_name   |  <%= user(2, switch: false).name %> |
    Then the step should fail

  # @author xiaocwan@redhat.com
  # @case_id OCP-11569
  Scenario: Check the registry-editor permission
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role        |  registry-editor     |
      | user_name   |  <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :policy_who_can client command with:
      | verb         | create              |
      | resource     | imagestreamimages   |
    Then the output should contain:
      | <%= user(1).name %> |
    When I run the :policy_who_can client command with:
      | verb         | delete              |
      | resource     | imagestreamimports  |
    Then the output should contain:
      | <%= user(1).name %> |
    When I run the :policy_who_can client command with:
      | verb         | deletecollection    |
      | resource     | imagestreammappings |
    Then the output should contain:
      | <%= user(1).name %> |
    When I run the :policy_who_can client command with:
      | verb         | list                 |
      | resource     | imagestreams/secrets |
    Then the output should contain:
      | <%= user(1).name %> |
    When I run the :policy_who_can client command with:
      | verb         | patch               |
      | resource     | imagestreamtags     |
    Then the output should contain:
      | <%= user(1).name %> |
    When I run the :policy_who_can client command with:
      | verb         | get                 |
      | resource     | imagestreams/layers |
    Then the output should contain:
      | <%= user(1).name %> |
    When I run the :create client command with:
      | f |https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json|
    Then the step should fail
    When I run the :policy_add_role_to_user client command with:
      | role        | registry-viewer      |
      | user_name   |  <%= user(2, switch: false).name %> |
    Then the step should fail

  # @author yinzhou@redhat.com
  # @case_id OCP-11252
  Scenario: Check the registry-admin permission
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role         |   registry-admin  |
      | user name    | <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I switch to the second user
    When I run the :policy_can_i client command with:
      | verb         | create              |
      | resource     | imagestreamimages   |
      | n            | <%= project.name %> |
    Then the output should contain:
      | yes |
    When I run the :policy_can_i client command with:
      | verb         | create              |
      | resource     | imagestreamimports  |
      | n            | <%= project.name %> |
    Then the output should contain:
      | yes |
    When I run the :policy_can_i client command with:
      | verb         | list                |
      | resource     | imagestreamimports  |
      | n            | <%= project.name %> |
    Then the output should contain:
      | no |
    When I run the :policy_can_i client command with:
      | verb         | get                 |
      | resource     | imagestreamtags     |
      | n            | <%= project.name %> |
    Then the output should contain:
      | yes |
    When I run the :policy_can_i client command with:
      | verb         | update              |
      | resource     | imagestreams/layers |
      | n            | <%= project.name %> |
    Then the output should contain:
      | yes |
    Given I switch to the first user
    When I run the :describe client command with:
      | resource | rolebinding |
    Then the step should succeed
    And the output should match:
      | Role:\\s+/registry-admin |
      | Users:\\s+<%= user(1, switch: false).name %> |

  # @author pruan@redhat.com
  # @case_id OCP-12195
  @admin
  Scenario: User should have privileges to access project when add its group as a project role
    Given a 5 characters random string of type :dns is stored into the :group_name clipboard
    When admin creates a project
    Then the step should succeed
    And system verification steps are used:
    """
    When I run the :get admin command with:
      | resource      | users            |
      | resource_name | <%= user.name %> |
      | template      | {{.groups}}      |
    Then the step should succeed
    And the output should match "<no value>|\[\]"
    """
    Given I run the :oadm_groups_new admin command with:
      | group_name | <%= cb.group_name %> |
    Then the step should succeed
    Given admin ensures "<%= cb.group_name %>" groups is deleted after scenario
    Given I run the :oadm_groups_add_users admin command with:
      | group_name | <%= cb.group_name %> |
      | user_name  | <%= user.name %>     |
    When I run the :policy_add_role_to_group admin command with:
      | role       | view                 |
      | group_name | <%= cb.group_name %> |
      | n | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    And I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should match:
      | <%= project.name%> |
      | Active             |
    """

  # @author chuyu@redhat.com
  # @case_id OCP-13095
  @admin
  Scenario: Add add-cluster-role-to-user support for -z
    Given I have a project
    Given I find a bearer token of the system:serviceaccount:<%= project.name %>:default service account
    Given I switch to the system:serviceaccount:<%= project.name %>:default service account
    Given I run the :get client command with:
      | resource | nodes |
    Then the step should fail
    Given I run the :oadm_policy_add_cluster_role_to_user admin command with:
      | role_name | system:node-reader  |
      | z         | default             |
      | n         | <%= project.name %> |
    Then the step should succeed
    And I register clean-up steps:
      """
      Given I run the :oadm_policy_remove_cluster_role_from_user admin command with:
        | role_name | system:node-reader  |
        | z         | default             |
        | n         | <%= project.name %> |
      Then the step should succeed
      """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | nodes |
    Then the step should succeed
    """

  # @author yinzhou@redhat.com
  # @case_id OCP-11697
  @admin
  Scenario: Delete role though rolebinding existed for the role
    Given I switch to cluster admin pseudo user
    Given admin ensures "tc467927" cluster_role is deleted after scenario
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/tc467927/role.json |
    Then the step should succeed
    Given admin waits for the "tc467927" clusterrole to appear
    And cluster role "tc467927" is added to the "first" user
    And I run the :get client command with:
      |resource | clusterrolebinding |
      | o       | wide               |
    And the output should match:
      | (ClusterRole\/)?tc467927.*(<%= user(0, switch: false).name %>)? |

  # @author chuyu@redhat.com
  # @case_id OCP-13480
  @admin
  @destructive
  Scenario: Allow to make a role binding to a service account if no rolebindingrestriction exists
    Given I have a project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        openshift.io/RestrictSubjectBindings:
          configuration:
            apiversion: v1
            kind: DefaultAdmissionConfig
    """
    Given I run the :policy_add_role_to_user client command with:
      | role           | view                |
      | serviceaccount | deployer            |
      | n              | <%= project.name %> |
    Then the step should succeed
    Given I run the :get client command with:
      | resource | rolebinding         |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should match:
      | .*view.*/view.*deployer |

  # @author chuyu@redhat.com
  # @case_id OCP-13479
  @admin
  @destructive
  Scenario: Allow to make a role binding to a group matched one rolebindingrestriction
    Given I have a project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        openshift.io/RestrictSubjectBindings:
          configuration:
            apiversion: v1
            kind: DefaultAdmissionConfig
    """
    And the master service is restarted on all master nodes
    When I run the :new_app client command with:
      | template | postgresql-persistent |
    Then the step should succeed
    Given admin ensures "groups-rolebindingrestriction" group is deleted after scenario
    Given I run the :oadm_groups_new admin command with:
      | group_name | groups-rolebindingrestriction |
      | user_name  | <%= user(1).name  %>          |
    Then the step should succeed
    Given I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml |
      | n | <%= project.name %>                                                                                                           |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should fail
    Given I switch to the first user
    And I run the :policy_add_role_to_group client command with:
      | role       | view                          |
      | group_name | groups-rolebindingrestriction |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-13478
  @admin
  @destructive
  Scenario: Allow to make a role binding to a user matched one rolebindingrestriction
    Given I have a project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        openshift.io/RestrictSubjectBindings:
          configuration:
            apiversion: v1
            kind: DefaultAdmissionConfig
    """
    And the master service is restarted on all master nodes
    When I run the :new_app client command with:
      | template | postgresql-persistent |
    Then the step should succeed
    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml"
    And I replace lines in "rolebindingrestriction.yaml":
      | name: match-groups                        | name: match-users                              |
      | grouprestriction:                         | userrestriction:                               |
      | groups: ["groups-rolebindingrestriction"] | users: ["<%= user(1, switch: false).name  %>"] |
    Given I run the :create admin command with:
      | f | rolebindingrestriction.yaml |
      | n | <%= project.name %>         |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should fail
    Given I switch to the first user
    And I run the :policy_add_role_to_user client command with:
      | role      | view                                |
      | user_name | <%= user(1, switch: false).name  %> |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-13477
  @admin
  @destructive
  Scenario: Allow to make a role binding to a group if no rolebindingrestriction exists
    Given I have a project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        openshift.io/RestrictSubjectBindings:
          configuration:
            apiversion: v1
            kind: DefaultAdmissionConfig
    """
    And the master service is restarted on all master nodes
    When I run the :new_app client command with:
      | template | postgresql-persistent |
    Then the step should succeed
    Given admin ensures "groups-rolebindingrestriction" group is deleted after scenario
    Given I run the :oadm_groups_new admin command with:
      | group_name | groups-rolebindingrestriction       |
      | user_name  | <%= user(1, switch: false).name  %> |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should fail
    Given I switch to the first user
    And I run the :policy_add_role_to_group client command with:
      | role       | view                          |
      | group_name | groups-rolebindingrestriction |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-13476
  @admin
  @destructive
  Scenario: Allow to make a role binding to a user if no rolebindingrestriction exists
    Given I have a project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        openshift.io/RestrictSubjectBindings:
          configuration:
            apiversion: v1
            kind: DefaultAdmissionConfig
    """
    And the master service is restarted on all master nodes
    When I run the :new_app client command with:
      | template | postgresql-persistent |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should fail
    Given I switch to the first user
    And I run the :policy_add_role_to_user client command with:
      | role      | view                                |
      | user_name | <%= user(1, switch: false).name  %> |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-13475
  @admin
  @destructive
  Scenario: Restrict making a role binding to a user not matched any rolebindingrestriction
    Given I have a project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        openshift.io/RestrictSubjectBindings:
          configuration:
            apiversion: v1
            kind: DefaultAdmissionConfig
    """
    And the master service is restarted on all master nodes
    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml"
    And I replace lines in "rolebindingrestriction.yaml":
      | name: match-groups                        | name: match-users |
      | grouprestriction:                         | userrestriction:  |
      | groups: ["groups-rolebindingrestriction"] | users: [""]       |
    Given I run the :create admin command with:
      | f | rolebindingrestriction.yaml |
      | n | <%= project.name %>         |
    Then the step should succeed
    And I run the :policy_add_role_to_user client command with:
      | role      | view                                |
      | user_name | <%= user(1, switch: false).name  %> |
    Then the step should fail
    And the output should match:
      | rolebindings.* "view" is forbidden |

  # @author chuyu@redhat.com
  # @case_id OCP-13474
  @admin
  @destructive
  Scenario: Restrict making a role binding to a group not matched any rolebindingrestriction
    Given I have a project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        openshift.io/RestrictSubjectBindings:
          configuration:
            apiversion: v1
            kind: DefaultAdmissionConfig
    """
    And the master service is restarted on all master nodes
    Given admin ensures "groups-rolebindingrestriction" group is deleted after scenario
    Given I run the :oadm_groups_new admin command with:
       | group_name | groups-rolebindingrestriction       |
       | user_name  | <%= user(1, switch: false).name  %> |
    Then the step should succeed
    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml"
    And I replace lines in "rolebindingrestriction.yaml":
      | groups: ["groups-rolebindingrestriction"] | groups: [""] |
    Given I run the :create admin command with:
      | f | rolebindingrestriction.yaml |
      | n | <%= project.name %>         |
    Then the step should succeed
    And I run the :policy_add_role_to_group client command with:
      | role       | view                          |
      | group_name | groups-rolebindingrestriction |
    Then the step should fail
    And the output should match:
      | rolebindings.* "view" is forbidden |

  # @author chuyu@redhat.com
  # @case_id OCP-13473
  @admin
  @destructive
  Scenario: Restrict making a role binding to a service account not matched any rolebindingrestriction
    Given I have a project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        openshift.io/RestrictSubjectBindings:
          configuration:
            apiversion: v1
            kind: DefaultAdmissionConfig
    """
    And the master service is restarted on all master nodes
    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml"
    And I replace lines in "rolebindingrestriction.yaml":
      | name: match-groups                        | name: match-serviceaccount |
      | grouprestriction:                         | serviceaccountrestriction: |
      | groups: ["groups-rolebindingrestriction"] | namespaces: [""]           |
    Given I run the :create admin command with:
       | f | rolebindingrestriction.yaml |
       | n | <%= project.name %>         |
    Then the step should succeed
    And I run the :policy_add_role_to_user client command with:
      | role           | view    |
      | serviceaccount | default |
    Then the step should fail
    And the output should match:
      | rolebindings.* "view" is forbidden |

  # @case_id OCP-20599
  @admin
  @destructive
  Scenario: Add warnings when bootstrap rolebindings are modified
    Given the "self-access-reviewers" clusterolebinding is recreated after scenario
    When I run the :annotate admin command with:
      | resource  | clusterrolebinding.rbac/self-access-reviewers    |
      | overwrite | true                                             |
      | keyval    | rbac.authorization.kubernetes.io/autoupdate=true |
    Then the step should succeed
    Given cluster role "self-access-reviewer" is removed from the "system:authenticated" group
    And the output should match:
      | Your changes may get lost whenever a master is restarted |
      | rbac.authorization.kubernetes.io/autoupdate=false        |
      | oc annotate clusterrolebinding.rbac                      |
    And the master service is restarted on all master nodes
    When I run the :annotate admin command with:
      | resource  | clusterrolebinding.rbac/self-access-reviewers     |
      | overwrite | true                                              |
      | keyval    | rbac.authorization.kubernetes.io/autoupdate=false |
    Then the step should succeed
    Given cluster role "self-access-reviewer" is removed from the "system:authenticated" group
    And the output should not match:
      | Your changes may get lost whenever a master is restarted |
      | rbac.authorization.kubernetes.io/autoupdate=false        |
      | oc annotate clusterrolebinding.rbac                      |

  # @author chuyu@redhat.com
  # @case_id OCP-22725
  @admin
  Scenario: 4.x Allow to make a role binding to a service account matched one rolebindingrestriction
    Given I have a project
    When I run the :new_app client command with:
      | template | postgresql-persistent |
    Then the step should succeed
    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml"
    And I replace lines in "rolebindingrestriction.yaml":
      | name: match-groups                        | name: match-serviceaccount          |
      | grouprestriction:                         | serviceaccountrestriction:          |
      | groups: ["groups-rolebindingrestriction"] | namespaces: ["<%= project.name %>"] |
    Given I run the :create admin command with:
      | f | rolebindingrestriction.yaml |
      | n | <%= project.name %>         |
    Then the step should succeed
    And I run the :policy_add_role_to_user client command with:
      | role      | view                                    |
      | user_name | system:serviceaccount:openshift:default |
    Then the step should fail
    Given I find a bearer token of the system:serviceaccount:<%= project.name %>:default service account
    Given I switch to the system:serviceaccount:<%= project.name %>:default service account
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should fail
    Given I switch to the first user
    And I run the :policy_add_role_to_user client command with:
      | role           | view    |
      | serviceaccount | default |
    Then the step should succeed
    Given I find a bearer token of the system:serviceaccount:<%= project.name %>:default service account
    Given I switch to the system:serviceaccount:<%= project.name %>:default service account
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-22717
  Scenario: 4.x Allow to make a role binding to a service account if no rolebindingrestriction exists
    Given I have a project
    Given I run the :policy_add_role_to_user client command with:
      | role           | view                |
      | serviceaccount | deployer            |
      | n              | <%= project.name %> |
    Then the step should succeed
    Given I run the :get client command with:
      | resource | rolebinding         |
      | n        | <%= project.name %> |
      | o        | wide                |
    Then the step should succeed
    And the output should match:
      | .*view.*/view.*deployer |

  # @author chuyu@redhat.com
  # @case_id OCP-22718
  @admin
  Scenario: 4.x Allow to make a role binding to a group matched one rolebindingrestriction
    Given I have a project
    When I run the :new_app client command with:
      | template | postgresql-persistent |
    Then the step should succeed
    Given admin ensures "groups-rolebindingrestriction" group is deleted after scenario
    Given I run the :oadm_groups_new admin command with:
      | group_name | groups-rolebindingrestriction |
      | user_name  | <%= user(1).name  %>          |
    Then the step should succeed
    Given I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml |
      | n | <%= project.name %>                                                                                                           |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should fail
    Given I switch to the first user
    And I run the :policy_add_role_to_group client command with:
      | role       | view                          |
      | group_name | groups-rolebindingrestriction |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-22719
  @admin
  Scenario: 4.x Allow to make a role binding to a user matched one rolebindingrestriction
    Given I have a project
    When I run the :new_app client command with:
      | template | postgresql-persistent |
    Then the step should succeed
    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml"
    And I replace lines in "rolebindingrestriction.yaml":
      | name: match-groups                        | name: match-users                              |
      | grouprestriction:                         | userrestriction:                               |
      | groups: ["groups-rolebindingrestriction"] | users: ["<%= user(1, switch: false).name  %>"] |
    Given I run the :create admin command with:
      | f | rolebindingrestriction.yaml |
      | n | <%= project.name %>         |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should fail
    Given I switch to the first user
    And I run the :policy_add_role_to_user client command with:
      | role      | view                                |
      | user_name | <%= user(1, switch: false).name  %> |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-22720
  @admin
  Scenario: 4.x Allow to make a role binding to a group if no rolebindingrestriction exists
    Given I have a project
    When I run the :new_app client command with:
      | template | postgresql-persistent |
    Then the step should succeed
    Given admin ensures "groups-rolebindingrestriction" group is deleted after scenario
    Given I run the :oadm_groups_new admin command with:
      | group_name | groups-rolebindingrestriction       |
      | user_name  | <%= user(1, switch: false).name  %> |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should fail
    Given I switch to the first user
    And I run the :policy_add_role_to_group client command with:
      | role       | view                          |
      | group_name | groups-rolebindingrestriction |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-22721
  Scenario: 4.x Allow to make a role binding to a user if no rolebindingrestriction exists
    Given I have a project
    When I run the :new_app client command with:
      | template | postgresql-persistent |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should fail
    Given I switch to the first user
    And I run the :policy_add_role_to_user client command with:
      | role      | view                                |
      | user_name | <%= user(1, switch: false).name  %> |
    Then the step should succeed
    Given I switch to the second user
    And I run the :get client command with:
      | resource | pods                |
      | n        | <%= project.name %> |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-22722
  @admin
  Scenario: 4.x Restrict making a role binding to a user not matched any rolebindingrestriction
    Given I have a project
    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml"
    And I replace lines in "rolebindingrestriction.yaml":
      | name: match-groups                        | name: match-users |
      | grouprestriction:                         | userrestriction:  |
      | groups: ["groups-rolebindingrestriction"] | users: [""]       |
    Given I run the :create admin command with:
      | f | rolebindingrestriction.yaml |
      | n | <%= project.name %>         |
    Then the step should succeed
    And I run the :policy_add_role_to_user client command with:
      | role      | view                                |
      | user_name | <%= user(1, switch: false).name  %> |
    Then the step should fail
    And the output should match:
      | rolebindings.* "view" is forbidden |

  # @author chuyu@redhat.com
  # @case_id OCP-22723
  @admin
  Scenario: 4.x Restrict making a role binding to a group not matched any rolebindingrestriction
    Given I have a project
    Given admin ensures "groups-rolebindingrestriction" group is deleted after scenario
    Given I run the :oadm_groups_new admin command with:
       | group_name | groups-rolebindingrestriction       |
       | user_name  | <%= user(1, switch: false).name  %> |
    Then the step should succeed
    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml"
    And I replace lines in "rolebindingrestriction.yaml":
      | groups: ["groups-rolebindingrestriction"] | groups: [""] |
    Given I run the :create admin command with:
      | f | rolebindingrestriction.yaml |
      | n | <%= project.name %>         |
    Then the step should succeed
    And I run the :policy_add_role_to_group client command with:
      | role       | view                          |
      | group_name | groups-rolebindingrestriction |
    Then the step should fail
    And the output should match:
      | rolebindings.* "view" is forbidden |

  # @author chuyu@redhat.com
  # @case_id OCP-22724
  @admin
  Scenario: 4.x Restrict making a role binding to a service account not matched any rolebindingrestriction
    Given I have a project
    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/policy/OCP-13479/rolebindingrestriction.yaml"
    And I replace lines in "rolebindingrestriction.yaml":
      | name: match-groups                        | name: match-serviceaccount |
      | grouprestriction:                         | serviceaccountrestriction: |
      | groups: ["groups-rolebindingrestriction"] | namespaces: [""]           |
    Given I run the :create admin command with:
       | f | rolebindingrestriction.yaml |
       | n | <%= project.name %>         |
    Then the step should succeed
    And I run the :policy_add_role_to_user client command with:
      | role           | view    |
      | serviceaccount | default |
    Then the step should fail
    And the output should match:
      | rolebindings.* "view" is forbidden |
