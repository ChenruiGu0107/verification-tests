Feature: creating 'apps' with CLI

  # @author akostadi@redhat.com
  # @case_id 482262
  @smoke
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

  #@author xxing@redhat.com
  #@case_id 470351
  Scenario: Create application from template via cli
    Given I have a project
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json|
    And I create a new application with:
      |template|ruby-helloworld-sample|
      |param   |MYSQL_USER=admin,MYSQL_PASSWORD=admin,MYSQL_DATABASE=xxingtest|
    Then the step should succeed
    Given I wait for the "frontend" service to become ready
    When I execute on the pod:
      | bash                       |
      | -c                         |
      | curl -k <%= service.url %> |
    Then the step should succeed
    And the output should contain "Demo App"
    Given I wait for the "database" service to become ready
    When I execute on the pod:
      | bash                                                           |
      | -c                                                             |
      | mysql -h <%= service.ip %> -P5434 -uadmin -padmin -e 'show databases;'|
    Then the step should succeed
    And the output should contain "xxingtest"

  # @author wsun@redhat.com
  # case_id 476293
  Scenario: Could not create any context in non-existent project
    Given I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | myapp          |
      | n            | noproject      |
    Then the step should fail
    Then the output should contain "Error: User "<%=@user.name%>" cannot create imagestreams in project "noproject""
    Then the output should contain "Error: User "<%=@user.name%>" cannot create buildconfigs in project "noproject""
    Then the output should contain "Error: User "<%=@user.name%>" cannot create services in project "noproject""
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
      | n | noproject |
    Then the step should fail
    Then the output should contain "User "<%=@user.name%>" cannot create pods in project "noproject""
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
      | n | noproject |
    Then the step should fail
    Then the output should contain "User "<%=@user.name%>" cannot create deploymentconfigs in project "noproject""
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json |
      | n | noproject |
    Then the step should fail
    Then the output should contain "Error from server: User "<%=@user.name%>" cannot create imagestreams in project "noproject""
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | n | noproject |
    Then the step should fail
    Then the output should contain "User "<%=@user.name%>" cannot create templates in project "noproject""

  # @author anli@redhat.com
  # @case_id 470297
  Scenario: Project admin could not grant cluster-admin permission to other users
    When I have a project
    And I run the :oadm_add_cluster_role_to_user client command with:
      | role_name | cluster-admin  | 
      | user_name | <%= user(1).name %>  |
    Then the step should fail
    And the output should contain "cannot get clusterpolicybindings at the cluster scope"
