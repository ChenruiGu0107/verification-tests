Feature:Create db using new_app cmd feature
  # @author dyan@redhat.com
  # @case_id OCP-9664, OCP-9665, OCP-10365
  Scenario Outline: Create mysql resources from imagestream via oc new-app
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | <image_stream_name> |
      | env          | MYSQL_USER=user     |
      | env          | MYSQL_PASSWORD=pass |
      | env          | MYSQL_DATABASE=db   |
    Then the step should succeed
    Given I wait for the "mysql" service to become ready
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash           |
      | -c             |
      | mysql -h $MYSQL_SERVICE_HOST -uuser -ppass -e "show databases" |
    Then the step should succeed
    """
    And the output should contain "db"

    When I execute on the pod:
      | bash           |
      | -c             |
      | mysql -h $MYSQL_SERVICE_HOST -uuser -ppass   -e "use db;create table test (name VARCHAR(20))" |
    Then the step should succeed
    When I execute on the pod:
      | bash           |
      | -c             |
      | mysql -h $MYSQL_SERVICE_HOST -uuser -ppass   -e "use db;insert into test VALUES('openshift')" |
    Then the step should succeed
    When I execute on the pod:
      | bash           |
      | -c             |
      | mysql -h $MYSQL_SERVICE_HOST -uuser -ppass  -e "use db;select * from test" |
    Then the output should contain:
      | name      |
      | openshift |

    Examples:
      | image_stream_name |
      | mysql:5.7         |
      | mysql:5.6         |
      | mysql:5.5         |

  # @author dyan@redhat.com
  # @case_id OCP-9654, OCP-9755
  Scenario Outline: Create mongodb resources from imagestream via oc new-app
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | <image_stream_name>         |
      | env          | MONGODB_USER=user           |
      | env          | MONGODB_PASSWORD=pass       |
      | env          | MONGODB_DATABASE=db         |
      | env          | MONGODB_ADMIN_PASSWORD=pass |
    Then the step should succeed
    Given I wait for the "mongodb" service to become ready
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash           |
      | -c             |
      | mongo db -uuser -ppass --eval "db.db.insert({'name':'openshift'})" |
    Then the step should succeed
    """
    When I execute on the pod:
      | bash           |
      | -c             |
      | mongo db -uuser -ppass --eval "printjson(db.db.findOne())" |
    Then the step should succeed
    And the output should contain:
      | name |
      | openshift |

    Examples:
      | image_stream_name |
      | mongodb:2.6       |
      | mongodb:2.4       |

  # @author xiuwang@redhat.com
  # @case_id OCP-12095
  Scenario: Use default values for memory limits env vars - mysql-57-rhel7
    Given I have a project
    When I run the :run client command with:
      | name  | mysql                                          |
      | image | <%= project_docker_repo %>rhscl/mysql-57-rhel7 |
      | env   | MYSQL_ROOT_PASSWORD=test                       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=mysql |
    When I execute on the pod:
      | cat                      | 
      | /etc/my.cnf.d/tuning.cnf |
    Then the output should contain:
      | key_buffer_size = 8M          |
      | read_buffer_size = 8M         |
      | innodb_buffer_pool_size = 32M |
      | innodb_log_file_size = 8M     |
      | innodb_log_buffer_size = 8M   |

  # @author xiuwang@redhat.com
  # @case_id OCP-11841
  Scenario: Use customized values for memory limits env vars - mysql-57-rhel7
    Given I have a project
    When I run the :run client command with:
      | name  | mysql                                          |
      | image | <%= project_docker_repo %>rhscl/mysql-57-rhel7 |
      | env   | MYSQL_ROOT_PASSWORD=test                       |
      | env   | MYSQL_KEY_BUFFER_SIZE=8M                       |
      | env   | MYSQL_READ_BUFFER_SIZE=8M                      |
      | env   | MYSQL_INNODB_BUFFER_POOL_SIZE=16M              |
      | env   | MYSQL_INNODB_LOG_FILE_SIZE=4M                  |
      | env   | MYSQL_INNODB_LOG_BUFFER_SIZE=4M                |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=mysql |
    When I execute on the pod:
      | cat                      |
      | /etc/my.cnf.d/tuning.cnf |
    Then the output should contain:
      | key_buffer_size = 8M          |
      | read_buffer_size = 8M         |
      | innodb_buffer_pool_size = 16M |
      | innodb_log_file_size = 4M     |
      | innodb_log_buffer_size = 4M   |

  # @author xiuwang@redhat.com
  # @case_id OCP-11367
  Scenario: Check memory limits env vars when pod is set with memory limit-mysql-57-rhel7
    Given I have a project
    When I run the :run client command with:
      | name   | mysql                                          |
      | image  | <%= project_docker_repo %>rhscl/mysql-57-rhel7 |
      | env    | MYSQL_ROOT_PASSWORD=test                       |
      | limits | memory=512Mi                                   |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=mysql |
    When I execute on the pod:
      | cat                      | 
      | /etc/my.cnf.d/tuning.cnf |
    Then the output should contain:
      | key_buffer_size = 51M          |
      | read_buffer_size = 25M         |
      | innodb_buffer_pool_size = 256M |
      | innodb_log_file_size = 76M     |
      | innodb_log_buffer_size = 76M   |
