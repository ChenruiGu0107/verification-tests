Feature: oc_env.feature

  # @author cryan@redhat.com
  # @case_id 479287
  Scenario: Display environment variables for resources
    Given I have a project
    And I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    And the step succeeded
    When I run the :env client command with:
      | resource | rc/database-1 |
      | list | true |
    Then the step should succeed
    And the output should contain:
      |MYSQL_USER    |
      |MYSQL_PASSWORD|
      |MYSQL_DATABASE|
    When I run the :env client command with:
      | resource | rc |
      | list | true |
      | all  | true |
    Then the step should succeed
    And the output should contain:
      |MYSQL_USER    |
      |MYSQL_PASSWORD|
      |MYSQL_DATABASE|

  # @author yapei@redhat.com
  # @case_id 479289
  Scenario: Set environment variables for resources
    Given I have a project
    And I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    And the step succeeded
    # set one enviroment variable
    When I run the :env client command with:
      | resource | rc/database-1 |
      | e        | key=value     |
    Then the step should succeed
    When I run the :env client command with:
      | resource | rc/database-1 |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      | MYSQL_USER     |
      | MYSQL_PASSWORD |
      | MYSQL_DATABASE |
      | key=value      |
    # set multiple enviroment variables
    When I run the :env client command with:
      | resource | rc/database-1 |
      | e        | key1=value1,key2=value2 |
    Then the step should succeed
    When I run the :env client command with:
      | resource | rc/database-1 |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      | MYSQL_USER     |
      | MYSQL_PASSWORD |
      | MYSQL_DATABASE |
      | key=value      |
      | key1=value1    |
      | key2=value2    |
    # set enviroment variable via STDIN
    When I run the :env client command with:
      | resource | rc/database-1 |
      | e        | -             |
      | _stdin   | key3=value3   |
    Then the step should succeed
    When I run the :env client command with:
      | resource | rc/database-1 |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      | MYSQL_USER     |
      | MYSQL_PASSWORD |
      | MYSQL_DATABASE |
      | key=value      |
      | key1=value1    |
      | key2=value2    |
      | key3=value3    |
    # set invalid enviroment variable
    When I run the :env client command with:
      | resource | rc/database-1 |
      | e        | pe#cial%=1234 |
    Then the step should fail
    And the output should contain:
      | invalid value 'pe#cial%'   |
      | Details: must be a C identifier |
