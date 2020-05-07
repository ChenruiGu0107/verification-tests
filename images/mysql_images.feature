Feature: mysql_images.feature
  # @author haowang@redhat.com
  # @case_id OCP-9722
  @smoke
  Scenario: mysql persistent template
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent             |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
    Then the step should succeed
    And the "mysql" PVC becomes :bound within 300 seconds
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

  # @author haowang@redhat.com
  # @case_id OCP-12342
  Scenario: Verify DB can be connect after change admin and user password and re-deployment for ephemeral storage - mysql-55-rhel7
    Given I have a project
    And I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/image/db-templates/mysql55-ephemeral-template.json |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
    And a pod becomes ready with labels:
      | name=mysql|
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |
    When I run the :set_env client command with:
      | resource | dc/mysql               |
      | e        | MYSQL_PASSWORD=newuser |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mysql          |
      | deployment=mysql-2  |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -pnewuser -D sampledb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -pnewuser -D sampledb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -pnewuser -D sampledb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |

  # @author haowang@redhat.com
  # @case_id OCP-12419
  Scenario: Verify DB can be connect after change admin and user password and re-deployment for persistent storage - mysql-55-rhel7
    Given I have a project
    And I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/image/db-templates/mysql55-persistent-template.json |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
    Then the step should succeed
    And the "mysql" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mysql|
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |
    When I run the :set_env client command with:
      | resource | dc/mysql               |
      | e        | MYSQL_PASSWORD=newuser |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mysql          |
      | deployment=mysql-2  |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -pnewuser -D sampledb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |

  # @author haowang@redhat.com
  Scenario Outline: Data remains after pod being scaled up from 0 for clustered mysql - mysql-55-rhel7 mysql-57-rhel7
    Given I have a project
    And I download a file from "<file>"
    And I replace lines in "mysql_replica.json":
      | <image> | <%= product_docker_repo %><org_image> |
    And I run the :new_app client command with:
      | file     | <template>                   |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
    And the "mysql-master" PVC becomes :bound within 300 seconds
    And the "mysql-slave" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mysql-slave         |
      | deployment=mysql-slave-1 |
    And a pod becomes ready with labels:
      | name=mysql-master         |
      | deployment=mysql-master-1 |
    Given evaluation of `pod.name` is stored in the :masterpod clipboard
    And I wait up to 200 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mysql -h <%= cb.masterpod %> -u user -puser -D userdb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mysql -h <%= cb.masterpod %> -u user -puser -D userdb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mysql -h <%= cb.masterpod %> -u user -puser -D userdb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |
    When I run the :scale client command with:
      | resource | replicationcontrollers  |
      | name     | mysql-master-1          |
      | replicas | 0                       |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers  |
      | name     | mysql-slave-1          |
      | replicas | 0                  |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers  |
      | name     | mysql-master-1          |
      | replicas | 1                       |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicationcontrollers  |
      | name     | mysql-slave-1          |
      | replicas | 1                  |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mysql-slave         |
      | deployment=mysql-slave-1 |
    And a pod becomes ready with labels:
      | name=mysql-master         |
      | deployment=mysql-master-1 |
    Given evaluation of `pod.name` is stored in the :masterpod clipboard
    And I wait up to 200 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mysql -h <%= cb.masterpod %> -u user -puser -D userdb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |
    Examples:
      | sclname    |image                     | org_image                  | template       | file                                                                                             |
      | mysql55    |openshift/mysql-55-centos7| openshift3/mysql-55-rhel7  | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.5/examples/replica/mysql_replica.json | # @case_id OCP-12045
      | rh-mysql56 |centos/mysql-56-centos7   | rhscl/mysql-56-rhel7       | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.6/examples/replica/mysql_replica.json | # @case_id OCP-12202

  # @author haowang@redhat.com
  Scenario Outline: Data remains after redeployment clustered mysql - mysql-55-rhel7 mysql-56-rhel7
    Given I have a project
    And I download a file from "<file>"
    And I replace lines in "mysql_replica.json":
      | <image> | <%= product_docker_repo %><org_image> |
    And I run the :new_app client command with:
      | file     | <template>                   |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
    Then the step should succeed
    And the "mysql-master" PVC becomes :bound within 300 seconds
    And the "mysql-slave" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mysql-slave         |
      | deployment=mysql-slave-1 |
    And a pod becomes ready with labels:
      | name=mysql-master         |
      | deployment=mysql-master-1 |
    Given evaluation of `pod.name` is stored in the :masterpod clipboard
    And I wait up to 200 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mysql -h <%= cb.masterpod %> -u user -puser -D userdb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mysql -h <%= cb.masterpod %> -u user -puser -D userdb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mysql -h <%= cb.masterpod %> -u user -puser -D userdb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |
    When I run the :deploy client command with:
      | deployment_config | mysql-slave  |
      | latest            |              |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | mysql-master  |
      | latest            |              |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mysql-slave         |
      | deployment=mysql-slave-2 |
    And a pod becomes ready with labels:
      | name=mysql-master         |
      | deployment=mysql-master-2 |
    Given evaluation of `pod.name` is stored in the :masterpod clipboard
    And I wait up to 200 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mysql -h <%= cb.masterpod %> -u user -puser -D userdb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |
    Examples:
      | sclname    |image                     | org_image                  | template       | file                                                                                             |
      | mysql55    |openshift/mysql-55-centos7| openshift3/mysql-55-rhel7  | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.5/examples/replica/mysql_replica.json | # @case_id OCP-12288
      | rh-mysql56 |centos/mysql-56-centos7   | rhscl/mysql-56-rhel7       | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.6/examples/replica/mysql_replica.json | # @case_id OCP-12343

  # @author wzheng@redhat.com
  Scenario Outline: Use default values for memory limits env vars
    Given I have a project
    When I run the :run client command with:
      | name   | mysql                             |
      | image  | <%= product_docker_repo %><image> |
      | env    | MYSQL_ROOT_PASSWORD=test          |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=mysql-1,deploymentconfig=mysql,run=mysql |
    When I execute on the pod:
      | cat | <file> |
    Then the output should contain:
      | max_allowed_packet = 200M     |
      | table_open_cache = 400        |
      | sort_buffer_size = 256K       |
      | key_buffer_size = 8M          |
      | read_buffer_size = 8M         |
      | innodb_buffer_pool_size = 32M |
      | innodb_log_file_size = 8M     |
      | innodb_log_buffer_size = 8M   |

    Examples:
      | image                     | file                                         |
      | rhscl/mysql-56-rhel7      | /etc/my.cnf.d/50-my-tuning.cnf               | # @case_id OCP-12067
