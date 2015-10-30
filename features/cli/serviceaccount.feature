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
    Then the output should match:
      | Role:\\s+admin |
      | ServiceAccounts:\\s+demo |
    Then the output should contain:
      | RoleBinding[system:deployers] |
    Given I find a bearer token of the demo service account
    And I switch to the demo service account
    When I run the :get client command with:
      | resource | buildconfig        |
    Then the output should contain:
      | myapp   |

  # @author xxing@redhat.com
  # @case_id 490722
  Scenario: The default service account could only get access to imagestreams in its own project
    Given I have a project
    When I run the :who_can client command with:
      | verb     | get |
      | resource | imagestreams/layers |
    Then the output should match:
      | Groups:\\s+system:cluster-admins |
      | system:serviceaccounts:<%= Regexp.escape(project.name) %> |
    When I run the :who_can client command with:
      | verb     | get |
      | resource | pods/layers |
    Then the output should not match:
      | system:serviceaccount(?:s)? |
    Given I create a new project
    When I run the :who_can client command with:
      | verb     | get |
      | resource | imagestreams/layers |
    Then the output should not match:
      | system:serviceaccount(?:s)?:<%= Regexp.escape(@projects[0].name) %>  |
    When I run the :who_can client command with:
      | verb     | update |
      | resource | imagestreams/layers |
    Then the output should not contain:
      | system:serviceaccounts:<%= project.name %> |
    When I run the :who_can client command with:
      | verb     | delete |
      | resource | imagestreams/layers |
    Then the output should not match:
      | system:serviceaccount(?:s)?:<%= Regexp.escape(project.name) %> |
