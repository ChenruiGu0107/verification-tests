Feature: project permissions

  # @author akostadi@redhat.com
  # @case_id 470300
  @admin
  Scenario: Admin could get/edit/delete the project resources
    ## create project without any user admins
    When admin creates a project
    Then the step should succeed
    And I run the :new_app admin command with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | myapp                |
      | n            | <%= project.name %>  |
      | l            | app=app1             |
    Then the step should succeed

    ## add a user as admin of the project
    When I run the :add_role_to_user admin command with:
      | role            |   admin               |
      | user name       |   <%= user.name %>    |
      | n               |   <%= project.name %> |
    Then the step should succeed

    ## switch user to the test project
    When I use the "<%= project.name %>" project
    Then the step should succeed

    ## test the admin user can actually manage the resources
    When I expose the "myapp" service
    Then the step should succeed

    ## test user can see all project resources
    Given I wait for the "myapp" service to become ready

    When I get project pods
    Then the step should succeed
    And the output should contain:
      |myapp-1-build|
    When I get project services
    Then the step should succeed
    And the output should contain:
      |deploymentconfig=myapp|
    When I get project builds
    Then the step should succeed
    And the output should contain:
      |myapp-1|
      |Source|
    When I get project buildConfigs
    Then the step should succeed
    And the output should contain:
      |SOURCE|
      |ruby-hello-world|
    When I get project replicationcontroller
    Then the step should succeed
    And the output should contain:
      |REPLICAS|
      |deploymentconfig=myapp|
    When I get project imagestream
    Then the step should succeed
    And the output should contain:
      |myapp|
      |DOCKER REPO|
    When I get project deploymentconfig
    Then the step should succeed
    And the output should contain:
      |TRIGGERS|
      |ConfigChange|
      |myapp|

    ## clean-up mess
    When I delete all resources by labels:
     | app=app1 |

    ## create another app and check user has full admin rights
    When I create a new application with:
      | docker image | openshift/mysql-55-centos7                              |
      | code         | https://github.com/openshift/ruby-hello-world           |
      | l            | app=hi                                                  |
      | env          | MYSQL_USER=root,MYSQL_PASSWORD=test,MYSQL_DATABASE=test |
    Then the step should succeed

    # check MySQL pod
    Given a pod becomes ready with labels:
      | deployment=mysql-55-centos7-1 |
    When I execute on the pod:
      | bash                                                  |
      | -c                                                    |
      | mysql -h $HOSTNAME -uroot -ptest -e 'show databases;' |
    Then the step should succeed
    And the output should contain "test"

    # access mysql through the service
    Given I use the "mysql-55-centos7" service
    And I reload the service
    When I execute on the pod:
      | bash                                                           |
      | -c                                                             |
      | mysql -h <%= service.ip %> -uroot -ptest -e 'show databases;'  |
    Then the step should succeed
    And the output should contain "test"

    ## test delete project
    When I delete the project
    Then the step should succeed
