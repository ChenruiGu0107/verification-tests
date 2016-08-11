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
