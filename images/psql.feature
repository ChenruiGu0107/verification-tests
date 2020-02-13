Feature: Postgresql images test

  # @author wewang@redhat.com
  Scenario Outline: Verify DB can be connect after change admin and user password and re-deployment for ephemeral storage - psql
    Given I have a project
    When I run the :new_app client command with:
      | template | postgresql-ephemeral         |
      | p        | POSTGRESQL_VERSION=<version> |
    Then the step should succeed
    And a pod becomes ready with labels:
      |name=postgresql|
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'CREATE TABLE tbl (col1 VARCHAR(20), col2 VARCHAR(20));' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    """
    And the output should contain:
      | CREATE TABLE |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c "INSERT INTO tbl (col1,col2) VALUES ('foo1', 'bar1');" -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | INSERT 0 1 |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | col1 | col2 |
      | foo1 | bar1 |
    #Change the postgresql password
    When I run the :set_env client command with:
      | resource |  dc/postgresql  |
      | e        | POSTGRESQL_PASSWORD=redhat  |
    Then the step should succeed
    # list environment variables
    When I run the :set_env client command with:
      | resource | dc/postgresql    |
      | list     | true        |
    Then the step should succeed
    And the output should contain:
      | POSTGRESQL_PASSWORD=redhat |
    And a pod becomes ready with labels:
      |name=postgresql|
      |deployment=postgresql-2|
    Given I wait for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should fail
    """
    And the output should contain:
      | relation "tbl" does not exist |
 
    Examples:
      | version |
      | 9.2     |  # @case_id OCP-11916 
      | 9.4     |  # @case_id OCP-12520 
      | 9.5     |  # @case_id OCP-11799 

  # @author wewang@redhat.com
  Scenario Outline: Verify clustered postgresql can be connect after redeployment
    Given I have a project
    And I download a file from "<file>"
    And I replace lines in "postgresql_replica.json":
      | <org_image> | <new_image> |
    And I run the :new_app client command with:
      | file     | <template>                   |
    Then the step should succeed
    And the "postgresql-data-claim" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=postgresql-slave|
      | deployment=postgresql-slave-1|
    And a pod becomes ready with labels:
      | name=postgresql-master         |
      | deployment=postgresql-master-1 |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'CREATE TABLE tbl (col1 VARCHAR(20), col2 VARCHAR(20));' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    """
    And the output should contain:
      | CREATE TABLE |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c "INSERT INTO tbl (col1,col2) VALUES ('foo1', 'bar1');" -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | INSERT 0 1 |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | col1 | col2 |
      | foo1 | bar1 |

    # Change the postgresql password
    When I run the :set_env client command with:
      | resource | dc/postgresql-master        |
      | e        | POSTGRESQL_PASSWORD=redhat  |
      | e        | POSTGRESQL_ADMIN_PASSWORD=redhat  |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | dc/postgresql-slave         |
      | e        | POSTGRESQL_PASSWORD=redhat  |
      | e        | POSTGRESQL_ADMIN_PASSWORD=redhat  |
    Then the step should succeed
    # list environment variables
    When I run the :set_env client command with:
      | resource | dc/postgresql-master    |
      | list     | true        |
    Then the step should succeed
    And the output should contain:
      | POSTGRESQL_PASSWORD=redhat |
      | POSTGRESQL_ADMIN_PASSWORD=redhat |
    And a pod becomes ready with labels:
      | name=postgresql-slave|
      | deployment=postgresql-slave-2|
    And a pod becomes ready with labels:
      | name=postgresql-master         |
      | deployment=postgresql-master-2 |
    # list environment variables
    When I run the :set_env client command with:
      | resource | dc/postgresql-master    |
      | list     | true        |
    Then the step should succeed
    And the output should contain:
      | POSTGRESQL_PASSWORD=redhat |
      | POSTGRESQL_ADMIN_PASSWORD=redhat |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    """
    And the output should contain:
      | col1 | col2 |
      | foo1 | bar1 |

    #Re-deploy both master and slave pods
    When I run the :deploy client command with:
      | deployment_config | postgresql-slave  |
      | latest            |              |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | postgresql-master  |
      | latest            |              |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=postgresql-slave|
      | deployment=postgresql-slave-3|
    And a pod becomes ready with labels:
      | name=postgresql-master         |
      | deployment=postgresql-master-3 |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    """
    And the output should contain:
      | col1 | col2 |
      | foo1 | bar1 |
    Examples:
      | file                     |   org_image    |  new_image | template|
      |  https://raw.githubusercontent.com/openshift/postgresql/master/examples/replica/postgresql_replica.json  | postgresql:9.5 | postgresql:9.4 | postgresql_replica.json |
      |  https://raw.githubusercontent.com/openshift/postgresql/master/examples/replica/postgresql_replica.json  | postgresql:9.5 | postgresql:9.2 | postgresql_replica.json |
      |  https://raw.githubusercontent.com/openshift/postgresql/master/examples/replica/postgresql_replica.json  |                |                | postgresql_replica.json | # @case_id OCP-12446

  # @author wewang@redhat.com
  @smoke
  Scenario Outline: Verify DB can be connect after change admin and user password and re-deployment for persistent storage
    Given I have a project
    When I run the :new_app client command with:
      | template | postgresql-persistent        |
      | p        | POSTGRESQL_VERSION=<version> |
    Then the step should succeed
    And the "postgresql" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      |name=postgresql|
      |deployment=postgresql-1|

    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'CREATE TABLE tbl (col1 VARCHAR(20), col2 VARCHAR(20));' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    """
    And the output should contain:
      | CREATE TABLE |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c "INSERT INTO tbl (col1,col2) VALUES ('foo1', 'bar1');" -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | INSERT 0 1 |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | col1 | col2 |
      | foo1 | bar1 |
    # Change the postgresql password
    When I run the :set_env client command with:
      | resource |  dc/postgresql  |
      | e        | POSTGRESQL_PASSWORD=redhat  |
    Then the step should succeed
    # list environment variables
    When I run the :set_env client command with:
      | resource | dc/postgresql    |
      | list     | true        |
    Then the step should succeed
    And the output should contain:
      | POSTGRESQL_PASSWORD=redhat |
    And a pod becomes ready with labels:
      |name=postgresql|
      |deployment=postgresql-2|
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    """
    And the output should contain:
      | col1 | col2 |
      | foo1 | bar1 |
    
    Examples:
      | version |
      | 9.5     |   # @case_id OCP-12070 
      | 9.4     |   # @case_id OCP-12509
      | 9.2     |   # @case_id OCP-11514
