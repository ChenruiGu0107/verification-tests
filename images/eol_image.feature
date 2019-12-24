Feature: Remove eol image
  # @author wewang@redhat.com
  # @case_id OCP-24451
  Scenario: Remove EOL images imported by samples operator
    Given the master version >= "4.2"
    When I run the :get client command with:
      | resource  | istag     |
      | namespace | openshift |
    Then the step should succeed
    And the output should not contain:
      | ruby:2.0       |
      | ruby:2.2       |
      | python:3.3     |
      | python:3.4     |
      | postgresql:9.2 |
      | postgresql:9.4 |
      | postgresql:9.5 |
      | php:5.5        |
      | php:5.6        |
      | perl:5.16      |
      | perl:5.20      |
      | nodejs:0.10    |
      | nodejs:4       |
      | nodejs:6       |
      | nginx:1.8      |
      | mysql:5.5      |
      | mysql:5.6      |
      | mongodb:2.4    |
      | mongodb:2.6    |
      | mariadb:10.1   |
      | dotnet:1.0     |
      | dotnet:1.1     |
      | dotnet:2.0     |
