Feature: ONLY ONLINE Images related scripts in this file

  # @author etrott@redhat.com
  # @case_id 531501
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
  # @case_id 531502
  Scenario: .NET Core application quickstart test using image dotnetcore-10-rhel7
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/tc531502/dotnet-sqlite-example-template.json |
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
