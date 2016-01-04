Feature: general_db.feature

  # @author cryan@redhat.com
  # @case_id 484487
  Scenario: Use mysql in openshift app
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc484487/jws-app-secret.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc484487/jboss-image-streams.json |
      | n | <%= project.name %> |
    Then the step should succeed
    And the output should contain "jboss-webserver3-tomcat7-openshift"
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc484487/jws-tomcat7-mysql-sti.json"
    #The following replacements occur because the original lines violate
    #the 15 char name limit otherwise
    Given I replace lines in "jws-tomcat7-mysql-sti.json":
      | jws-app | jws |
      | -mysql-tcp-3306 | -tcp-3306 |
      | jws.local | |
    When I run the :new_app client command with:
      | file | jws-tomcat7-mysql-sti.json |
    Then the step should succeed
    When I use the "jws-http-service" service
    Then I wait for a server to become available via the "jws-http-route" route
  # @author haowang@redhat.com
  # @case_id 473389
  Scenario: Add env variables to mongodb-24-rhel7 image
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mongodb-24-rhel7-env-test.json"
    And I replace lines in "mongodb-24-rhel7-env-test.json":
      | registry.access.redhat.com/openshift3/mongodb-24-rhel7 | <%= product_docker_repo %>openshift3/mongodb-24-rhel7|
    When I run the :create client command with:
      | f | mongodb-24-rhel7-env-test.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=database|
    When I execute on the pod:
      | bash               |
      | -c                 |
      | env \| grep MONGO  |
    Then the output should contain:
      | MONGODB_NOPREALLOC=false |
      | MONGODB_QUIET=false      |
      | MONGODB_SMALLFILES=false |
    When I execute on the pod:
      | bash               |
      | -c                 |
      | scl enable mongodb24 "cat /etc/mongod.conf" |
    Then the output should contain:
      | noprealloc = false |
      | smallfiles = false |
      | quiet = false      |
