Feature: ONLY ONLINE Images related scripts in this file

  # @author etrott@redhat.com
  # @case_id OCP-10133
  Scenario: Create .NET app by imagestream
    Given I have a project
    When I create a new application with:
      | image_stream | openshift/dotnet:1.0~https://github.com/openshift-s2i/s2i-aspnet-example |
      | context dir  | app                                                                      |
      | name         | aspnet-app                                                               |
    Then the step should succeed
    And the "aspnet-app-1" build completed
    And a pod becomes ready with labels:
      | deployment=aspnet-app-1     |
      | deploymentconfig=aspnet-app |
    When I expose the "aspnet-app" service
    Then the step should succeed
    And I wait for a web server to become available via the route

  # @author etrott@redhat.com
  # @case_id OCP-10134
  Scenario: .NET Core application quickstart test using image dotnetcore-10-rhel7
    Given I have a project
    Given I obtain test data file "online/tc531502/dotnet-sqlite-example-template.json"
    When I run the :create client command with:
      | f | dotnet-sqlite-example-template.json |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :new_app client command with:
      | app_repo | dotnet-sqlite-example |
    Then the step should succeed
    And the "dotnet-sqlite-example-1" build completed
    When I run the :build_logs client command with:
      | build_name | dotnet-sqlite-example-1 |
    Then the output should not contain:
      | error |
    When I get project pods
    Then the output should contain:
      | dotnet-sqlite-example-1-build  |
      | dotnet-sqlite-example-1-deploy |
    And I wait for the "dotnet-sqlite-example" service to become ready
    When I get project services
    Then the output should contain:
      | dotnet-sqlite-example |
    When I get project routes
    Then the output should contain:
      | dotnet-sqlite-example |
    And I wait for a web server to become available via the "dotnet-sqlite-example" route

  # @author etrott@redhat.com
  # @case_id OCP-12373
  Scenario: Tune puma workers according to memory limit ruby-rhel7
    Given I have a project
    Given I obtain test data file "image/language-image-templates/tc532767/template.json"
    When I run the :create client command with:
      | f | template.json |
    Then the step should succeed
    Given the "rails-ex-1" build was created
    And the "rails-ex-1" build completed
    Given 1 pods become ready with labels:
      | app=rails-ex          |
      | deployment=rails-ex-1 |
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %> |
    Then the output should contain:
      | * Process workers: 1 |
    When I run the :patch client command with:
      | resource      | deploymentconfig                                                                                              |
      | resource_name | rails-ex                                                                                                      |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"rails-ex","resources":{"limits":{"memory":"700Mi"}}}]}}}} |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | app=rails-ex          |
      | deployment=rails-ex-2 |
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %> |
    Then the output should contain:
      | * Process workers: 2 |
