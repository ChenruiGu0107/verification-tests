Feature: MariaDB images test
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

