Feature: dotnet.feature

  # @author haowang@redhat.com
  # @case_id 533862
  Scenario: Create .NET application with new-app
    Given I have a project
    When I run the :new_app client command with:
      | app_repo    | https://github.com/redhat-developer/s2i-dotnetcore |
      | context_dir | 1.0/test/asp-net-hello-world/                      |
    Then the step should succeed
    Given the "s2i-dotnetcore-1" build was created
    And the "s2i-dotnetcore-1" build completed
    Given 1 pods become ready with labels:
      | app=s2i-dotnetcore          |
      | deployment=s2i-dotnetcore-1 |
