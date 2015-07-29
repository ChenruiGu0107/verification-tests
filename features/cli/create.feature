Feature: creating 'apps' with CLI

  # @author akostadi@redhat.com
  # @case_id 482262
  Scenario: Create an application with overriding app name
    Given I have a project
    And I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | myapp                |
      # | namespace    | <%= @project.name %> |
    Then the step should succeed
    When I expose "myapp" service
    Then the step should succeed
    And I wait for a server to become available via the route
    And the project is deleted

    ## recreate project between each test because of
    #    https://bugzilla.redhat.com/show_bug.cgi?id=1233503
    ## create app with broken labels
    Given I have a project
    When I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | upperCase |
    Then the step should fail
    And the project is deleted

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

    # TODO: check mysql
    # service access via ip and hostname
    # delete all resources with label
    # check all is gone
