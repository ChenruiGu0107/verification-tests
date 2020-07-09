Feature: env.feature

  # @author shiywang@redhat.com
  # @case_id OCP-11411
  Scenario: Set environment variables when creating application using DeploymentConfig template
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | jenkins-persistent |
      | e        | APPLE1=apple       |
      | e        | APPLE2=tesla       |
      | e        | APPLE3=linux       |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=jenkins-1 |
    When I run the :set_env client command with:
      | resource | pod/<%= pod.name %> |
      | list     | true                |
    And the step should succeed
    And the output should contain:
      | APPLE1=apple |
      | APPLE2=tesla |
      | APPLE3=linux |

  # @author shiywang@redhat.com
  # @case_id OCP-11007
  Scenario: Allow for non-string parameters in templates
    Given I have a project
    Given I obtain test data file "templates/OCP-11007/cakephp1.json"
    When I run the :new_app client command with:
      | file | cakephp1.json |
    Then the step should succeed
    And the "cakephp-example-1" build was created
    And the "cakephp-example-1" build completed
    Given I wait until number of replicas match "2" for replicationController "cakephp-example-1"
    And I delete all resources from the project
    Given I obtain test data file "templates/OCP-11007/cakephp2.json"
    When I run the :new_app client command with:
      | file | cakephp2.json |
    Then the step should succeed
    And the "cakephp-example-1" build was created
    And the "cakephp-example-1" build completed
    Given I obtain test data file "templates/OCP-11007/cakephp3.json"
    When I run the :process client command with:
      | f | cakephp3.json |
    And the output should contain "a${{REPLICA_COUNT}}"
    Given I obtain test data file "templates/OCP-11007/cakephp4.json"
    When I run the :process client command with:
      | f | cakephp4.json |
    And the output should contain "{2"

  # @author shiywang@redhat.com
  # @case_id OCP-12783
  Scenario: Can set env vars on buildconfig with new-build --build-env and --build-env-file
    Given I have a project
    When I run the :new_build client command with:
      | app_repo  | ruby:latest~https://github.com/openshift/ruby-hello-world |
      | build_env | abc=123                                                   |
    Then the step should succeed
    Given the "ruby-hello-world-1" build completed
    When I run the :set_env client command with:
      | resource | pods/ruby-hello-world-1-build |
      | list     | true                          |
    And the output should contain "{"name":"abc","value":"123"}"
    And I delete all resources from the project
    Given a "test" file is created with the following lines:
    """
    abc=456
    """
    When I run the :new_build client command with:
      | app_repo       | ruby:latest~https://github.com/openshift/ruby-hello-world |
      | build_env_file | test                                                      |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | pods/ruby-hello-world-1-build |
      | list     | true                          |
    And the output should contain "{"name":"abc","value":"456"}"

  # @author shiywang@redhat.com
  # @case_id OCP-12888
  Scenario: Can set env vars on buildconfig with new-app --build-env and --build-env-file
    Given I have a project
    When I run the :new_app client command with:
      | app_repo  | ruby:latest~https://github.com/openshift/ruby-hello-world |
      | build_env | DB_USER=test                                              |
    Then the step should succeed
    And the "ruby-hello-world-1" build becomes :running
    When I run the :set_env client command with:
      | resource | pods/ruby-hello-world-1-build |
      | list     | true                          |
    And the output should contain "{"name":"DB_USER","value":"test"}"
    And I delete all resources from the project
    When I run the :new_app client command with:
      | app_repo  | ruby:latest~https://github.com/openshift/ruby-hello-world |
      | build_env | RACK_ENV=development                                      |
    Then the step should succeed
    And the "ruby-hello-world-1" build becomes :running
    When I run the :set_env client command with:
      | resource | pods/ruby-hello-world-1-build |
      | list     | true                          |
    And the output should contain "{"name":"RACK_ENV","value":"development"}"
    And I delete all resources from the project
    Given a "test" file is created with the following lines:
    """
    DB_USER=test
    """
    When I run the :new_app client command with:
      | app_repo       | ruby:latest~https://github.com/openshift/ruby-hello-world |
      | build_env_file | test                                                      |
    Then the step should succeed
    And the "ruby-hello-world-1" build becomes :running
    When I run the :set_env client command with:
      | resource | pods/ruby-hello-world-1-build |
      | list     | true                          |
    And the output should contain "{"name":"DB_USER","value":"test"}"
    And I delete all resources from the project
    Given a "test" file is created with the following lines:
    """
    RACK_ENV=development
    """
    When I run the :new_app client command with:
      | app_repo       | ruby:latest~https://github.com/openshift/ruby-hello-world |
      | build_env_file | test                                                      |
    Then the step should succeed
    And the "ruby-hello-world-1" build becomes :running
    When I run the :set_env client command with:
      | resource | pods/ruby-hello-world-1-build |
      | list     | true                          |
    And the output should contain "{"name":"RACK_ENV","value":"development"}"
