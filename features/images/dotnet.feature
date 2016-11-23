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

  # @author haowang@redhat.com
  # @case_id 534580
  Scenario: dotnet10 build behind proxy
    Given I have a project
    And I have a proxy configured in the project
    When I run the :new_build client command with:
      | app_repo    | openshift/dotnet:1.0~https://github.com/openshift-s2i/s2i-aspnet-example |
      | context_dir | app                                                                      |
      | e           | http_proxy=http://<%= cb.proxy_ip %>:3128                                |
      | e           | https_proxy=http://<%= cb.proxy_ip %>:3128                               |
      | e           | HTTP_PROXY=http://<%= cb.proxy_ip %>:3128                                |
      | e           | HTTPS_PROXY=http://<%= cb.proxy_ip %>:3128                               |
    Then the step should succeed
    And the "s2i-aspnet-example-1" build completes
