Feature: projects related features via cli
  # @author pruan@redhat.com
  # @case_id OCP-11107
  Scenario: There is annotation instead of 'Display name' for project info
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
      | display_name | <%= cb.proj_name %> |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    And I run the :get client command with:
      | resource | project |
      |  o       | json    |
    Then the output should contain:
      | display-name": "<%= cb.proj_name %>" |
    And the output should not contain:
      | displayName |
    """

  # @author pruan@redhat.com
  # @case_id OCP-12616
  Scenario: Could not create the project with invalid name via CLI
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | new-project  |
    Then the step should fail
    And the output should contain:
      | Create a new project for yourself |
      | oc new-project NAME [--display-name=DISPLAYNAME] [--description=DESCRIPTION] [options] |
      | error: must have exactly one argument                                                  |
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    Given I switch to the second user
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should fail
    And the output should match:
      | project.* "<%= cb.proj_name %>" already exists |
    When I run the :new_project client command with:
      | project_name | <%= rand_str(1,:dns) %> |
    Then the step should fail
    When I run the :new_project client command with:
      | project_name | <%= rand_str(64,:dns) %> |
    Then the step should fail
    When I run the :new_project client command with:
      | project_name | ALLUPPERCASE |
    Then the step should fail
    Then the output should contain:
      | The ProjectRequest "ALLUPPERCASE" is invalid |
    When I run the :new_project client command with:
      | project_name | -abc |
    Then the step should fail
    And the output should contain:
      | unknown shorthand flag: 'a' in -abc |
    When I run the :new_project client command with:
      | project_name | xyz- |
    Then the step should fail
    And the output should contain:
      | The ProjectRequest "xyz-" is invalid |
    When I run the :new_project client command with:
      | project_name | $pe#cial& |
    Then the step should fail
    And the output should contain:
      | The ProjectRequest "$pe#cial&" is invalid |

  # @author pruan@redhat.com
  # @case_id 478983
  @admin
  @destructive
  Scenario: A user could create a project successfully via CLI
    Given I have a project
    When I run the :get client command with:
      | resource | project |
    Then the step should succeed
    Then the output should contain:
      | <%= project.name %> |
      | Active              |
    Given cluster role "self-provisioner" is removed from the "system:authenticated:oauth" group
    When I create a new project
    Then the step should fail
    And the output should contain:
      | You may not request a new project via this API |

  # @author pruan@redhat.com
  # @case_id OCP-12548
  Scenario: User should be able to switch projects via CLI
    Given I create a new project
    And I create a new project
    And I create a new project
    When I run the :project client command with:
      | project_name | <%= project(2, switch: false).name %> |
    Then the output should contain:
      | project "<%= project(2, switch: false).name %>" on server |
    When I run the :project client command with:
      | project_name | <%= project(1, switch: false).name %> |
    Then the output should contain:
      | project "<%= project(1, switch: false).name %>" on server |
    When I run the :project client command with:
      | project_name | <%= project.name %> |
    Then the output should contain:
      | project "<%= project.name %>" on server |
    And I run the :project client command with:
      | project_name | notaccessible |
    Then the output should contain:
      | error: You are not a member of project "notaccessible". |
      | Your projects are:                                      |
      | * <%= project(0).name %>                                |
      | * <%= project(1).name %>                                |
      | * <%= project(2).name %>                                |

  # @author wyue@redhat.com
  # @case_id OCP-12029
  @admin
  Scenario: Should be able to create a project with valid node selector
    # Create a project with the node label
    Given I store the schedulable nodes in the clipboard
    Given evaluation of `node.labels.keys.select{|key| key.include?("io/hostname")}.first` is stored in the :unique_key clipboard
    Given evaluation of `[cb.unique_key, node.labels[cb.unique_key]].join("=")` is stored in the :node_selector clipboard
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/projects/prj_with_invalid_node-selector.json"
    And I replace lines in "prj_with_invalid_node-selector.json":
      | "openshift.io/node-selector": "env,qa" | "openshift.io/node-selector": "<%= cb.node_selector %>" |
      | "name": "jhou"                         | "name": "<%= cb.proj_name %>"                           |
    Then the step should succeed
    When I run the :create admin command with:
      | f | prj_with_invalid_node-selector.json |
    Then the step should succeed
    Given I register clean-up steps:
      | admin deletes the "<%= cb.proj_name %>" project |
      | the step should succeed                         |

    When I run the :describe admin command with:
      | resource | project             |
      | name     | <%= cb.proj_name %> |
    Then the output should contain:
      | <%= cb.node_selector %> |
    # Grant admin to user
    When I run the :policy_add_role_to_user admin command with:
      | role            |   admin               |
      | user name       |   <%= user.name %>    |
      | n               |   <%= cb.proj_name %> |
    Then the step should succeed
    # Create a pod in the project
    When I use the "<%= cb.proj_name %>" project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then  the step should succeed
    Given the pod named "hello-openshift" status becomes :running
    # Check pod is create on the correspond node
    When I run the :describe client command with:
      | resource | pods            |
      | name     | hello-openshift |
    Then the output should contain:
      | <%= node.name %> |

  # @author xiaocwan@redhat.com
  # @case_id OCP-12026
  Scenario: User should be notified if the set project does not exist anymore
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed

    When I run the :policy_add_role_to_user client command with:
      | role      | admin                               |
      | user_name | <%= user(1, switch: false).name %>  |
    Then the step should succeed

    Given I switch to the second user
    When I use the "<%= cb.proj_name %>" project
    Then the step should succeed

    When I create a new application with:
      | name         | myapp                                         |
      | image_stream | ruby                                          |
      | code         | https://github.com/openshift/ruby-hello-world |
    Then the step should succeed

    When I delete the project
    Then the step should succeed

    Given I switch to the first user
    When I run the :get client command with:
      | resource | pods |
    Then the step should fail

  # @author pruan@redhat.com
  # @case_id OCP-10753
  Scenario: Give user suggestion about new-app on new-project
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    And the output should contain:
      | You can add applications to this project with the 'new-app' command. |

  # @author cryan@redhat.com
  # @case_id OCP-12617
  Scenario: Race to create new project
    Given a 5 characters random string of type :dns is stored into the :user1proj1 clipboard
    When I run the :new_project background client command with:
      | project_name | <%= cb.user1proj1 %> |
      | description  | racetocreate |
    Given I switch to the second user
    When I run the :new_project client command with:
      | project_name | <%= cb.user1proj1 %> |
      | description  | racetocreate |
    Then the step should fail
    And the output should contain "already exists"
    When I run the :get client command with:
      | resource | projects |
    Then the output should not contain "racetocreate"

  # @author xxia@redhat.com
  # @case_id OCP-9594
  @admin
  Scenario: Update on project
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    # Update with cluster-admin (*admin* command)
    When I run the :annotate admin command with:
      | resource     | project/<%= project.name %>  |
      | overwrite    | true                         |
      | keyval       | openshift.io/description=descr1       |
      | keyval       | openshift.io/display-name=display1    |
    Then the step should succeed
    Then I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource      | project/<%= project.name %>  |
    Then the step should succeed
    And the output should contain:
      | openshift.io/description=descr1     |
      | openshift.io/display-name=display1  |
    """

    When I run the :get client command with:
      | resource      | pod/hello-openshift  |
    Then the step should succeed
    # Resource is not affected by above project update.
    And the output should match "unning\s*0"

    When I run the :annotate admin command with:
      | resource     | project/<%= project.name %>  |
      | overwrite    | true              |
      | keyval       | openshift.io/sa.scc.uid-range=1000030000/100001 |
      | keyval       | openshift.io/node-selector=region=primary       |
      | keyval       | openshift.io/sa.scc.mcs=s0:c7,c1111             |
    Then the step should fail
    And the output should match:
      | sa.scc.uid-range.*immutable   |
      | node-selector.*immutable      |
      | sa.scc.mcs.*immutable         |

    When I run the :patch admin command with:
      | resource      | project/<%= project.name %>      |
      | p             | {"metadata":{"name":"new-name"}} |
    Then the step should fail

    # Update with noraml user (*client* command)
    When I run the :annotate client command with:
      | resource     | project/<%= project.name %>  |
      | overwrite    | true                         |
      | keyval       | openshift.io/description=descr2       |
      | keyval       | openshift.io/display-name=display2    |
    Then the step should succeed
    Then I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource      | project/<%= project.name %>  |
    Then the step should succeed
    And the output should contain:
      | openshift.io/description=descr2     |
      | openshift.io/display-name=display2  |
    """

    When I run the :get client command with:
      | resource      | pod/hello-openshift  |
    Then the step should succeed
    # Resource is not affected by above project update.
    And the output should match "unning\s*0"

    When I run the :annotate client command with:
      | resource     | project/<%= project.name %>  |
      | overwrite    | true              |
      | keyval       | openshift.io/sa.scc.uid-range=1000030000/100001 |
      | keyval       | openshift.io/node-selector=region=primary       |
      | keyval       | openshift.io/sa.scc.mcs=s0:c7,c1111             |
    Then the step should fail
    And the output should match:
      | sa.scc.uid-range.*immutable   |
      | node-selector.*immutable      |
      | sa.scc.mcs.*immutable         |

    When I run the :patch client command with:
      | resource      | project/<%= project.name %>      |
      | p             | {"metadata":{"name":"new-name"}} |
    Then the step should fail

  # @author wjiang@redhat.com
  # @case_id OCP-9797
  Scenario: serviceaccount can not create projectrequest
    Given I have a project
    Given I find a bearer token of the default service account
    And I switch to the default service account
    When I create a new project
    Then the step should fail
    And the output should contain:
      |You may not request a new project via this API|

  # @author xxia@redhat.com
  # @case_id OCP-12546
  Scenario: Should use and show the existing projects after the user login
    Given I create 3 new projects
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>         |
      | token    | <%= user.cached_tokens.first %>  |
      | skip_tls_verify | true           |
      | config   | new_config_file       |
    Then the step should succeed
    And the output should contain:
      | You have access to the following projects and can switch between them with 'oc project <projectname>': |
      | <%= @projects[0].name %> |
      | <%= @projects[1].name %> |
      | <%= @projects[2].name %> |

    # 'Using project "<project>" uses the alphabetically least project name when config is newly created
    # So can not be hard coded as <%= project.name %>
    And the output should match:
      | Using project "(<%= @projects[0].name %>\|<%= @projects[1].name %>\|<%= @projects[2].name %>)" |

    When I switch to the second user
    # Due to FW, to cover bug 1263562, script must use --config=<the same file> for oc login here
    And I run the :login client command with:
      | token    | <%= user.cached_tokens.first %>  |
      | config   | new_config_file       |
    Then the step should succeed
    And the output should contain:
      | You don't have any projects. You can try to create a new project |

    #  Similarly, use --config=<the same file> here
    When I run the :config_view client command with:
      | config   | new_config_file       |
    Then the step should succeed
    And the output should match:
      |   name: .+/.+/<%= user(0, switch: false).name %> |
      | current-context: /.+/<%= user.name %>            |

  # @author xiaocwan@redhat.com
  # @case_id OCP-10874
  Scenario: oc project or projects to get project or projects with information
    Given I create a new project
    Then evaluation of `project.name` is stored in the :project1 clipboard
    Given I create a new project
    Then evaluation of `project.name` is stored in the :project2 clipboard
    Given I create a new project
    Then evaluation of `project.name` is stored in the :project3 clipboard

    When I run the :project client command
    Then the step should succeed
    And the output should match:
      | [Uu]sing.*<%= cb.project3 %> |
    And the output should not match:
      | <%= cb.project1 %>     |
      | <%= cb.project2 %>     |
    When I run the :projects client command
    Then the step should succeed
    And the output should match:
      | \*.*<%= cb.project3 %> |
      | <%= cb.project1 %>     |
      | <%= cb.project2 %>     |
    ## delete the latest project and check
    When I run the :delete client command with:
      | object_type       | project            |
      | object_name_or_id | <%= cb.project3 %> |
    Then the step should succeed
    And I wait for the resource "project" named "<%= cb.project3 %>" to disappear
    When I run the :projects client command
    Then the step should succeed
    And the output should not contain:
      | <%= cb.project3 %>     |
    And the output should match:
      | [Yy]ou have access to the following projects |
      | <%= cb.project1 %>     |
      | <%= cb.project2 %>     |
    When I run the :project client command
    Then the step should fail
    And the output should match:
      | do not have rights.*<%= cb.project3 %> |
    ## delete one and left only one project then check
    When I run the :delete client command with:
      | object_type       | project            |
      | object_name_or_id | <%= cb.project2 %> |
    Then the step should succeed
    And I wait for the resource "project" named "<%= cb.project2 %>" to disappear
    When I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should not match:
      | <%= cb.project2 %>   |

    When I run the :project client command
    Then the step should fail
    And the output should match:
      | do not have rights.*<%= cb.project3 %> |
    When I run the :projects client command
    Then the step should succeed
    And the output should match:
      | have one project.*<%= cb.project1 %>   |
    ## delete the only left one and check
    When I run the :delete client command with:
      | object_type       | project            |
      | object_name_or_id | <%= cb.project1 %> |
    Then the step should succeed
    And I wait for the resource "project" named "<%= cb.project1 %>" to disappear
    When I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should not match:
      | <%= cb.project1 %>   |
    When I run the :projects client command
    Then the step should succeed
    And the output should match:
      | [Yy]ou are not a member of any project |
    When I run the :project client command
    Then the step should fail
    And the output should match:
      | do not have rights.*<%= cb.project3 %> |

  # @author xiaocwan@redhat.com
  # @case_id OCP-11297
  Scenario: oc project or projects to get project or projects without any extra information
    Given I create a new project
    Then evaluation of `project.name` is stored in the :project1 clipboard
    Given I create a new project
    Then evaluation of `project.name` is stored in the :project2 clipboard
    Given I create a new project
    Then evaluation of `project.name` is stored in the :project3 clipboard

    When I run the :project client command with:
      | short | true |
    Then the step should succeed
    And the output should match:
      | <%= cb.project3 %> |
    And the output should not match:
      | <%= cb.project1 %> |
      | <%= cb.project2 %> |
    # A fix: need wait to be robuster because the projects were just created quickly
    Given I wait for the steps to pass:
    """
    When I run the :projects client command with:
      | short | true |
    Then the step should succeed
    And the output should match:
      | <%= cb.project1 %> |
      | <%= cb.project2 %> |
      | <%= cb.project3 %> |
    """
    ## delete the latest project and check
    When I run the :delete client command with:
      | object_type       | project            |
      | object_name_or_id | <%= cb.project3 %> |
    Then the step should succeed
    And I wait for the resource "project" named "<%= cb.project3 %>" to disappear
    When I run the :projects client command with:
      | short | true |
    Then the step should succeed
    And the output should match:
      | <%= cb.project1 %>     |
      | <%= cb.project2 %>     |
    When I run the :project client command with:
      | short | true |
    Then the step should succeed
    And the output should match:
      | <%= cb.project3 %> |
    And the output should not match:
      | <%= cb.project1 %> |
      | <%= cb.project2 %> |
    ## delete one and left only one project then check
    When I run the :delete client command with:
      | object_type       | project            |
      | object_name_or_id | <%= cb.project2 %> |
    Then the step should succeed
    And I wait for the resource "project" named "<%= cb.project2 %>" to disappear
    When I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should not match:
      | <%= cb.project2 %>   |
    When I run the :project client command with:
      | short | true |
    Then the step should succeed
    And the output should match:
      | <%= cb.project3 %> |
    And the output should not match:
      | <%= cb.project1 %> |
      | <%= cb.project2 %> |
    When I run the :projects client command with:
      | short | true |
    Then the step should succeed
    And the output should match:
      | <%= cb.project1 %>   |
    ## switch to the only left project and display short name
    ## different with `oc project <project>` which output "Now using project <project> on server"
    When I run the :project client command with:
      | project_name | <%= cb.project1 %> |
      | short        | true               |
    Then the step should succeed
    And the output should contain:
      | <%= cb.project1 %> |
    And the output should not contain:
      | [Nn]ow using project <%= cb.project1 %> |
    ## delete the only left one and check
    When I run the :delete client command with:
      | object_type       | project            |
      | object_name_or_id | <%= cb.project1 %> |
    Then the step should succeed
    And I wait for the resource "project" named "<%= cb.project1 %>" to disappear
    When I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should not match:
      | <%= cb.project1 %>   |
    When I run the :projects client command with:
      | short | true |
    # Remove output check for 3.5 - origin PR #12274 issue #12267
    Then the step should succeed
    When I run the :project client command with:
      | short | true |
    Then the step should succeed
    And the output should match:
      | <%= cb.project1 %> |
    And the output should not match:
      | <%= cb.project3 %> |
      | <%= cb.project2 %> |

  # @author xxia@redhat.com
  # @case_id OCP-10350
  Scenario: compensate for raft/cache delay in namespace admission
    Given evaluation of `rand_str(5,:dns)` is stored in the :proj_name clipboard
    Then I run the steps 15 times:
    """
    Given I wait for the steps to pass:
    \"\"\"
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    \"\"\"
    When I run the :new_app client command with:
      | app_repo | openshift/hello-openshift |
    Then the step should succeed
    Then I delete the "<%= cb.proj_name %>" project
    """
