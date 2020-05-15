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
