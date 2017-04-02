Feature: templates.feature
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

  # @author bingli@redhat.com
  # @case_id OCP-13264
  Scenario: Deploy Redis database using default template "redis-persistent"
  Given I have a project
  When I run the :new_app client command with:
    | template | redis-persistent          |
    | param    | REDIS_PASSWORD=mypassword |
  Then the step should succeed
  And the "redis" PVC becomes :bound within 300 seconds
  And a pod becomes ready with labels:
    | deployment=redis-1 |
  And I wait up to 60 seconds for the steps to pass:
  """
  When I execute on the pod:
    | bash | -c | redis-cli -h 127.0.0.1 -p 6379 -a mypassword append mykey "myvalue" |
  Then the step should succeed
  """ 
  When I execute on the pod:
    | bash | -c | redis-cli -h 127.0.0.1 -p 6379 -a mypassword get mykey |
  Then the step should succeed
  And the output should contain:
    | myvalue |
  When I run the :env client command with:
    | resource | dc/redis                   |
    | e        | REDIS_PASSWORD=newpassword |
  And a pod becomes ready with labels:
    | deployment=redis-2 |
  When I execute on the pod:
    | bash | -c | redis-cli -h 127.0.0.1 -p 6379 -a mypassword get mykey |
  And the output should contain:
    | Authentication required |
  Then I execute on the pod:
    | bash | -c | redis-cli -h 127.0.0.1 -p 6379 -a newpassword get mykey |
  Then the step should succeed
  And the output should contain:
    | myvalue |

  # @author bingli@redhat.com
  # @case_id OCP-10502
  Scenario: Create new application using default template "jenkins-persistent"
  Given I have a project
  When I run the :new_app client command with:
    | template | jenkins-persistent             |
    | param    | JENKINS_SERVICE_NAME=myjenkins |
    | param    | ENABLE_OAUTH=false             |
  Then the step should succeed
  And the "myjenkins" PVC becomes :bound within 300 seconds
  And a pod becomes ready with labels:
    | app=jenkins-persistent |
    | deployment=myjenkins-1 |
  And I get project routes
  Then the output should contain "myjenkins"
  Given I wait up to 300 seconds for the steps to pass:
    """
    When I open web server via the "https://<%= route("myjenkins", service("myjenkins")).dns(by: user) %>/login" url
    Then the output should contain "Jenkins"
    And the output should not contain "ready to work"
    """
  Given I have a browser with:
    | rules    | lib/rules/web/images/jenkins_2/                                      |
    | base_url | https://<%= route("myjenkins", service("myjenkins")).dns(by: user) %> |
  When I perform the :jenkins_standard_login web action with:
    | username | admin    |
    | password | password |
  Then the step should succeed
  Given I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> /Dashboard \[Jenkins\]/ =~ browser.title
    """
  When I perform the :jenkins_create_freestyle_job web action with:
    | job_name | <%= project.name %> |
  Then the step should succeed