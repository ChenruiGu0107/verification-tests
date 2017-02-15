Feature: Delete the resources via web console

  # @author wsun@redhat.com
  # @case_id OCP-10742
  Scenario: Delete app resources on web console as admin user
    When I create a project via web with:
      | display_name | :null               |
      | description  ||
    Then the step should succeed
    Given I wait for the :create_app_from_image web console action to succeed with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | latest                                     |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Given I wait for the "nodejs-sample" service to become ready
    And I wait until the status of deployment "nodejs-sample" becomes :complete
    When I run the :deploy client command with:
      | deployment_config | nodejs-sample |
      | latest            ||
    Then the step should succeed
    And I wait until the status of deployment "nodejs-sample" becomes :complete

    When I perform the :delete_resources_in_the_project web console action with:
      | project_name     | <%= project.name %>   |
      | pod_name         | nodejs-sample-1-build |
      | service_name     | nodejs-sample         |
      | bc_name          | nodejs-sample         |
      | dc_name          | nodejs-sample         |
      | build_name       | nodejs-sample-1       |
      | route_name       | nodejs-sample         |
      | image_name       | nodejs-sample         |
      | dc_number        | 1                     |
    Then the step should succeed
    When I perform the :check_deleted_resources web console action with:
      | project_name     | <%= project.name %>   |
      | pod_name         | nodejs-sample-1-build |
      | service_name     | nodejs-sample         |
      | bc_name          | nodejs-sample         |
      | dc_name          | nodejs-sample         |
      | build_name       | nodejs-sample-1       |
      | route_name       | nodejs-sample         |
      | image_name       | nodejs-sample         |
      | dc_number        | 1                     |
    Then the step should succeed

  # @author wsun@redhat.com
  # @case_id OCP-11541
  Scenario: The viewer can not delete app resources on web console
    Given I have a project
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | latest                                     |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed
    Given I wait for the "nodejs-sample" service to become ready
    When I run the :deploy client command with:
      | deployment_config | nodejs-sample |
      | latest            ||
    Then the step should succeed
    And I wait until the status of deployment "nodejs-sample" becomes :complete

    When I run the :policy_add_role_to_user client command with:
      | role      |   view    |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed
    Given I switch to the second user
    When I perform the :delete_resources_with_viewer_in_the_project web console action with:
      | project_name     | <%= project.name %>   |
      | pod_name         | nodejs-sample-1-build |
      | service_name     | nodejs-sample         |
      | bc_name          | nodejs-sample         |
      | dc_name          | nodejs-sample         |
      | build_name       | nodejs-sample-1       |
      | route_name       | nodejs-sample         |
      | image_name       | nodejs-sample         |
      | dc_number        | 1                     |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-11212
  Scenario: The editor can delete app resources on web console
    Given I have a project
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | latest                                     |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed
    Given I wait for the "nodejs-sample" service to become ready
    When I run the :deploy client command with:
      | deployment_config | nodejs-sample |
      | latest            ||
    Then the step should succeed
    And I wait until the status of deployment "nodejs-sample" becomes :complete

    When I run the :policy_add_role_to_user client command with:
      | role      |   edit    |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed
    Given I switch to the second user
    When I perform the :delete_resources_in_the_project web console action with:
      | project_name     | <%= project.name %>   |
      | pod_name         | nodejs-sample-1-build |
      | service_name     | nodejs-sample         |
      | bc_name          | nodejs-sample         |
      | dc_name          | nodejs-sample         |
      | build_name       | nodejs-sample-1       |
      | route_name       | nodejs-sample         |
      | image_name       | nodejs-sample         |
      | dc_number        | 1                     |
    Then the step should succeed
    When I perform the :check_deleted_resources web console action with:
      | project_name     | <%= project.name %>   |
      | pod_name         | nodejs-sample-1-build |
      | service_name     | nodejs-sample         |
      | bc_name          | nodejs-sample         |
      | dc_name          | nodejs-sample         |
      | build_name       | nodejs-sample-1       |
      | route_name       | nodejs-sample         |
      | image_name       | nodejs-sample         |
      | dc_number        | 1                     |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-10217
  Scenario: Check deployments and builds of deleted bc/dc on web console
    Given I have a project
    When I run the :new_build client command with:
      | code         | https://github.com/openshift/ruby-hello-world |
      | image        | openshift/ruby                                |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            ||
    Then the step should succeed

    Given the "ruby-hello-world-1" build finished
    When I perform the :delete_resources_buildconfig web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-hello-world    |
    Then the step should succeed

    When I perform the :check_builds_of_deleted_buildconfig web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-hello-world    |
      | build_number | 2                   |
    Then the step should succeed

    When I perform the :delete_resources_deploymentconfig web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
    Then the step should succeed

    When I perform the :check_deployments_of_deleted_deploymentconfig web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
      | deployment_number | 2              |
    Then the step should succeed
