Feature: Routes related features on web console
  # @author yanpzhan@redhat.com
  # @case_id 509106
  Scenario: Check Routes page
    Given I login via web console
    Given I have a project

    When I perform the :check_empty_routes_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed
    Given the "nodejs-sample-1" build was created
    Given the "nodejs-sample-1" build completed
    Given I wait for the "nodejs-sample" service to become ready
    And I wait for a server to become available via the "nodejs-sample" route
    When I run the :get client command with:
      | resource      | route                 |
      | resource_name | nodejs-sample         |
      | template      | {{.spec.host}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :patch_yaml clipboard

    When I perform the :check_routes_page web console action with:
      | project_name | <%= project.name %> |
      | route_name   | nodejs-sample       |
    Then the step should succeed

    When I perform the :check_a_route_detail_page web console action with:
      | project_name | <%= project.name %> |
      | route_name   | nodejs-sample       |
      | service_name | nodejs-sample       |
    Then the step should succeed

    When I perform the :access_route_hostname web console action with:
      | project_name | <%= project.name %> |
      | route_name   | nodejs-sample       |
      | service_url | <%= cb.patch_yaml %>|
    Then the step should succeed    
