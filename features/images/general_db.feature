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
    Then I wait for a web server to become available via the "jws-http-route" route

  # @author haowang@redhat.com
  # @case_id 473389 508066
  Scenario Outline: Add env variables to mongodb image
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/<template>" replacing paths:
      | ["spec"]["template"]["spec"]["containers"][0]["image"] | <%= product_docker_repo %><image>|
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
      | template                            | command                                         | image             |
      | mongodb-24-rhel7-env-test.json      | scl enable mongodb24 "cat /etc/mongod.conf"     | openshift3/mongodb-24-rhel7  |
      | mongodb-26-rhel7-env-test.json      | scl enable rh-mongodb26 "cat /etc/mongod.conf"  | rhscl/mongodb-26-rhel7  |

  # @author haowang@redhat.com
  # @case_id 511971
  Scenario: Create mongodb resources via installed ephemeral template on web console
    Given I have a project
    When I run the :new_app client command with:
      | template | mongodb-ephemeral            |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
    And a pod becomes ready with labels:
      | name=mongodb|
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | rh-mongodb26 | mongo admin -u admin -padmin  --eval 'printjson(db.serverStatus())' |
    Then the step should succeed
    """
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
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | rh-mongodb26 | mongo admin -u admin -padmin  --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 2.6 |
    When I run the :env client command with:
      | resource | dc/mongodb |
      | e        | MONGODB_ADMIN_PASSWORD=newadmin |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mongodb          |
      | deployment=mongodb-2  |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | rh-mongodb26 | mongo admin -u admin -pnewadmin  --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 2.6 |

  # @author haowang@redhat.com
  # @case_id 500991 508085 529330
  Scenario Outline: Verify cluster mongodb can be connect after change admin and user password or redeployment for ephemeral storage - mongodb-24-rhel7 mongodb-26-rhel7
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/mongodb/master/2.4/examples/replica/mongodb-clustered.json"
    And I replace lines in "mongodb-clustered.json":
      | openshift/mongodb-24-centos7 | <%= product_docker_repo %><image> |
    When I run the :new_app client command with:
      | file     | mongodb-clustered.json  |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
    And 3 pods become ready with labels:
      | name=mongodb-replica  |
      | deployment=mongodb-1  |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mongo admin -u admin -padmin  --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | <output> |
    When I run the :env client command with:
      | resource | dc/mongodb |
      | e        | MONGODB_ADMIN_PASSWORD=newadmin |
    Then the step should succeed
    And 3 pods become ready with labels:
      | name=mongodb-replica  |
      | deployment=mongodb-2  |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | <sclname> | mongo admin -u admin -pnewadmin  --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | <output> |
    Examples:
      | image                       | sclname      | output |
      | openshift3/mongodb-24-rhel7 | mongodb24    | 2.4    |
      | rhscl/mongodb-26-rhel7      | rh-mongodb26 | 2.6    |
      | rhscl/mongodb-32-rhel7      | rh-mongodb32 | 3.2    |

  # @author haowang@redhat.com
  # @case_id 498006
  Scenario: mongodb persistent template
    Given I have a project
    Then I run the :new_app client command with:
      | template | mongodb-persistent |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mongodb                                                                         |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "mongodb" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mongodb          |
      | deployment=mongodb-1  |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | rh-mongodb26 | mongo admin -u admin -padmin  --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 2.6 |
  # @author haowang@redhat.com
  # @case_id 519474
  Scenario: mongodb 24 with persistent volume
    Given I have a project
    Then I run the :new_app client command with:
      | file     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mongodb24-persistent-template.json |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mongodb                                                                         |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "mongodb" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mongodb          |
      | deployment=mongodb-1  |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | scl | enable | mongodb24 | mongo admin -u admin -padmin  --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 2.4 |
  # @author haowang@redhat.com
  # @case_id 498005
  Scenario: Create app using mysql-ephemeral template
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-ephemeral              |
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

  # @author xiuwang@redhat.com
  # @case_id 529316
  Scenario: Create mongo resources with persistent template for mongodb-32-rhel7 images
    Given I have a project
    When I run the :import_image client command with:
      | image_name | mongodb:3.2 |
      | from | <%= product_docker_repo %>rhscl/mongodb-32-rhel7 |
      | confirm  | true |
      | insecure | true |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mongodb-persistent-template.json" 
    And I replace lines in "mongodb-persistent-template.json":
      |mongodb:latest|mongodb:3.2|
      |${NAMESPACE}|<%= project.name %>|
    Then I run the :new_app client command with:
      | file  |mongodb-persistent-template.json| 
      | param | MONGODB_ADMIN_PASSWORD=admin   |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mongodb                                                                         |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "mongodb" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mongodb         |
      | deployment=mongodb-1 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo admin -u admin -padmin --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 3.2 |

  # @author xiuwang@redhat.com
  # @case_id 529320
  Scenario: create resource via oc new-app mongodb-32-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | docker_image      | <%= product_docker_repo %>rhscl/mongodb-32-rhel7 |
      | insecure_registry | true      |
      | name              | mongodb32 |
      | env               | MONGODB_USER=user,MONGODB_PASSWORD=pass,MONGODB_DATABASE=db,MONGODB_ADMIN_PASSWORD=pass |
    Then the step should succeed
    Given I wait for the "mongodb32" service to become ready
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -c   |
      | mongo db -uuser -ppass --eval "db.db.insert({'name':'openshift'})" |
    Then the step should succeed
    """
    When I execute on the pod:
      | bash |
      | -c   |
      | mongo db -uuser -ppass --eval "printjson(db.db.findOne())" |
    Then the step should succeed
    And the output should contain:
      | name |
      | openshift |

  # @author xiuwang@redhat.com
  # @case_id 529333
  Scenario: Verify mongodb can be connect after change admin and user password or re-deployment for ephemeral storage - mongodb-32-rhel7
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mongodb-ephemeral-template.json"
    When I run the :import_image client command with:
      | image_name | mongodb:3.2 |
      | from | <%= product_docker_repo %>rhscl/mongodb-32-rhel7 |
      | confirm  | true |
      | insecure | true |
    Then the step should succeed
    And I replace lines in "mongodb-ephemeral-template.json":
      |mongodb:latest|mongodb:3.2|
      |${NAMESPACE}|<%= project.name %>|
    When I run the :new_app client command with:
      | file  | mongodb-ephemeral-template.json |
      | param | MONGODB_ADMIN_PASSWORD=admin    |
    And a pod becomes ready with labels:
      | name=mongodb         |
      | deployment=mongodb-1 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo admin -u admin -padmin --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 3.2 |
    When I run the :env client command with:
      | resource | dc/mongodb |
      | e        | MONGODB_ADMIN_PASSWORD=newadmin |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mongodb         |
      | deployment=mongodb-2 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo admin -u admin -padmin --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 3.2 |
