Feature: Delete the resources via web console

  # @author wsun@redhat.com
  # @case_id OCP-10742
  Scenario: Delete app resources on web console as admin user
    Given I have a project
    Given I wait for the :create_app_from_image web console action to succeed with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | latest                                     |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Given the "nodejs-sample-1" build completed
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
    Given the "nodejs-sample-1" build completed
    Given I wait for the "nodejs-sample" service to become ready
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
    And I wait until the status of deployment "nodejs-sample" becomes :complete

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

  # @author yapei@redhat.com
  # @case_id OCP-14215
  Scenario: Delete deployment should also delete ReplicaSets and pod with alert dialog
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-14215/k8s-deployment.yaml |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | app=hello-openshift |
    When I perform the :goto_one_k8s_deployment_page web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
    Then the step should succeed
    When I run the :get client command with:
      | resource | rs |
    Then the step should succeed
    And the output should contain:
      | hello-openshift |
    
    When I run the :check_delete_deployment_warning_in_delete_action web console action
    Then the step should succeed
    When I run the :click_delete web console action
    Then the step should succeed
    Given I wait for the resource "deployment" named "hello-openshift" to disappear
    When I run the :get client command with:
      | resource | rs |
    Then the step should succeed
    And the output should contain:
      | No resources found |
    And the output should not contain:
      | hello-openshift |
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    And the output should contain:
      | No resources found |
    And the output should not contain:
      | hello-openshift |

  # @author yapei@redhat.com
  # @case_id OCP-14207
  Scenario: Delete BC/statefulSet from console should remove builds/pods with alert dialog
    Given the master version >= "3.6"
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    When I run the :get client command with:
      | resource | builds |
    Then the step should succeed
    And the output should contain:
      | ruby-sample-build-1 |
    When I perform the :goto_one_buildconfig_page web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample-build   |
    Then the step should succeed
    When I run the :check_delete_bc_warning_in_delete_action web console action
    Then the step should succeed
    When I run the :click_delete web console action
    Then the step should succeed
    Given I wait for the resource "bc" named "ruby-sample-build" to disappear
    When I run the :get client command with:
      | resource | builds |
    Then the step should succeed
    And the output should contain:
      | No resources found |
    And the output should not contain:
      | ruby-sample-build-1 |

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/statefulset/statefulset-hello.yaml |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | app=hello |
    When I perform the :goto_one_stateful_sets_page web console action with:
      | project_name       | <%= project.name %> |
      | stateful_sets_name | hello               |
    Then the step should succeed
    When I run the :check_delete_statefulsets_warning_in_delete_action web console action
    Then the step should succeed
    When I run the :click_delete web console action
    Then the step should succeed
    Given I wait for the resource "statefulsets" named "hello" to disappear
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | hello |
