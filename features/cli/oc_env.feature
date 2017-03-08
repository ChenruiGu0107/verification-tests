Feature: oc_env.feature

  # @author cryan@redhat.com
  # @case_id OCP-10614
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
  # @case_id OCP-11473
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
    And the output should match:
      | can only contain letters, numbers, and underscores |
  # @author yapei@redhat.com
  # @case_id OCP-11715
  Scenario: Update environment variables for resources
    Given I have a project
    And I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    And the step succeeded
    When I run the :get client command with:
      | resource | dc   |
      | o        | json |
    Then the step succeeded
    Given evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :dc_one clipboard
    Given evaluation of `@result[:parsed]['items'][1]['metadata']['name']` is stored in the :dc_two clipboard
    # set environment variables
    When I run the :env client command with:
      | resource | dc   |
      | all      | true |
      | e        | test=1234 |
    Then the step succeeded
    When I run the :env client command with:
      | resource | dc   |
      | list     | true |
      | all      | true |
    Then the step should succeed
    And the output by order should contain:
      | # deploymentconfigs <%= cb.dc_one %> |
      | test=1234 |
      | # deploymentconfigs <%= cb.dc_two %> |
      | test=1234 |
    # update resource environment variable
    When I run the :env client command with:
      | resource | dc/<%= cb.dc_one %> |
      | env_name | test=1234change     |
    Then the step should succeed
    When I run the :env client command with:
      | resource | dc/<%= cb.dc_one %> |
      | list     | true |
    Then the step should succeed
    And the output by order should contain:
      | # deploymentconfigs <%= cb.dc_one %> |
      | test=1234change |
    # update environment variables with --all option
    When I run the :env client command with:
      | resource | dc   |
      | all      | true |
      | env_name | test2=abcchange |
    Then the step should succeed
    When I run the :env client command with:
      | resource | dc   |
      | list     | true |
      | all      | true |
    Then the step should succeed
    And the output by order should contain:
      | # deploymentconfigs <%= cb.dc_one %> |
      | test=1234change |
      | test2=abcchange |
      | # deploymentconfigs <%= cb.dc_two %> |
      | test=1234 |
      | test2=abcchange |
    # diaplay environment variables with json yaml format
    When I run the :env client command with:
      | resource | dc/<%= cb.dc_two %> |
      | env_name | test2=abcchange     |
      | o        | json                |
    Then the step should succeed
    And the output should contain:
      | "name": "test2"      |
      | "value": "abcchange" |

  # @author yapei@redhat.com
  # @case_id OCP-11108
  Scenario: Remove environment variables for resources
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step succeeded
    # set environment variables
    When I run the :env client command with:
      | resource | dc/hooks    |
      | e        | test=1234   |
    Then the step succeeded
    # list environment variables
    When I run the :env client command with:
      | resource | dc/hooks    |
      | list     | true        |
    Then the step should succeed
    And the output should contain:
      | test=1234 |
    # remove environment variables
    When I run the :env client command with:
      | resource | dc/hooks    |
      | env_name | test-       |
    Then the step succeeded
    # list environment variables
    When I run the :env client command with:
      | resource | dc/hooks    |
      | list     | true        |
    Then the step should succeed
    And the output should not contain:
      | test=1234 |
    # set multiple enviroment variables
    When I run the :env client command with:
      | resource | dc/hooks  |
      | e        | key1=value1,key2=value2,key3=value3 |
    Then the step should succeed
    # list environment variables
    When I run the :env client command with:
      | resource | dc/hooks    |
      | list     | true        |
    Then the step should succeed
    And the output should contain:
      | key1=value1 |
      | key2=value2 |
      | key3=value3 |
    # remove multiple environment variables
    When I run the :env client command with:
      | resource | dc/hooks |
      | env_name | key1- |
      | env_name | key2- |
    Then the step should succeed
    # list environment variables
    When I run the :env client command with:
      | resource | dc/hooks    |
      | list     | true        |
    Then the step should succeed
    And the output should not contain:
      | key1=value1 |
      | key2=value2 |

  # @author xiuwang@redhat.com
  # @case_id OCP-11032
  Scenario: Set environment variables when creating application using non-DeploymentConfig template
    Given I have a project
    When I run the :new_app client command with:
      | template | cakephp-mysql-example |
      | env | OPCACHE_REVALIDATE_FREQ=3  |
      | env | APPLE1=apple               |
      | env | APPLE2=tesla               |
      | env | APPLE3=linux               |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=cakephp-mysql-example |
    Given I store in the clipboard the pods labeled:
      | app=cakephp-mysql-example |
    When I run the :env client command with:
      | resource | pods/<%= cb.pods[0].name%> |
      | list     | true                       |
    And the output should contain:
      | OPCACHE_REVALIDATE_FREQ=3 |
      | APPLE1=apple              |
      | APPLE2=tesla              |
      | APPLE3=linux              |
