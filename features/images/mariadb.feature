Feature: MariaDB images test

  # @author cryan@redhat.com
  # @case_id 529359 529360
  Scenario Outline: Deploy mariadb image
    Given I have a project
    When I run the :run client command with:
      | name  | mariadb                                        |
      | image | <%= product_docker_repo %>rhscl/<image>:latest |
      | env   | MYSQL_ROOT_PASSWORD=test                       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=mariadb |
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
      | mariadb-100-rhel7 |
      | mariadb-101-rhel7 |
