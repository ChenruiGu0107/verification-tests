Feature: dotnet.feature

  # @author haowang@redhat.com
  # @case_id OCP-10949
  Scenario: Create .NET application with new-app
    Given I have a project
    When I run the :new_app client command with:
      | app_repo    | openshift/dotnet:latest~https://github.com/openshift-s2i/s2i-aspnet-example#dotnetcore-1.1 |
      | context_dir | app                                                                                        |
    Then the step should succeed
    Given the "s2i-aspnet-example-1" build was created
    And the "s2i-aspnet-example-1" build completed
    Given 1 pods become ready with labels:
      | app=s2i-aspnet-example          |
      | deployment=s2i-aspnet-example-1 |

  # @author haowang@redhat.com
  # @case_id OCP-10247
  Scenario: dotnet10 build behind proxy
    Given I have a project
    And I have a proxy configured in the project
    When I run the :new_build client command with:
      | app_repo    | openshift/dotnet:1.1~https://github.com/redhat-developer/s2i-dotnetcore-ex#dotnetcore-1.1 |
      | context_dir | app                                                                                       |
      | e           | http_proxy=http://<%= cb.proxy_ip %>:3128                                                 |
      | e           | https_proxy=http://<%= cb.proxy_ip %>:3128                                                |
      | e           | HTTP_PROXY=http://<%= cb.proxy_ip %>:3128                                                 |
      | e           | HTTPS_PROXY=http://<%= cb.proxy_ip %>:3128                                                |
    Then the step should succeed
    And the "s2i-dotnetcore-ex-1" build completes

  # @author haowang@redhat.com
  # @case_id OCP-11353
  Scenario: Create .NET buildconfig with new-build
    Given I have a project
    When I run the :new_build client command with:
      | app_repo    | openshift/dotnet:latest~https://github.com/openshift-s2i/s2i-aspnet-example#dotnetcore-1.1 |
      | context_dir | app                                                                                        |
    Then the step should succeed
    Given the "s2i-aspnet-example-1" build was created
    And the "s2i-aspnet-example-1" build completed
