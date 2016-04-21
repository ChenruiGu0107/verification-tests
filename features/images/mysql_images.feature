Feature: mysql_images.feature
    # @author haowang@redhat.com
    # @case_id 511968
    @admin
    @destructive
    Scenario: mysql persistent template
        Given I have a project
        And I have a NFS service in the project
        Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/auto-nfs-pv.json" where:
            | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
        When I run the :new_app client command with:
            | template | mysql-persistent             |
            | param    | MYSQL_USER=user              |
            | param    | MYSQL_PASSWORD=user          |
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
    # @case_id 501051
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
    # @case_id 501055
    @admin
    @destructive
    Scenario: Verify DB can be connect after change admin and user password and re-deployment for persistent storage - mysql-55-rhel7
        Given I have a project
        And I have a NFS service in the project
        Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/auto-nfs-pv.json" where:
            | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
        And I run the :new_app client command with:
            | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mysql55-persistent-template.json |
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
            | scl | enable | mysql55 | mysql -h 127.0.0.1 -u user -pnewuser -D sampledb -e 'select * from  test;' |
        Then the step should succeed
        """
        And the output should contain:
            | 10 |

    # @author haowang@redhat.com
    # @case_id 508132 508134
    @admin
    @destructive
    Scenario Outline: Data remains after pod being re-created for clustered mysql - mysql-55-rhel7 mysql-56-rhel7
        Given I have a project
        And I have a NFS service in the project
        Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/auto-nfs-pv.json" where:
            | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
        And I run the :new_app client command with:
            | file     | <template>                   |
            | param    | MYSQL_USER=user              |
            | param    | MYSQL_PASSWORD=user          |
        And a pod becomes ready with labels:
            | name=mysql-slave         |
            | deployment=mysql-slave-1 |
        And a pod becomes ready with labels:
            | name=mysql-master         |
            | deployment=mysql-master-1 |
        And I wait up to 60 seconds for the steps to pass:
        """
        When I execute on the pod:
            | scl | enable | <sclname> | mysql -h 127.0.0.1 -u user -puser -D userdb -e 'create table test (age INTEGER(32));' |
        Then the step should succeed
        """
        And I wait up to 60 seconds for the steps to pass:
        """
        When I execute on the pod:
            | scl | enable | <sclname> | mysql -h 127.0.0.1 -u user -puser -D userdb -e 'insert into test VALUES(10);' |
        Then the step should succeed
        """
        And I wait up to 60 seconds for the steps to pass:
        """
        When I execute on the pod:
            | scl | enable | <sclname> | mysql -h 127.0.0.1 -u user -puser -D userdb -e 'select * from  test;' |
        Then the step should succeed
        """
        And the output should contain:
            | 10 |
        When I run the :deploy client command with:
            | deployment_config | mysql-master   |
            | latest            |               |
        Then the step should succeed
        When I run the :deploy client command with:
            | deployment_config | mysql-slave   |
            | latest            |               |
        Then the step should succeed
        And a pod becomes ready with labels:
            | name=mysql-slave         |
            | deployment=mysql-slave-2 |
        And a pod becomes ready with labels:
            | name=mysql-master         |
            | deployment=mysql-master-2 |
        And I wait up to 60 seconds for the steps to pass:
        """
        When I execute on the pod:
            | scl | enable | <sclname> | mysql -h 127.0.0.1 -u user -puser -D userdb -e 'select * from  test;' |
        Then the step should succeed
        """
        And the output should contain:
            | 10 |
        Examples:
            | sclname    | template |
            | mysql55    | https://raw.githubusercontent.com/openshift/mysql/master/5.5/examples/replica/mysql_replica.json |
            | rh-mysql56 | https://raw.githubusercontent.com/openshift/mysql/master/5.6/examples/replica/mysql_replica.json |


