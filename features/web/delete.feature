Feature: Delete the resources via web console

  # @author wsun@redhat.com
  # @case_id 512251
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
      | pod_warning      | The pod details could not be loaded. |
      | service_name     | nodejs-sample         |
      | service_warning  | The service details could not be loaded |
      | bc_name          | nodejs-sample         |
      | bc_warning       | This build configuration can not be found |
      | dc_name          | nodejs-sample         |
      | dc_warning       | This deployment configuration can not be found |
      | build_name       | nodejs-sample-1       |
      | build_warning    | The build details could not be loaded. |
      | route_name       | nodejs-sample         |
      | route_warning    | The route details could not be loaded. |
      | image_name       | nodejs-sample         |
      | image_warning    | The image stream details could not be loaded. |
      | dc_number        | 1                     |
      | rc_warning       | The deployment details could not be loaded. |
    Then the step should succeed

  # @author wsun@redhat.com
  # @case_id 512253
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
  # @case_id 512252
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
      | pod_warning      | The pod details could not be loaded. |
      | service_name     | nodejs-sample         |
      | service_warning  | The service details could not be loaded |
      | bc_name          | nodejs-sample         |
      | bc_warning       | This build configuration can not be found |
      | dc_name          | nodejs-sample         |
      | dc_warning       | This deployment configuration can not be found |
      | build_name       | nodejs-sample-1       |
      | build_warning    | The build details could not be loaded. |
      | route_name       | nodejs-sample         |
      | route_warning    | The route details could not be loaded. |
      | image_name       | nodejs-sample         |
      | image_warning    | The image stream details could not be loaded. |
      | dc_number        | 1                     |
      | rc_warning       | The deployment details could not be loaded. |
    Then the step should succeed
