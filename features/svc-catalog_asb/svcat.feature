Feature: svcat related command

  # @author zhsun@redhat.com
  # @case_id OCP-
  @admin
  Scenario: svcat get command
    Given I have a project
    When I run the :new_app client command with:
      | file        | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | namespace   | <%= project.name %> |
    Then the step should succeed
    When I run the :get client command with:
      | _tool       | svcat     |
      | resource    | instances |
    Then the step should succeed

    When I run the :get admin command with:
      | _tool       | svcat     |
      | resource    | brokers   |
    Then the step should succeed
    And the output should contain:
      | ansible-service-broker  |
