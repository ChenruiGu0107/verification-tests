Feature: creating 'apps' with CLI

  # @author akostadi@redhat.com
  # @case_id 482262
  Scenario: Create an application with overriding app name
    Given I have a project
    And I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | myapp                |
      # | namespace    | <%= project.name %>  |
    Then the step should succeed
    When I expose "myapp" service
    Then the step should succeed
    And I wait for a server to become available via the route
    And the project is deleted

    ## recreate project between each test because of
    #    https://bugzilla.redhat.com/show_bug.cgi?id=1233503
    ## create app with broken labels
    # disabled for https://bugzilla.redhat.com/show_bug.cgi?id=1251601
    #Given I have a project
    #When I create a new application with:
    #  | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
    #  | name         | upperCase |
    #Then the step should fail
    #And the project is deleted

    # disabled for https://bugzilla.redhat.com/show_bug.cgi?id=1247680
    #Given I have a project
    #When I create a new application with:
    #  | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
    #  | name         | <%= rand_str(25, :dns952) %> |
    #Then the step should fail
    #And the project is deleted

    Given I have a project
    When I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | 4igit-first |
    Then the step should fail
    And the project is deleted

    Given I have a project
    When I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | with#char |
    Then the step should fail
    And the project is deleted

    Given I have a project
    When I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | with^char |
    Then the step should fail
    And the project is deleted

    Given I have a project
    When I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | with@char |
    Then the step should fail
    And the project is deleted

    ## create app with labels
    And I have a project
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

    # access web app through the service
    Given I wait for the "ruby-hello-world" service to become ready
    When I execute on the pod:
      | bash                       |
      | -c                         |
      | curl -k <%= service.url %> |
    Then the step should succeed
    And the output should contain "Demo App"

    # delete resources by label
    When I delete all resources by labels:
     | app=hi |
    Then the step should succeed
    And the project should be empty
