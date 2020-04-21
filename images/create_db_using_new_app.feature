Feature:Create db using new_app cmd feature
  # @author xiuwang@redhat.com
  # @case_id OCP-12095
  Scenario: Use default values for memory limits env vars - mysql-57-rhel7
    Given I have a project
    When I run the :run client command with:
      | name  | mysql                                          |
      | image | <%= product_docker_repo %>rhscl/mysql-57-rhel7 |
      | env   | MYSQL_ROOT_PASSWORD=test                       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=mysql |
    When I execute on the pod:
      | cat                      |
      | /etc/my.cnf.d/50-my-tuning.cnf |
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
      | image | <%= product_docker_repo %>rhscl/mysql-57-rhel7 |
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
      | /etc/my.cnf.d/50-my-tuning.cnf |
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
      | image  | <%= product_docker_repo %>rhscl/mysql-57-rhel7 |
      | env    | MYSQL_ROOT_PASSWORD=test                       |
      | limits | memory=512Mi                                   |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=mysql |
    When I execute on the pod:
      | cat                      |
      | /etc/my.cnf.d/50-my-tuning.cnf |
    Then the output should contain:
      | key_buffer_size = 51M          |
      | read_buffer_size = 25M         |
      | innodb_buffer_pool_size = 256M |
      | innodb_log_file_size = 76M     |
      | innodb_log_buffer_size = 76M   |
