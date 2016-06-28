Feature: Add env variables to image feature
  # @author dyan@redhat.com
  # @case_id 473390 500960
  Scenario Outline: Add env variables to mysql image
    Given I have a project
    When I run the :create client command with:
      | f | <template> |
    Then the step should succeed
    And I run the :get client command with:
      | resource | template |
    Then the step should succeed
    And the output should contain:
      | mysql-ephemeral   MySQL database service, without persistent storage. |
    And I run the :new_app client command with:
      | template | mysql-ephemeral |
    Then the step should succeed

    Given I wait for the "mysql" service to become ready
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash           |
      | -c             |
      | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -e "show databases" |
    Then the step should succeed
    """
    And the output should contain "sampledb"
    When I execute on the pod:
      | bash           |
      | -l             |
      | -c             |
      | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD   -e "SHOW VARIABLES LIKE 'lower_case_table_names';" |
    Then the step should succeed
    And the output should contain:
      | lower_case_table_names |
      | 1                      |
    When I execute on the pod:
      | bash           |
      | -l             |
      | -c             |
      | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD   -e "SHOW VARIABLES LIKE 'max_connections';" |
    Then the step should succeed
    And the output should contain:
      | max_connections |
      | 100             |
    When I execute on the pod:
      | bash           |
      | -l             |
      | -c             |
      | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD   -e "SHOW VARIABLES LIKE 'ft_min_word_len';" |
    Then the step should succeed
    And the output should contain:
      | ft_min_word_len |
      | 5               |
    When I execute on the pod:
      | bash           |
      | -l             |
      | -c             |
      | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD   -e "SHOW VARIABLES LIKE 'ft_max_word_len';" |
    Then the step should succeed
    And the output should contain:
      | ft_max_word_len |
      | 15              |
    When I execute on the pod:
      | bash           |
      | -l             |
      | -c             |
      | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD   -e "SHOW VARIABLES LIKE 'innodb_use_native_aio';" |
    Then the step should succeed
    And the output should contain:
      | innodb_use_native_aio |
      | ON                    |

    Examples:
      | template |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mysql-55-env-var-test.json |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mysql-56-env-var-test.json |

  # @author wewang@redhat.com cryan@redhat.com
  # @case_id 473391 508068 529314
  Scenario Outline: Add env variables to postgresql image
    Given I have a project
    When I run the :run client command with:
      | name  | psql                                                                                                                                      |
      | image | <image>                                                                                                                                   |
      | env   | POSTGRESQL_USER=user,POSTGRESQL_PASSWORD=redhat,POSTGRESQL_DATABASE=sampledb,POSTGRESQL_MAX_CONNECTIONS=42,POSTGRESQL_SHARED_BUFFERS=64MB |
    And a pod becomes ready with labels:
      | run=psql |
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
    Examples:
      | image |
      | <%= product_docker_repo %>openshift3/postgresql-92-rhel7 |
      | <%= product_docker_repo %>rhscl/postgresql-94-rhel7      |
      | <%= product_docker_repo %>rhscl/postgresql-95-rhel7      |

  # @author cryan@redhat.com
  # @case_id 497480
  Scenario: Add env variables to mongodb-24-centos7 image
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mongodb-24-centos7-env-test.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=database |
    When I execute on the pod:
      | bash | -c| env \| grep MONGO |
    Then the output should match:
      | MONGODB_NOPREALLOC=false                  |
      | MONGODB_QUIET=false                       |
      | MONGODB_PREFIX=/opt/rh/mongodb24/root/usr |
      | MONGODB_ADMIN_PASSWORD=r00t               |
      | MONGODB_DATABASE=root                     |
      | MONGODB_PASSWORD=fpBt72kI                 |
      | MONGODB_VERSION=2.4                       |
      | MONGODB_SMALLFILES=false                  |
      | MONGODB_USER=user7BE                      |
    When I execute on the pod:
      | bash | -c| cat /etc/mongod.conf |
    Then the output should match:
      | noprealloc = false |
      | smallfiles = false |
      | quiet = false      |

  # @author cryan@redhat.com
  # @case_id 529325 529362
  Scenario Outline: mem based auto-tuning mariadb
    Given I have a project
    When I run the :run client command with:
      | name  | mariadb                                        |
      | image | <%= product_docker_repo %>rhscl/<image>:latest |
      | env   | MYSQL_ROOT_PASSWORD=test                       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=mariadb |
    When I execute on the pod:
      | bash | -c | cat /etc/my.cnf.d/tuning.cnf |
    Then the output should contain:
      | key_buffer_size = 32M         |
      | read_buffer_size = 8M         |
      | innodb_buffer_pool_size = 32M |
      | innodb_log_file_size = 8M     |
      | innodb_log_buffer_size = 8M   |
    When I run the :delete client command with:
      | all_no_dash |  |
      | all         |  |
    Then the step should succeed
    Given I wait for the pod to die regardless of current status
    When I run the :run client command with:
      | name   | mariadb                                        |
      | image  | <%= product_docker_repo %>rhscl/<image>:latest |
      | env    | MYSQL_ROOT_PASSWORD=test                       |
      | limits | memory=512Mi                                   |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=mariadb |
    When I execute on the pod:
      | bash | -c | cat /etc/my.cnf.d/tuning.cnf |
    Then the output should contain:
      | key_buffer_size = 51M          |
      | read_buffer_size = 25M         |
      | innodb_buffer_pool_size = 256M |
      | innodb_log_file_size = 76M     |
      | innodb_log_buffer_size = 76M   |
    Examples:
      | image             |
      | mariadb-100-rhel7 |
      | mariadb-101-rhel7 |
