Feature: Postgresql images test 

  # @author wewang@redhat.com
  # @case_id  508090 501060
  Scenario Outline:  Verify DB can be connect after change admin and user password and re-deployment for ephemeral storage - psql92 and psql94
    Given I have a project
    When I run the :new_app client command with:
      | file | <file_name> |
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
    When I run the :env client command with:
      | resource |  dc/postgresql  |
      | e        | POSTGRESQL_PASSWORD=redhat  |
    Then the step should succeed
    # list environment variables
    When I run the :env client command with:
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
      | file_name                     |
      | https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/postgresql-ephemeral-template.json  |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/postgresql-92-ephemeral-template.json  |
  
 



















 
