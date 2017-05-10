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

  # @author bingli@redhat.com
  # @case_id OCP-10509
  Scenario: Check online default images
    When I run the :get client command with:
      | resource      | imagestreamtag  |
      | n             | openshift       |
    Then the step should succeed
    And the output should contain:
      | dotnet:latest                           |
      | dotnet:1.1                              |
      | dotnet:1.0                              |
      | jboss-webserver30-tomcat7-openshift:1.1 |
      | jboss-webserver30-tomcat7-openshift:1.2 |
      | jboss-webserver30-tomcat8-openshift:1.1 |
      | jboss-webserver30-tomcat8-openshift:1.2 |
      | jenkins:latest                          |
      | jenkins:1                               |
      | jenkins:2                               |
      | mariadb:latest                          |
      | mariadb:10.1                            |
      | mongodb:latest                          |
      | mongodb:2.4                             |
      | mongodb:2.6                             |
      | mongodb:3.2                             |
      | mysql:latest                            |
      | mysql:5.5                               |
      | mysql:5.6                               |
      | mysql:5.7                               |
      | nodejs:latest                           |
      | nodejs:0.10                             |
      | nodejs:4                                |
      | nodejs:6                                |
      | perl:latest                             |
      | perl:5.16                               |
      | perl:5.20                               |
      | perl:5.24                               |
      | php:latest                              |
      | php:5.5                                 |
      | php:5.6                                 |
      | php:7.0                                 |
      | postgresql:latest                       |
      | postgresql:9.2                          |
      | postgresql:9.4                          |
      | postgresql:9.5                          |
      | python:latest                           |
      | python:2.7                              |
      | python:3.3                              |
      | python:3.4                              |
      | python:3.5                              |
      | redhat-openjdk18-openshift:1.0          |
      | redis:latest                            |
      | redis:3.2                               |
      | ruby:latest                             |
      | ruby:2.0                                |
      | ruby:2.2                                |
      | ruby:2.3                                |
      | wildfly:latest                          |
      | wildfly:8.1                             |
      | wildfly:9.0                             |
      | wildfly:10.0                            |
      | wildfly:10.1                            |
