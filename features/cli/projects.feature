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
      | The ProjectRequest "ALLUPERCASE" is invalid. |
    When I run the :new_project client command with:
      | project_name | -abc |
    Then the step should fail
    And the output should contain:
      | unknown shorthand flag: 'a' in -abc |
    When I run the :new_project client command with:
      | project_name | xyz- |
    Then the step should fail
    And the output should contain:
      | The ProjectRequest "xyz-" is invalid. |

    When I run the :new_project client command with:
      | project_name | $pe#cial& |
    Then the step should fail
    And the output should contain:
      | The ProjectRequest "$pe#cial&" is invalid. |

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
     | the step should succeed                                       |
    When I run the :oadm_remove_cluster_role_from_group admin command with:
      | role_name  | self-provisioner     |
      | group_name | system:authenticated |
    Then the step should succeed
    When I create a new project
    Then the step should fail
    And the output should contain:
      | You may not request a new project via this API |
  # @author pruan@redhat.com
  # @case_id 470729
  Scenario: Should use and show the existing projects after the user login
    Given I create a new project
    And evaluation of `user.projects` is stored in the :user1_proj clipboard
    And I switch to the second user
    And I create a new project
    And I create a new project
    And I create a new project
    And evaluation of `user.projects` is stored in the :user2_proj clipboard
    And I switch to the first user
    And I run the :login client command with:
      | u | <%= @user.name %>     |
    Then the output should contain:
      | Using project "<%= cb.user1_proj[0].name %>" |
    And I switch to the second user
    And I run the :login client command with:
      | u | <%= @user.name %>     |
    Then the output should contain:
      | Using project "<%= project.name %>" |
      | You have access to the following projects and can switch between them with 'oc project <projectname>': |
      | * <%= cb.user2_proj[0].name %> |
      | * <%= cb.user2_proj[1].name %> |
      | * <%= cb.user2_proj[2].name %> |
    And I switch to the third user
    And I run the :login client command with:
      | u | <%= @user.name %>     |
    Then the step should succeed
    And the output should contain:
      | You don't have any projects. You can try to create a new project |

  # @author pruan@redhat.com
  # @case_id 470730
  Scenario: User should be able to switch projects via CLI
    Given I create a new project
    And I create a new project
    And I create a new project
    When I run the :project client command with:
      | project_name | <%= project(2, switch: false).name %> |
    Then the output should contain:
      | Now using project "<%= project(2, switch: false).name %>" on server |
    When I run the :project client command with:
      | project_name | <%= project(1, switch: false).name %> |
    Then the output should contain:
      | Now using project "<%= project(1, switch: false).name %>" on server |
    When I run the :project client command with:
      | project_name | <%= project.name %> |
    Then the output should contain:
      | Now using project "<%= project.name %>" on server |
    And I run the :project client command with:
      | project_name | notaccessible |
    Then the output should contain:
      | error: You are not a member of project "notaccessible". |
      | Your projects are:                                      |
      | * <%= project(0).name %>                              |
      | * <%= project(1).name %>                              |
      | * <%= project(2).name %>                              |
  # @author haowang@redhat.com
  # @case_id 497401
  Scenario: Indicate when build failed to push in 'oc status'
    Given I have a project
    When I run the :status client command
    Then the step should succeed
    And the output should contain:
      | <%= project.name %> |
      |no services |
      |Run 'oc new-app' to create an application|
    When I run the :new_app client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world |
      | l | app=ruby |
    Then the step should succeed
    And the output should contain:
      | WARNING |
      | it does not look like a Docker registry has been integrated |
    Given the "ruby-hello-world-1" build was created
    When I run the :status client command
    Then the step should succeed
    And the output should contain:
      | can't push to image |
      | Warning |
      | administrator has not configured the integrated Docker registry |
      
  # @author yapei@redhat.com
  # @case_id 476297
  Scenario: Could delete all resources when delete the project   
    Given a 5 characters random string of type :dns is stored into the :prj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.prj_name %> |
    Then the step should succeed
    And I create a new application with:
      | docker image | openshift/mysql-55-centos7 |
      | code         | https://github.com/openshift/ruby-hello-world |
      | n            | <%= cb.prj_name %>           |
    Then the step should succeed

    ### get project resource
    When I run the :get client command with:
      | resource | deploymentconfigs |
      | n        | <%= cb.prj_name %>  |
    Then the output should contain:
      | mysql-55-centos7 |
      | ruby-hello-world |
    
    When I run the :get client command with:
      | resource | buildconfigs |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | ruby-hello-world |

    When I run the :get client command with:
      | resource | services |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | mysql-55-centos7 |
      | ruby-hello-world |

    When I run the :get client command with:
      | resource | pods  |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | mysql-55-centos7-1-deploy |
      | ruby-hello-world-1-build |

    ### delete this project
    Then I run the :delete client command with:
      | object_type       | project |
      | object_name_or_id | <%= cb.prj_name %> |
    And the step should succeed

    ### get project resource after project is deleted
    When I run the :get client command with:
      | resource | deploymentconfigs |
      | n        | <%= cb.prj_name %>  |
    Then the output should contain:
      | Error from server: User "<%= @user.name %>" cannot list deploymentconfigs in project "<%= cb.prj_name %>" |
    When I run the :get client command with:
      | resource | buildconfigs |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | Error from server: User "<%= @user.name %>" cannot list buildconfigs in project "<%= cb.prj_name %>" |
    When I run the :get client command with:
      | resource | services |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | Error from server: User "<%= @user.name %>" cannot list services in project "<%= cb.prj_name %>" |
    When I run the :get client command with:
      | resource | pods  |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | Error from server: User "<%= @user.name %>" cannot list pods in project "<%= cb.prj_name %>" |

    ### create a project with same name, no context for this new one
    Given I run the :new_project client command with:
      | project_name | <%= cb.prj_name %> | 
    And the step should succeed
    Then I run the :status client command
    And the output should contain:
      | In project <%= cb.prj_name %> on server |
      | You have no services, deployment configs, or build configs |

