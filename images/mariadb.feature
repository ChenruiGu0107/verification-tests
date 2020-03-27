Feature: MariaDB images test

  # @author cryan@redhat.com
  Scenario Outline: Deploy mariadb image
    Given I have a project
    When I run the :new_app client command with:
      | name              | mariadb                                        |
      | docker_image      | <%= product_docker_repo %>rhscl/<image>:latest |
      | env               | MYSQL_ROOT_PASSWORD=test                       |
      | insecure_registry | true                                           |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=mariadb-1 |
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | mysql -h <%= pod.name %> --user=root --password=test -e 'use test;create table test (name VARCHAR(20));insert into test VALUES("openshift")' |
    Then the step should succeed
    """
    When I execute on the pod:
      | bash | -c | mysql -h <%= pod.name %> --user=root --password=test -e 'use test;select * from test;' |
    Then the step should succeed
    And the output should contain "openshift"
    Examples:
      | image             |
      | mariadb-100-rhel7 | # @case_id OCP-11598
      | mariadb-101-rhel7 | # @case_id OCP-11800

  # @author haowang@redhat.com
  Scenario Outline: Add env vars to mariadb image
    Given I have a project
    And I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/image/db-templates/<file>"
    And I replace lines in "<template>":
      | registry.access.redhat.com/ | <%= product_docker_repo %> |
    When I run the :new_app client command with:
      | file | <file> |
    Then the step should succeed
    And 1 pods become ready with labels:
      | deployment=mysql-1 |
    When I execute on the pod:
      | cat | /etc/my.cnf.d/50-my-tuning.cnf |
    Then the step should succeed
    And the output should contain:
      | innodb_log_file_size = 16M           |
      | max_allowed_packet = 300M            |
      | table_open_cache = 300               |
      | sort_buffer_size = 128K              |
      | read_buffer_size = 16M               |
      | innodb_buffer_pool_size = 16M        |
      | innodb_log_buffer_size = 16M         |
      | innodb_log_file_size = 16M           |
      | myisam_sort_buffer_size = 2M         |
    Examples:
      | file                          |
      | mariadb-100-env-var-test.json | # @case_id OCP-10868
      | mariadb-101-env-var-test.json | # @case_id OCP-11293

  # @author dyan@redhat.com
  # @case_id OCP-14855
  Scenario: mariadb persistent template
    Given I have a project
    When I run the :new_app client command with:
      | template | mariadb-persistent           |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
    Then the step should succeed
    And the "mariadb" PVC becomes :bound within 300 seconds
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
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -c   |
      |mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    """
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

  # @author dyan@redhat.com
  # @case_id OCP-14853
  Scenario: mariadb ephemeral template
    Given I have a project
    When I run the :new_app client command with:
      | template | mariadb-ephemeral            |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
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
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -c   |
      |mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    """
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

