Feature: mysql_images.feature
  # @author haowang@redhat.com
  # @case_id OCP-9722
  Scenario: mysql persistent template
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent             |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql                                                                           |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "mysql" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mysql|
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | rh-mysql56 | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | rh-mysql56 | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | rh-mysql56 | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |
  # @author haowang@redhat.com
  # @case_id OCP-12342
  Scenario: Verify DB can be connect after change admin and user password and re-deployment for ephemeral storage - mysql-55-rhel7
    Given I have a project
    And I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mysql55-ephemeral-template.json |
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
    When I run the :env client command with:
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
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mysql55-persistent-template.json |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql                                                                           |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
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
    When I run the :env client command with:
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
  # @case_id OCP-11177 OCP-11747 OCP-11837
  Scenario Outline: Data remains after pod being re-created for clustered mysql - mysql-55-rhel7 mysql-56-rhel7
    Given I have a project
    And I download a file from "<file>"
    And I replace lines in "mysql_replica.json":
      | <image> | <%= product_docker_repo %><org_image> |
    And I run the :new_app client command with:
      | file     | <template>                   |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql-master                                                                    |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql-slave                                                                     |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
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
    When I run the :delete client command with:
      | object_type | pods                    |
      | l           | name=mysql-master       |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | name=mysql-slave         |
      | deployment=mysql-slave-1 |
    When I run the :delete client command with:
      | object_type | pods                    |
      | l           | name=mysql-slave        |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | name=mysql-slave         |
      | deployment=mysql-slave-1 |
    And a pod becomes ready with labels:
      | name=mysql-master         |
      | deployment=mysql-master-1 |
    Given evaluation of `pod.name` is stored in the :masternewpod clipboard
    And I wait up to 200 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mysql -h <%= cb.masternewpod %> -u user -puser -D userdb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |
    Examples:
      | sclname    |image                     | org_image                  | template            | file                                                                                             |
      | mysql55    |openshift/mysql-55-centos7| openshift3/mysql-55-rhel7  | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.5/examples/replica/mysql_replica.json | # @case_id OCP-11177
      | rh-mysql56 |centos/mysql-56-centos7   | rhscl/mysql-56-rhel7       | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.6/examples/replica/mysql_replica.json | # @case_id OCP-11747
      | rh-mysql57 |centos/mysql-57-centos7   | rhscl/mysql-57-rhel7       | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.7/examples/replica/mysql_replica.json | # @case_id OCP-11837

  # @author haowang@redhat.com
  # @case_id OCP-12045 OCP-12202
  Scenario Outline: Data remains after pod being scaled up from 0 for clustered mysql - mysql-55-rhel7 mysql-57-rhel7
    Given I have a project
    And I download a file from "<file>"
    And I replace lines in "mysql_replica.json":
      | <image> | <%= product_docker_repo %><org_image> |
    And I run the :new_app client command with:
      | file     | <template>                   |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql-master                                                                    |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql-slave                                                                     |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
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
      | mysql55    |openshift/mysql-55-centos7| openshift3/mysql-55-rhel7  | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.5/examples/replica/mysql_replica.json |
      | rh-mysql56 |centos/mysql-56-centos7   | rhscl/mysql-56-rhel7       | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.6/examples/replica/mysql_replica.json |
  # @author haowang@redhat.com
  # @case_id OCP-12288 OCP-12343
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
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql-master                                                                    |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql-slave                                                                     |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
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
      | mysql55    |openshift/mysql-55-centos7| openshift3/mysql-55-rhel7  | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.5/examples/replica/mysql_replica.json |
      | rh-mysql56 |centos/mysql-56-centos7   | rhscl/mysql-56-rhel7       | mysql_replica.json  | https://raw.githubusercontent.com/openshift/mysql/master/5.6/examples/replica/mysql_replica.json |

  # @author wzheng@redhat.com
  # @case_id OCP-10845,OCP-11278
  Scenario Outline: Check memory limits env vars when pod is set with memory limit
    Given I have a project
    When I run the :run client command with:
      | name   | mysql                             |
      | image  | <%= product_docker_repo %><image> |
      | limits | memory=512Mi                      |
      | env    | MYSQL_ROOT_PASSWORD=test          |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=mysql-1,deploymentconfig=mysql,run=mysql |
    When I execute on the pod:
      | cat | <file> |
    Then the output should contain:
      | key_buffer_size = 51M          |
      | read_buffer_size = 25M         |
      | innodb_buffer_pool_size = 256M |
      | innodb_log_file_size = 76M     |
      | innodb_log_buffer_size = 76M   |

    Examples:
      | image                     | file                                         |
      | openshift3/mysql-55-rhel7 | /opt/rh/mysql55/root/etc/my.cnf.d/tuning.cnf |
      | rhscl/mysql-56-rhel7      | /etc/my.cnf.d/tuning.cnf                     |

  # @author wzheng@redhat.com
  # @case_id OCP-11955,OCP-12067
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
      | openshift3/mysql-55-rhel7 | /opt/rh/mysql55/root/etc/my.cnf.d/tuning.cnf |
      | rhscl/mysql-56-rhel7      | /etc/my.cnf.d/tuning.cnf                     |

  # @author wzheng@redhat.com
  # @case_id OCP-11585,OCP-11789
  Scenario Outline: Use customized values for memory limits env vars
    Given I have a project
    When I run the :run client command with:
      | name   | mysql                             |
      | image  | <%= product_docker_repo %><image> |
      | env    | MYSQL_ROOT_PASSWORD=test,MYSQL_KEY_BUFFER_SIZE=8M,MYSQL_READ_BUFFER_SIZE=8M,MYSQL_INNODB_BUFFER_POOL_SIZE=16M,MYSQL_INNODB_LOG_FILE_SIZE=4M,MYSQL_INNODB_LOG_BUFFER_SIZE=4M |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=mysql-1,deploymentconfig=mysql,run=mysql |
    When I execute on the pod:
      | cat | <file> |
    Then the output should contain:
      | key_buffer_size = 8M          |
      | read_buffer_size = 8M         |
      | innodb_buffer_pool_size = 16M |
      | innodb_log_file_size = 4M     |
      | innodb_log_buffer_size = 4M   |

    Examples:
      | image                      | file                                         |
      | openshift3/mysql-55-rhel7  | /opt/rh/mysql55/root/etc/my.cnf.d/tuning.cnf |
      | rhscl/mysql-56-rhel7       | /etc/my.cnf.d/tuning.cnf                     |

  # @author yantan@redhat.com
  # @case_id OCP-11513
  Scenario: Verify clustered mysql can be connected after password changed - mysql-56-rhel7
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift/mysql/master/5.6/examples/replica/mysql_replica.json"
    Given I replace lines in "mysql_replica.json":
      | centos/mysql-56-centos7   |  <%= product_docker_repo %>rhscl/mysql-56-rhel7 |
    And I run the :new_app client command with:
      | file  | mysql_replica.json  |
      | param | MYSQL_USER=user     |
      | param | MYSQL_PASSWORD=user |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql-master                                                                    |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql-slave                                                                     |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "mysql-master" PVC becomes :bound within 300 seconds
    And the "mysql-slave" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mysql-slave          |
    And a pod becomes ready with labels:
      | name=mysql-master         |
    Given I wait for the "mysql-master" service to become ready
    And I wait up to 200 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | mysql -h mysql-master -u user -puser -D userdb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    When I execute on the pod:
      | bash | -c | mysql -h mysql-master -u user -puser -D userdb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    When I execute on the pod:
      | bash | -c | mysql -h mysql-master -u user -puser -D userdb -e 'select * from  test;' |
    Then the step should succeed
    And the output should contain:
      | 10 |
    When I run the :env client command with:
      | resource | dc/mysql-master        |
      | e        | MYSQL_PASSWORD=newuser |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | mysql -h mysql-master -u user -puser -D userdb -e 'select * from  test;' |
    Then the step should fail
    """
    And a pod becomes ready with labels:
      | name=mysql-master         |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | mysql -h mysql-master -u user -pnewuser -D userdb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |

  # @author xiuwang@redhat.com
  # @case_id OCP-11647
  Scenario: Verify clustered mysql can be connected after password changed - mysql-57-rhel7
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift/mysql/master/5.7/examples/replica/mysql_replica.json"
    Given I replace lines in "mysql_replica.json":
      | centos/mysql-57-centos7   |  <%= product_docker_repo %>rhscl/mysql-57-rhel7 |
    And I run the :new_app client command with:
      | file  | mysql_replica.json  |
      | param | MYSQL_USER=user     |
      | param | MYSQL_PASSWORD=user |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql-master                                                                    |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mysql-slave                                                                     |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "mysql-master" PVC becomes :bound within 300 seconds
    And the "mysql-slave" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mysql-slave          |
    And a pod becomes ready with labels:
      | name=mysql-master         |
    Given I wait for the "mysql-master" service to become ready
    And I wait up to 200 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | rh-mysql57 | mysql -h mysql-master -u user -puser -D userdb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    When I execute on the pod:
      | scl | enable | rh-mysql57 | mysql -h mysql-master -u user -puser -D userdb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    When I execute on the pod:
      | scl | enable | rh-mysql57 | mysql -h mysql-master -u user -puser -D userdb -e 'select * from  test;' |
    Then the step should succeed
    And the output should contain:
      | 10 |
    When I run the :env client command with:
      | resource | dc/mysql-master        |
      | e        | MYSQL_PASSWORD=newuser |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | rh-mysql57 | mysql -h mysql-master -u user -puser -D userdb -e 'select * from  test;' |
    Then the step should fail
    """
    And a pod becomes ready with labels:
      | name=mysql-master         |
      | deployment=mysql-master-2 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | rh-mysql57 | mysql -h mysql-master -u user -pnewuser -D userdb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |
