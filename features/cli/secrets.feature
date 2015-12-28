Feature: secrets related scenarios
  # @author pruan@redhat.com
  # @case_id 484328
  Scenario: Can not convert to secrets with non-existing files
    Given I have a project
    And I run the :secrets client command with:
      | action       | new      |
      | secrets_name | tc483168 |
      | name | I_do_not_exist |
    Then the step should fail
    And the output should contain:
      | error: error reading I_do_not_exist: no such file or directory |

  # @author wjiang@redhat.com
  # @case_id 490966
  Scenario: Generate dockercfg type secrets via oc secrets new-dockercfg
    Given I have a project
    When I run the :new_dockercfg client command with:
      |secret_name      |test                     |
      |docker_email     |serviceaccount@redhat.com|
      |docker_password  |password                 |
      |docker_server    |dockerregistry.io        |
      |docker_username  |serviceaccount           |
    Then the step should succeed
    When I run the :get client command with:
      |resource     |secrets  |
      |resource_name|test     |
    Then the step should succeed
    And the output should contain:
      |kubernetes.io/dockercfg|
