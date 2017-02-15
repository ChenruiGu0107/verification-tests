Feature:policy related features on web console

  # @author xiaocwan@redhat.com
  # @case_id OCP-11710
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
  # @case_id OCP-10604
  @admin
  @destructive
  Scenario: Cluster-admin can completely disable access to request project.
    Given I log the message> this scenario is only valid for oc >= 3.4
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
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>        |
      | token    | <%= user.get_bearer_token.token %> |
      | skip_tls_verify | true                        |
      | config   | new.config                         |
    Then the step should succeed
    And the output should not contain:
      | oc new-project                                |
    And the output should match:
      | [Cc]ontact.*to request a project              |
    When I create a new project
    Then the step should fail
    And the output should match:
      | [Ee]rror.*[Uu]ser.*ca(n'\|nno)t list.*projectrequests |

  # @author xiaocwan@redhat.com
  # @case_id OCP-10544
  @admin
  @destructive
  Scenario: Cluster-admin disable access to project by remove cluster role from group
    Given I log the message> this scenario is only valid for oc >= 3.4
    Given cluster roles are restored after scenario
    Given cluster role "self-provisioner" is removed from the "system:authenticated" group
    And cluster role "self-provisioner" is removed from the "system:authenticated:oauth" group

    Given I login via web console
    When I get the html of the web page
    Then the output should match:
      | cluster admin can create a project for you    |
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>        |
      | token    | <%= user.get_bearer_token.token %> |
      | skip_tls_verify | true                        |
      | config   | new.config                         |
    Then the step should succeed
    And the output should not contain:
      | oc new-project                                |
    And the output should match:
      | [Cc]ontact.*to request a project              |
    When I create a new project
    Then the step should fail
    And the output should not contain:
      | oc new-project                                |
    And the output should match:
      | [Yy]ou may not request a new project          |

  # @author xiaocwan@redhat.com
  # @case_id OCP-11321
  Scenario: Check user actions they have view authority to check buttons and links on web console
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role            | view                               |
      | user name       | <%= user(1, switch: false).name %> |
      | n               | <%= project.name %>                |
    Then the step should succeed
    Given I switch to the second user
    # check when project has no resouce,there should be no button for creating resource
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should contain "elcome"
    And the output should not contain "Add to project"
    """
    When I perform the :goto_one_route_page web console action with:
      | project_name     | <%= project.name %>   |
      | route_name       | route-edge            |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "oute"
    And the output should not match:
      | [Cc]reate [Rr]oute |
    """
    # 3.3 does not have pipeline page and will stay on last page
    When I perform the :check_pipline_no_permission_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain "Add to Project"

    # project admin create some resources for the project
    Given I switch to the first user
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    When I run the :create client command with:
      | f    | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f    | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/pvc-rox.json |
    Then the step should succeed
    # when build is running, check bc and build page, check buttons and links
    Given the "ruby-sample-build-1" build becomes :running
    Given I switch to the second user
    When I perform the :goto_one_buildconfig_page web console action with:
      | project_name     | <%= project.name %>   |
      | bc_name          | ruby-sample-build     |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "ruby-sample-build"
    And the output should not match:
      | Actions             |
      | [Ss]tart [Bb]uild   |
    """
    When I perform the :goto_one_build_page web console action with:
      | project_name     | <%= project.name %>   |
      | bc_and_build_name| ruby-sample-build/ruby-sample-build-1 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "ruby-sample-build-1"
    And the output should not match:
      | Actions            |
      | [Cc]ancel [Bb]uild |
    """
    # when build is finished, check build page and other pages one by one
    Given the "ruby-sample-build-1" build finished
    When I perform the :goto_one_build_page web console action with:
      | project_name     | <%= project.name %>   |
      | bc_and_build_name| ruby-sample-build/ruby-sample-build-1 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "ruby-sample-build-1"
    And the output should not match:
      | Actions          |
      | Rebuild          |
    """
    # dc and rc page
    When I perform the :goto_one_dc_page web console action with:
      | project_name     | <%= project.name %>   |
      | dc_name          | frontend              |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "frontend"
    And the output should not match:
      | Actions                   |
      | [Aa]dd [Hh]ealth [Cc]heck |
      | [Aa]dd [Aa]utoscaler      |
      | [Aa]dd [Ss]torage         |
    """
    When I perform the :goto_one_deployment_page web console action with:
      | project_name     | <%= project.name %>   |
      | dc_name          | frontend              |
      | dc_number        | 1                     |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "frontend-1"
    And the output should not match:
      | Actions                     |
      | [Aa]dd storage and redeploy |
    """
    # one pod page
    Given the pod named "ruby-sample-build-1-build" status becomes :succeeded
    When I perform the :goto_one_pod_page web console action with:
      | project_name     | <%= project.name %>       |
      | pod_name         | ruby-sample-build-1-build |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "ruby-sample-build-1-build"
    And the output should not contain "Actions"
    """
    # imagestream page
    When I perform the :goto_one_image_stream_page web console action with:
      | project_name     | <%= project.name %>   |
      | image_name       | ruby-22-centos7       |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "ruby-22-centos7"
    And the output should not contain "Actions"
    """
    # routes and one route page
    When I perform the :goto_routes_page web console action with:
      | project_name     | <%= project.name %>   |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "example.com"
    And the output should not match:
      | [Cc]reate [Rr]oute  |
    """
    When I perform the :goto_one_route_page web console action with:
      | project_name     | <%= project.name %>   |
      | route_name       | route-edge            |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "route-edge"
    And the output should not contain "Actions"
    """
    # membership page
    # 3.3 does not have membership page and will stay on last page
    When I perform the :check_membership_no_permission_page web console action with:
      | project_name     | <%= project.name %>   |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain "Edit"

    # secret and one secret page
    When I perform the :check_secret_no_permission_page web console action with:
      | project_name     | <%= project.name %>   |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain "Create Secret"
    When I perform the :check_one_secret_no_permission_page web console action with:
      | project_name     | <%= project.name %>   |
      | secret           | test-secrets          |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain "Actions"
    # pvc and one pvc page
    When I perform the :goto_storage_page web console action with:
      | project_name     | <%= project.name %>   |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "torage"
    And the output should not match:
      | [Cc]reate [Ss]torage |
    """
    When I perform the :goto_one_pvc_page web console action with:
      | project_name     | <%= project.name %>   |
      | pvc_name         | cinderc               |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "cinderc"
    And the output should not contain "Actions"
    """
    # service page
    When I perform the :goto_one_service_page web console action with:
      | project_name     | <%= project.name %>   |
      | service_name     | database              |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "database"
    And the output should not contain "Actions"
    """
    # overview page
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should contain "o grouped service"
    And the output should not contain "Group Service"
    """
