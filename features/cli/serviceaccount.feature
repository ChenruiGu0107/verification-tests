Feature: ServiceAccount and Policy Managerment

  # @author anli@redhat.com
  # @case_id 490717
  Scenario: Could grant admin permission for the service account username to access to its own project
    Given I have a project
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    Then the step should succeed
    Given I create the serviceaccount "demo"
    And I give project admin role to the demo service account
    When I run the :describe client command with:
      | resource | policybindings |
      | name     | :default       |
    Then the output should contain:
      | Role:	admin                                 |
      # | system:serviceaccount:<%= project.name %>:demo|
      | Groups:	[                                     |
      | RoleBinding[system:deployers]                 |
    Given I find a bearer token of the demo service account
    And I switch to the demo service account
    When I run the :get client command with:
      | resource | buildconfig        |
    Then the output should contain:
      | myapp   |
