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
    And I download a file from "<file>"
    And I replace lines in "<template>":
      | registry.access.redhat.com/ | <%= product_docker_repo %> |
    When I run the :new_app client command with:
      | file | <template> |
    Then the step should succeed
    And 1 pods become ready with labels:
      | deployment=mysql-1 |
    When I execute on the pod:
      | cat | /etc/my.cnf.d/tuning.cnf |
    Then the step should succeed
    And the output should contain:
      | innodb_log_file_size = 16M           |
      | max_allowed_packet = 300M            |
      | table_open_cache = 300               |
      | sort_buffer_size = 128K              |
      | read_buffer_size = 16M               |
      | innodb_buffer_pool_size = 16M        |
      | innodb_additional_mem_pool_size = 2M |

    Examples:
      | file                                                                                                                | template                      |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mariadb-100-env-var-test.json | mariadb-100-env-var-test.json | # @case_id OCP-10868
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mariadb-101-env-var-test.json | mariadb-101-env-var-test.json | # @case_id OCP-11293
