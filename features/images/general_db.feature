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
  # @case_id 473389 508066
  Scenario Outline: Add env variables to mongodb image
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/<template>"
    And I replace lines in "<template>":
      | registry.access.redhat.com/openshift3/ | <%= product_docker_repo %>openshift3/|
    When I run the :create client command with:
      | f | <template> |
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
      | bash       |
      | -c         |
      | <command>  |
    Then the output should contain:
      | noprealloc = false |
      | smallfiles = false |
      | quiet = false      |
    Examples:
      | template                            | command                                         |
      | mongodb-24-rhel7-env-test.json      | scl enable mongodb24 "cat /etc/mongod.conf"     |
      | mongodb-26-rhel7-env-test.json      | scl enable rh-mongodb26 "cat /etc/mongod.conf"  |

  # @author haowang@redhat.com
  # @case_id 511971
  Scenario: Create mongodb resources via installed ephemeral template on web console
    Given I have a project
    When I run the :new_app client command with:
      | template | mongodb-ephemeral            |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
    And a pod becomes ready with labels:
      | name=mongodb|
    And 30 seconds have passed
    When I execute on the pod:
      | noescape: scl enable rh-mongodb26 "mongo admin -u admin -padmin  --eval 'printjson(db.serverStatus())'"  |
    Then the step should succeed
    And the output should contain:
      | "ok" : 1 |

  # @author haowang@redhat.com
  # @case_id 508094
  Scenario: Verify mongodb can be connect after change admin and user password or re-deployment for ephemeral storage - mongodb-26-rhel7
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mongodb-ephemeral-template.json"
    And I replace lines in "mongodb-ephemeral-template.json":
      | latest | 2.6 |
    When I run the :new_app client command with:
      | file | mongodb-ephemeral-template.json  |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
    And a pod becomes ready with labels:
      | name=mongodb          |
      | deployment=mongodb-1  |
    And 30 seconds have passed
    When I execute on the pod:
      | noescape: scl enable rh-mongodb26 "mongo admin -u admin -padmin  --eval 'db.version()'"  |
    Then the step should succeed
    And the output should contain:
      | 2.6 |
    When I run the :env client command with:
      | resource | dc/mongodb |
      | e        | MONGODB_ADMIN_PASSWORD=newadmin |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mongodb          |
      | deployment=mongodb-2  |
    And 30 seconds have passed
    When I execute on the pod:
      | noescape: scl enable rh-mongodb26 "mongo admin -u admin -pnewadmin  --eval 'db.version()'"  |
    Then the step should succeed
    And the output should contain:
      | 2.6 |
