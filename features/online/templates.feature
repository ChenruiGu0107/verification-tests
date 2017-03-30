Feature: templates.feature
  # @author zhaliu@redhat.com
  # @case_id OCP-12744
  Scenario: Create new application using default template "django-psql-persistent"
    Given I have a project
    When I run the :new_app client command with:
      | template | django-psql-persistent          |
      | param    | NAME=django-psql-persistent     |
      | param    | DATABASE_USER=user              |
      | param    | DATABASE_NAME=testdb            |
    Then the step should succeed
    And the "postgresql" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | deploymentconfig=postgresql |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the "<%= pod.name %>" pod:
      | bash | -c | psql -h 127.0.0.1 -U user -d testdb -c "CREATE TABLE test (product varchar(10));INSERT INTO test VALUES ('openshift');SELECT * FROM test;" |
    Then the step should succeed
    And the output should contain:
      | openshift |
    """
    Then the "django-psql-persistent-1" build was created
    And the "django-psql-persistent-1" build completed
    And I wait for the "django-psql-persistent" service to become ready
    Then I wait up to 60 seconds for a web server to become available via the "django-psql-persistent" route
    Then the output should contain "Welcome to your Django application on OpenShift"

  # @author zhaliu@redhat.com
  # @case_id OCP-12745
  Scenario: Create new application using default template "dancer-mysql-persistent"
    Given I have a project
    When I run the :new_app client command with:
      | template | dancer-mysql-persistent     |
      | param    | NAME=dancer-mysql-persistent              |
      | param    | DATABASE_USER=user              |
      | param    | DATABASE_PASSWORD=user          |
      | param    | DATABASE_NAME=testdb        |
    Then the step should succeed
    And the "database" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | deploymentconfig=database |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the "<%= pod.name %>" pod:
      | bash | -c | mysql -h 127.0.0.1 -u user -puser -D testdb -e 'create table test (name VARCHAR(20));insert into test VALUES("openshift");select * from  test;' |
    Then the step should succeed
    And the output should contain:
      | openshift |
    """
    Then the "dancer-mysql-persistent-1" build was created
    And the "dancer-mysql-persistent-1" build completed
    And I wait for the "dancer-mysql-persistent" service to become ready
    Then I wait up to 60 seconds for a web server to become available via the "dancer-mysql-persistent" route
    Then the output should contain "Welcome to your Dancer application on OpenShift"

  # @author zhaliu@redhat.com
  # @case_id OCP-12743
  Scenario: Create new application using default template "cakephp-mysql-persistent"
    Given I have a project
    When I run the :new_app client command with:
      | template | cakephp-mysql-persistent     |
      | param    | NAME=cakephp-mysql-persistent              |
      | param    | DATABASE_USER=user              |
      | param    | DATABASE_PASSWORD=user          |
      | param    | DATABASE_NAME=testdb        |
    Then the step should succeed
    And the "mysql" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | deploymentconfig=mysql |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the "<%= pod.name %>" pod:
      | bash | -c | mysql -h 127.0.0.1 -u user -puser -D testdb -e 'create table test (name VARCHAR(20));insert into test VALUES("openshift");select * from  test;' |
    Then the step should succeed
    And the output should contain:
      | openshift |
    """
    Then the "cakephp-mysql-persistent-1" build was created
    And the "cakephp-mysql-persistent-1" build completed
    And I wait for the "cakephp-mysql-persistent" service to become ready
    Then I wait up to 60 seconds for a web server to become available via the "cakephp-mysql-persistent" route
    Then the output should contain "Welcome to your CakePHP application on OpenShift"

  # ONLY ONLINE related templates' scripts in this file
  # @author yasun@redhat.com
  # @case_id OCP-10508
  Scenario: mysql persistent template
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent             |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
      | param    | MYSQL_DATABASE=testdb        |
    Then the step should succeed
    And the "mysql" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mysql|
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mysql -h 127.0.0.1 -u user -puser -D testdb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mysql -h 127.0.0.1 -u user -puser -D testdb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mysql -h 127.0.0.1 -u user -puser -D testdb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |

  # @author yasun@redhat.com
  # @case_id OCP-10507
  Scenario: mongodb persistent template
    Given I have a project
    Then I run the :new_app client command with:
      | template | mongodb-persistent           |
      | param    | MONGODB_USER=tester          |
      | param    | MONGODB_PASSWORD=test        |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
      | param    | MONGODB_DATABASE=testdb      |
    Then the step should succeed
    And the "mongodb" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mongodb         |
      | deployment=mongodb-1 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo testdb -u tester -ptest --eval "db.foo.save({'name':'mongouser','address':{'city':'beijing','post':10009},'phone':[138,139]})" |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo testdb -u tester -ptest --eval "db.foo.find()" |
    Then the step should succeed
    """
    And the output should contain:
      | mongouser |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo admin -u admin -padmin --eval "db.user_addr.save({'Uid':'mongouser@redhat.com','Al':['mongouser-1@redhat.com','mongouser-2@redhat.com']})" |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo admin -u admin -padmin --eval "db.user_addr.find()" |
    Then the step should succeed
    """
    And the output should contain:
      | mongouser |

  # @author yasun@redhat.com
  # @case_id OCP-12719
  Scenario: mariadb persistent template
    Given I have a project
    When I run the :new_app client command with:
      | template | mariadb-persistent           |
      | param    | MYSQL_USER=user              |
      | param    | MYSQL_PASSWORD=user          |
      | param    | MYSQL_DATABASE=testdb        |
      | param    | MYSQL_ROOT_PASSWORD=admin    |
    Then the step should succeed
    And the "mariadb" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | deployment=mariadb-1 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | mysql -h <%= pod.name %> -u user -puser -e 'use testdb; create table test (name VARCHAR(20)); insert into test VALUES("openshift");' |
    Then the step should succeed
    """
    When I execute on the pod:
      | bash | -c | mysql -h <%= pod.name %> -u user -puser -e 'use testdb; select * from  test;' |
    Then the step should succeed
    And the output should contain:
      | openshift |
    When I execute on the pod:
      | bash | -c | mysql -h <%= pod.name %> -u root -padmin -e 'use testdb; select * from  test;' |
    Then the step should succeed
    And the output should contain:
      | openshift |
