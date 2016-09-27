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

  # @author etrott@redhat.com
  # @case_id 532739
  Scenario: Verify Mariadb can be connected after admin and user password are changed and re-deployment for persistent storage - marialdb-101-rhel7
    Given I have a project
    And I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc532739/mariadb-persistent.json |
    Given a pod becomes ready with labels:
      | deployment=mariadb-1 |
    When I run the :env client command with:
      | resource | pod/<%= pod.name %> |
      | list     | true                |
    Then the output should contain:
      | MYSQL_USER              |
      | MYSQL_PASSWORD          |
      | MYSQL_DATABASE=sampledb |
    Given I get project pod named "<%= pod.name %>" as YAML
    And evaluation of `pod.env_var("MYSQL_PASSWORD")` is stored in the :mysql_password clipboard
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | mysql -h <%= pod.name %> --user=$MYSQL_USER --password=<%= cb.mysql_password %> -e 'use sampledb;create table test (name VARCHAR(20));insert into test VALUES("openshift")' |
    Then the step should succeed
    """
    When I execute on the pod:
      | bash | -c | mysql -h <%= pod.name %> --user=$MYSQL_USER --password=<%= cb.mysql_password %> -e 'use sampledb;select * from test;' |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | dc/mariadb            |
      | e        | MYSQL_PASSWORD=redhat |
    Given a pod becomes ready with labels:
      | deployment=mariadb-2 |
    When I execute on the pod:
      | bash | -c | mysql -h <%= pod.name %> --user=$MYSQL_USER --password=<%= cb.mysql_password %> |
    Then the step should fail
    When I execute on the pod:
      | bash | -c | mysql -h <%= pod.name %> --user=$MYSQL_USER --password=redhat -e 'use sampledb;select * from test;' |
    Then the step should succeed
    Given I ensure "<%= pod.name %>" pod is deleted
    When I run the :deploy client command with:
      | deployment_config | mariadb |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=mariadb-2 |
    When I execute on the pod:
      | bash | -c | mysql -h <%= pod.name %> --user=$MYSQL_USER --password=redhat -e 'use sampledb;select * from test;' |
    Then the step should succeed

    # @author etrott@redhat.com
    # @case_id 532732
    Scenario: mem based auto-tuning mariadb
      Given I have a project
      When I run the :new_app client command with:
        | name  | mariadb                  |
        | image | openshift/mariadb:10.1   |
        | env   | MYSQL_ROOT_PASSWORD=test |
      Then the step should succeed
      Given a pod becomes ready with labels:
        | deployment=mariadb-1 |
      When I execute on the pod:
        | cat | /etc/my.cnf.d/tuning.cnf |
      Then the output should contain:
        | key_buffer_size = 51M          |
        | read_buffer_size = 25M         |
        | innodb_buffer_pool_size = 256M |
        | innodb_log_file_size = 76M     |
        | innodb_log_buffer_size = 76M   |
      Given I perform the :goto_set_resource_limits_for_dc web console action with:
        | project_name | <%= project.name %> |
        | dc_name      | mariadb             |
      Then the step should succeed
      When I perform the :set_resource_limit_single web console action with:
        | resource_type   | memory |
        | limit_type      | Limit  |
        | amount_unit     | MiB    |
        | resource_amount | 800    |
      Then the step should succeed
      When I run the :save_your_committed_changes web console action
      Then the step should succeed
      Given I wait for the pod named "mariadb-2-deploy" to die
      And a pod becomes ready with labels:
        | deployment=mariadb-2 |
      When I execute on the pod:
        | cat | /etc/my.cnf.d/tuning.cnf |
      Then the output should contain:
        | key_buffer_size = 80M          |
        | read_buffer_size = 40M         |
        | innodb_buffer_pool_size = 400M |
        | innodb_log_file_size = 120M    |
        | innodb_log_buffer_size = 120M  |

  # @author etrott@redhat.com
  # @case_id 532767
  Scenario: Tune puma workers according to memory limit ruby-rhel7
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/maybelinot/v3-testfiles/master/image/language-image-templates/tc532767/template.json |
    Then the step should succeed
    Given the "rails-ex-1" build was created
    And the "rails-ex-1" build completed
    Given 1 pods become ready with labels:
      | app=rails-ex          |
      | deployment=rails-ex-1 |
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %> |
    Then the output should contain:
      | * Min threads: 0, max threads: 16 |
      | * Process workers: 4              |
