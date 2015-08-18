Feature: sandbox for testing steps
  Scenario: random str
    Given I have a project
    Given a random string is stored into the clipboard
    Given a random string of type :dns is stored into the :dns_rand clipboard
