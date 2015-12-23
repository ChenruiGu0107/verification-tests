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
