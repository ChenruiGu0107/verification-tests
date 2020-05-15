Feature: Upgrade images feature
  # @author wewang@redhat.com
  Scenario Outline: Image upgrade test for rhel7 images in OCP
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | registry.access.redhat.com/<image>~<repo> |
      | context_dir  | <context_dir>                             |
    Then the step should succeed
    And the "<app_name>-1" build was created
    And the "<app_name>-1" build completed
    And a pod becomes ready with labels:
      | app=<app_name> |
    When I run the :patch client command with:
      | resource      | buildconfig |
      | resource_name | <app_name>  |
      | p | {"spec":{"strategy":{"sourceStrategy":{"from":{"kind":"ImageStreamTag","name":"<istag>","namespace":"openshift"}}}}} |
    Then the step should succeed
    And the "<app_name>-2" build was created
    And the "<app_name>-2" build completed
    And a pod becomes ready with labels:
      | app=<app_name> |
    When I expose the "<app_name>" service
    Then I wait for a web server to become available via the "<app_name>" route
    Then the output should contain "<display_info>"

    Examples:
      | image                 | image_stream    |repo                                               |context_dir | app_name         | display_info                 | istag      |
      | rhscl/python-27-rhel7 | python-27-rhel7 |https://github.com/sclorg/django-ex.git         |            | django-ex        | Welcome to your Django       | python:2.7 | # @case_id OCP-9670
      | rhscl/python-34-rhel7 | python-34-rhel7 |https://github.com/sclorg/django-ex.git         |            | django-ex        | Welcome to your Django       | python:3.4 | # @case_id OCP-9671
      | rhscl/python-35-rhel7 | python-35-rhel7 |https://github.com/sclorg/django-ex.git         |            | django-ex        | Welcome to your Django       | python:3.5 | # @case_id OCP-17137
      | rhscl/httpd-24-rhel7  | httpd-24-rhel7  |https://github.com/sclorg/httpd-ex.git          |            | httpd-ex         | Welcome to your static httpd | httpd:2.4  | # @case_id OCP-17139
      | rhscl/ruby-23-rhel7   | ruby-23-rhel7   |https://github.com/openshift/ruby-hello-world.git  |            | ruby-hello-world | Welcome to an OpenShift v3   | ruby:2.3   | # @case_id OCP-17127
      | rhscl/ruby-24-rhel7   | ruby-24-rhel7   |https://github.com/openshift/ruby-hello-world.git  |            | ruby-hello-world | Welcome to an OpenShift v3   | ruby:2.4   | # @case_id OCP-17130
      | rhscl/perl-520-rhel7  | perl-520-rhel7  |https://github.com/sclorg/dancer-ex.git         |            | dancer-ex        | Welcome to your Dancer       | perl:5.20  | # @case_id OCP-9672
      | rhscl/perl-524-rhel7  | perl-524-rhel7  |https://github.com/sclorg/dancer-ex.git         |            | dancer-ex        | Welcome to your Dancer       | perl:5.24  | # @case_id OCP-17106
      | rhscl/nodejs-6-rhel7  | nodejs-6-rhel7  |https://github.com/sclorg/nodejs-ex.git         |            | nodejs-ex        | Welcome to your Node.js      | nodejs:6   | # @case_id OCP-17108
      | rhscl/nodejs-8-rhel7  | nodejs-8-rhel7  |https://github.com/sclorg/nodejs-ex.git         |            | nodejs-ex        | Welcome to your Node.js      | nodejs:8   | # @case_id OCP-17721
      | dotnet/dotnet-20-rhel7    | dotnet-20-rhel7     |https://github.com/redhat-developer/s2i-dotnetcore-ex.git#dotnetcore-2.0|app| s2i-dotnetcore-ex| .NET Core MVC | dotnet:2.0 | # @case_id OCP-17133
      | dotnet/dotnetcore-11-rhel7| dotnetcore-11-rhel7 |https://github.com/redhat-developer/s2i-dotnetcore-ex.git#dotnetcore-1.1|app| s2i-dotnetcore-ex| .NET Core MVC | dotnet:1.1 | # @case_id OCP-17134
      | dotnet/dotnetcore-10-rhel7| dotnetcore-10-rhel7 |https://github.com/redhat-developer/s2i-dotnetcore-ex.git#dotnetcore-1.0|app| s2i-dotnetcore-ex| .NET Core MVC | dotnet:1.0 | # @case_id OCP-17135

  # @author wewang@redhat.com
  Scenario Outline: Image upgrade test for postgresql rhel7 in OCP
    Given I have a project
    And I run the :import_image client command with:
      | image_name |  postgresql                              |
      | from       | registry.access.redhat.com/rhscl/<image> |
      | confirm    | true                                     |
      | insecure   | true                                     |
      | all        | true                                     |
    Then the step should succeed
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/postgresql-persistent-template.json"
    And I replace lines in "postgresql-persistent-template.json":
      | "value": "9.6"       | "value": "<version>"           |
      | "value": "openshift" | "value": "<%= project.name %>" |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | postgresql-persistent-template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=postgresql-1 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'CREATE TABLE tbl (col1 VARCHAR(20), col2 VARCHAR(20));' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    """
    And the output should contain:
      | CREATE TABLE |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c "INSERT INTO tbl (col1,col2) VALUES ('foo1', 'bar1');" -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | INSERT 0 1 |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | col1 | col2 |
      | foo1 | bar1 |
    When I run the :import_image client command with:
      | image_name | postgresql                                                         |
      | from       | <%= product_docker_repo %>rhscl/<image>                            |
      | confirm    | true                                                               |
      | insecure   | true                                                               |
      | all        | true                                                               |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=postgresql-2 |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | col1 | col2 |
      | foo1 | bar1 |

    Examples:
      | version | image               |
      | 9.5     | postgresql-95-rhel7 | # @case_id OCP-17136
      | 9.4     | postgresql-94-rhel7 | # @case_id OCP-9680

  # @author wzheng@redhat.com
  # @case_id OCP-17128
  Scenario: Image upgrade test for mariadb-101-rhel7
    Given I have a project
    And I run the :import_image client command with:
      | image_name | mariadb                                            |
      | from       | registry.access.redhat.com/rhscl/mariadb-101-rhel7 |
      | confirm    | true                                               |
      | insecure   | true                                               |
      | all        | true                                               |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | mariadb-persistent            |
      | param    | MYSQL_USER=user               |
      | param    | MYSQL_PASSWORD=user           |
      | param    | NAMESPACE=<%= project.name %> |
      | param    | MARIADB_VERSION=latest        |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mariadb |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -c   |
      | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    When I execute on the pod:
      | bash |
      | -c   |
      |mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    When I execute on the pod:
      | bash |
      | -c   |
      | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'select * from  test;' |
    Then the step should succeed
    And the output should contain:
      | 10 |
    Then I run the :import_image client command with:
      | image_name | mariadb                                           |
      | from       | <%= product_docker_repo %>rhscl/mariadb-101-rhel7 |
      | confirm    | true                                              |
      | insecure   | true                                              |
      | all        | true                                              |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=mariadb-2 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -c   |
      | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |

  # @author wzheng@redhat.com
  # @case_id OCP-17129
  Scenario: Image upgrade test for redis-32-rhel7
    Given I have a project
    And I run the :import_image client command with:
      | image_name | redis                                           |
      | from       | registry.access.redhat.com/rhscl/redis-32-rhel7 |
      | confirm    | true                                            |
      | insecure   | true                                            |
      | all        | true                                            |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | redis-persistent              |
      | param    | REDIS_PASSWORD=redhat         |
      | param    | NAMESPACE=<%= project.name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=redis |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                                                      |
      | -c                                                                        |
      | redis-cli -h redis -p 6379 -c 'auth redhat; set mykey "hello"; get mykey' |
    Then the step should succeed
    And the output should contain:
      | hello |
    """
    Then I run the :import_image client command with:
      | image_name | redis                                          |
      | from       | <%= product_docker_repo %>rhscl/redis-32-rhel7 |
      | confirm    | true                                           |
      | insecure   | true                                           |
      | all        | true                                           |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=redis-2 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                                                      |
      | -c                                                                        |
      | redis-cli -h redis -p 6379 -c 'auth redhat; set mykey "hello"; get mykey' |
    Then the step should succeed
    And the output should contain:
      | hello |
    """


  # @author wzheng@redhat.com
  # @case_id OCP-17125
  Scenario: Image upgrade test for mysql-57-rhel7 in OCP
    Given I have a project
    And I run the :import_image client command with:
      | image_name | mysql                                           |
      | from       | registry.access.redhat.com/rhscl/mysql-57-rhel7 |
      | confirm    | true                                            |
      | insecure   | true                                            |
      | all        | true                                            |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | mysql-persistent              |
      | param    | MYSQL_USER=user               |
      | param    | MYSQL_PASSWORD=user           |
      | param    | NAMESPACE=<%= project.name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mysql|
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -c   |
      | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    When I execute on the pod:
      | bash |
      | -c   |
      |mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    When I execute on the pod:
      | bash |
      | -c   |
      | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'select * from  test;' |
    Then the step should succeed
    And the output should contain:
      | 10 |
    Then I run the :import_image client command with:
      | image_name | mysql                                          |
      | from       | <%= product_docker_repo %>rhscl/mysql-57-rhel7 |
      | confirm    | true                                           |
      | insecure   | true                                           |
      | all        | true                                           |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=mysql-2 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -c   |
      | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |
