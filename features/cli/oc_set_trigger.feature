Feature: oc set triggers tests
  # @author pruan@redhat.com
  # @case_id 519819
  Scenario: `oc set triggers` with misc flags
    Given I have a project
    And I run the :run client command with:
      | name  | hello                                               |
      | image | <%= project_docker_repo %>openshift/hello-openshift |
      | -l    | title=tc519819                                      |
    Then the step should succeed
    And I run the :run client command with:
      | name  | world                                               |
      | image | <%= project_docker_repo %>openshift/hello-openshift |
      | -l    | title=deadbeef_519819                               |
    Then the step should succeed
    And I run the :set_triggers client command with:
      | resource | dc             |
      | l        | title=tc519819 |
    Then the step should succeed
    And the output should contain "hello"
    And the output should not contain "deadbeef_519819"
    And I run the :set_triggers client command with:
      | resource   | dc   |
      | all        | true |
      | remove_all | true |
    Then the step should succeed
    And I run the :get client command with:
      | resource      | dc      |
      | resource_name | hello   |
      | o             | yaml    |
    Then the step should succeed
    And I save the output to file> dc.yaml
    And I run the :set_triggers client command with:
      | f        | dc.yaml            |
      | o        | go-template        |
      | t        | {{.metadata.name}} |
    Then the step should succeed
    And the output should contain "hello"
    And I run the :set_triggers client command with:
      | resource | dc    |
      | resource | hello |
      | resource | world |
    Then the step should succeed
    And the output should contain:
      | hello |
      | world |
