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

  # @author etrott@redhat.com
  # @case_id 532758
  Scenario: Create mongo resources with persistent template for mongodb-32-rhel7 images
    Given I have a project
    Then I run the :new_app client command with:
      | template | mongodb-persistent           |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
    Then the step should succeed
    And the "mongodb" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mongodb         |
      | deployment=mongodb-1 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo admin -u admin -padmin --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 3.2 |

  # @author etrott@redhat.com
  # @case_id 532647
  Scenario: Add env variables to postgresql-95-rhel7 image
    Given I have a project
    When I run the :new_app client command with:
      | name  | psql                           |
      | image | openshift/postgresql:9.5       |
      | env   | POSTGRESQL_USER=user           |
      | env   | POSTGRESQL_PASSWORD=redhat     |
      | env   | POSTGRESQL_DATABASE=sampledb   |
      | env   | POSTGRESQL_MAX_CONNECTIONS=42  |
      | env   | POSTGRESQL_SHARED_BUFFERS=64MB |
    And a pod becomes ready with labels:
      | deployment=psql-1 |
    When I execute on the pod:
      | env |
    Then the output should contain:
      | POSTGRESQL_SHARED_BUFFERS=64MB |
      | POSTGRESQL_MAX_CONNECTIONS=42  |
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | bash                           |
      | -c                             |
      | psql -c 'show shared_buffers;' |
    Then the step should succeed
    """
    Then the output should contain:
      | shared_buffers |
      | 64MB           |
    And I wait for the steps to pass:
    """
    And I execute on the pod:
      | bash                            |
      | -c                              |
      | psql -c 'show max_connections;' |
    """
    Then the step should succeed
    Then the outputs should contain:
      | max_connections |
      | 42              |
