Feature: general_db.feature
  # @author haowang@redhat.com
  # @case_id OCP-12044
  Scenario: Add env variables to mongodb26 image
    Given I have a project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/image/db-templates/mongodb-26-rhel7-env-test.json" replacing paths:
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
      | rhscl/mongodb-26-rhel7      | rh-mongodb26 | 2.6    | # @case_id OCP-12491
      | rhscl/mongodb-32-rhel7      | rh-mongodb32 | 3.2    | # @case_id OCP-12437

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
