Feature: dotnet.feature
  # @author haowang@redhat.com
  # @case_id OCP-11353
  Scenario: Create .NET buildconfig with new-build
    Given I have a project
    When I run the :new_build client command with:
      | app_repo    | openshift/dotnet:2.1~https://github.com/openshift-s2i/s2i-aspnet-example#dotnetcore-2.1 |
      | context_dir | app |
    Then the step should succeed
    Given the "s2i-aspnet-example-1" build was created
    And the "s2i-aspnet-example-1" build completed
