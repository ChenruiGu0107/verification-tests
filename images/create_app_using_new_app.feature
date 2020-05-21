Feature:Create apps using new_app cmd feature
  # @author xiuwang@redhat.com
  # @case_id OCP-16887
  Scenario: Validate dotnet imagestream works well in online env
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/redhat-developer/s2i-dotnetcore/master/templates/dotnet-example.json |
    Then the step should succeed
    And the "dotnet-example-1" build was created
    And the "dotnet-example-1" build completed
    Then I wait for a web server to become available via the "dotnet-example" route
    And the output should contain "Sample pages using ASP.NET Core MVC"
