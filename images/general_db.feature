Feature: general_db.feature

  # @author haowang@redhat.com
  # @case_id OCP-10581
  Scenario: Add env variables to mongodb24 image
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mongodb-24-rhel7-env-test.json" replacing paths:
      | ["spec"]["template"]["spec"]["containers"][0]["image"] | <%= product_docker_repo %>openshift3/mongodb-24-rhel7 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=database      |
    When I execute on the pod:
      | bash               |
      | -c                 |
      | env \| grep MONGO  |
    Then the output should contain:
      | MONGODB_NOPREALLOC=false |
      | MONGODB_QUIET=false      |
      | MONGODB_SMALLFILES=false |
    When I execute on the pod:
      | cat | /etc/mongod.conf   |
    Then the output should contain:
      | noprealloc = false       |
      | smallfiles = false       |
      | quiet = false            |

  # @author haowang@redhat.com
  # @case_id OCP-12044
  Scenario: Add env variables to mongodb26 image
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mongodb-26-rhel7-env-test.json" replacing paths:
      | ["spec"]["template"]["spec"]["containers"][0]["image"] | <%= product_docker_repo %>rhscl/mongodb-26-rhel7 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=database      |
    When I execute on the pod:
      | bash               |
      | -c                 |
      | env \| grep MONGO  |
    Then the output should contain:
      | MONGODB_PREALLOC=true    |
      | MONGODB_QUIET=false      |
      | MONGODB_SMALLFILES=false |
    When I execute on the pod:
      | cat | /etc/mongod.conf   |
    Then the output should contain:
      | preallocDataFiles: true  |
      | smallFiles: false        |
      | quiet: false             |

  # @author haowang@redhat.com
  # @case_id OCP-9723
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
      | bash | -lc | mongo admin -u admin -padmin  --eval 'printjson(db.serverStatus())' |
    Then the step should succeed
    """
    And the output should contain:
      | "ok" : 1 |

  # @author haowang@redhat.com
  # @case_id OCP-12538
  Scenario: Verify mongodb can be connect after change admin and user password or re-deployment for ephemeral storage - mongodb-26-rhel7
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mongodb-ephemeral-template.json"
    When I run the :new_app client command with:
      | file  | mongodb-ephemeral-template.json |
      | param | MONGODB_ADMIN_PASSWORD=admin    |
      | param | MONGODB_VERSION=2.6             |
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
    When I run the :set_env client command with:
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
    When I run the :set_env client command with:
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
      | openshift3/mongodb-24-rhel7 | mongodb24    | 2.4    | # @case_id OCP-11165
      | rhscl/mongodb-26-rhel7      | rh-mongodb26 | 2.6    | # @case_id OCP-12491
      | rhscl/mongodb-32-rhel7      | rh-mongodb32 | 3.2    | # @case_id OCP-12437

  # @author haowang@redhat.com
  # @case_id OCP-9580
  Scenario: mongodb persistent template
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mongodb-persistent-template.json"
    Then I run the :new_app client command with:
      | file  |mongodb-persistent-template.json|
      | param | MONGODB_ADMIN_PASSWORD=admin   |
      | param | MONGODB_VERSION=2.6   |
    Then the step should succeed
    And the "mongodb" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mongodb          |
      | deployment=mongodb-1  |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo admin -u admin -padmin --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 2.6 |

  # @author haowang@redhat.com
  # @case_id OCP-9852
  Scenario: mongodb 24 with persistent volume
    Given I have a project
    Then I run the :new_app client command with:
      | file     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mongodb24-persistent-template.json |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
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
  # @case_id OCP-9579
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
      | bash |
      | -c   |
      | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'create table test (age INTEGER(32));' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -c   |
      | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'insert into test VALUES(10);' |
    Then the step should succeed
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash |
      | -c   |
      | mysql -h 127.0.0.1 -u user -puser -D sampledb -e 'select * from  test;' |
    Then the step should succeed
    """
    And the output should contain:
      | 10 |

  # @author xiuwang@redhat.com
  # @case_id OCP-11597
  @smoke
  Scenario: Create mongo resources with persistent template for mongodb-32-rhel7 images
    Given I have a project
    Then the step should succeed
    Then I run the :new_app client command with:
      | template | mongodb-persistent |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
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
  # @case_id OCP-12159
  Scenario: create resource via oc new-app mongodb-32-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | docker_image      | <%= product_docker_repo %>rhscl/mongodb-32-rhel7 |
      | insecure_registry | true                                             |
      | name              | mongodb32                                        |
      | env               | MONGODB_USER=user                                |
      | env               | MONGODB_PASSWORD=pass                            |
      | env               | MONGODB_DATABASE=db                              |
      | env               | MONGODB_ADMIN_PASSWORD=pass                      |
    Then the step should succeed
    Given I wait for the "mongodb32" service to become ready up to 300 seconds
    And I get the service pods
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
  # @case_id OCP-12463
  Scenario: Verify mongodb can be connect after change admin and user password or re-deployment for ephemeral storage - mongodb-32-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | template | mongodb-ephemeral         |
      | param | MONGODB_ADMIN_PASSWORD=admin |
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
    When I run the :set_env client command with:
      | resource | dc/mongodb |
      | e        | MONGODB_ADMIN_PASSWORD=newadmin |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mongodb         |
      | deployment=mongodb-2 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo admin -u admin -pnewadmin --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 3.2 |

  # @author haowang@redhat.com
  # @case_id OCP-11011
  Scenario: Mongodb replica petset example with persistent storage
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/sclorg/mongodb-container/master/examples/petset/mongodb-petset-persistent.yaml |
      | p    | MONGODB_USER=user                                                                                                |
      | p    | MONGODB_PASSWORD=pass                                                                                            |
      | p    | MONGODB_DATABASE=db                                                                                              |
      | p    | MONGODB_ADMIN_PASSWORD=pass                                                                                      |
    Then the step should succeed
    And the "mongo-data-mongodb-0" PVC becomes :bound within 300 seconds
    Given I wait for the "mongo-data-mongodb-1" pvc to appear up to 120 seconds
    And the "mongo-data-mongodb-1" PVC becomes :bound within 300 seconds
    Given I wait for the "mongo-data-mongodb-2" pvc to appear up to 120 seconds
    And the "mongo-data-mongodb-2" PVC becomes :bound within 300 seconds
    And 3 pods become ready with labels:
      | name=mongodb |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the "mongodb-0" pod:
      | bash                                                               |
      | -c                                                                 |
      | mongo db -uuser -ppass --eval "db.db.insert({'name':'openshift'})" |
    Then the step should succeed
    """
    When I execute on the "mongodb-0" pod:
      | bash                                                       |
      | -c                                                         |
      | mongo db -uuser -ppass --eval "printjson(db.db.findOne())" |
    Then the step should succeed
    And the output should contain:
      | name      |
      | openshift |
    When I run the :delete client command with:
      | object_type | pods |
      | all         |      |
    Then the step should succeed
    And 3 pods become ready with labels:
      | name=mongodb |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the "mongodb-0" pod:
      | bash |
      | -c   |
      | mongo db -uuser -ppass --eval "rs.slaveOk(),printjson(db.db.findOne())" |
    Then the step should succeed
    """
    And the output should contain:
      | name      |
      | openshift |
