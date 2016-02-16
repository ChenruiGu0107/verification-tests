Feature: Some basic project related tests

  Scenario: project methods
    When I have a project
    Then I delete the project
    Given I create 10 new projects
