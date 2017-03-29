Feature: ONLY ONLINE Imagestreams related scripts in this file

  # @author etrott@redhat.com
  # @case_id 533084
  # @case_id OCP-10165
  Scenario Outline: Imagestream should not be tagged with 'builder'
    When I create a new project via web
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain:
      | <is> |
    When I run the :get client command with:
      | resource      | is        |
      | resource_name | <is>      |
      | n             | openshift |
      | o             | json      |
    Then the step should succeed
    And the output should not contain "builder"
    Examples:
      | is                     |
      | jboss-eap70-openshift  |
      | redhat-sso70-openshift |

  # @author bingli@redhat.com
  # @case_id OCP-13212
  Scenario: Build and run Java applications using redhat-openjdk18-openshift image
    Given I have a project
    And I create a new application with:
      | image_stream | openshift/redhat-openjdk18-openshift:latest              |
      | code         | https://github.com/jboss-openshift/openshift-quickstarts |
      | context_dir  | undertow-servlet                                         |
      | name         | openjdk18                                                |
    When I get project bc named "openjdk18" as YAML
    Then the output should match:
      | uri:\\s+https://github.com/jboss-openshift/openshift-quickstarts |
      | type: Git                                                        |
      | name: redhat-openjdk18-openshift:latest                          |
    Given the "openjdk18-1" build was created
    And the "openjdk18-1" build completed
    When I run the :build_logs client command with:
      | build_name | openjdk18-1 |
    Then the output should contain:
      | Starting S2I Java Build |
      | Push successful         |
    Given 1 pods become ready with labels:
      | app=openjdk18              |
      | deployment=openjdk18-1     |
      | deploymentconfig=openjdk18 |
    When I expose the "openjdk18" service
    Then the step should succeed
    Then I wait for a web server to become available via the "openjdk18" route
    And the output should contain:
      | Hello World |
