Feature: test nodes relates steps
  @admin
  Scenario: nodes test
    Given I store the schedulable nodes in the clipboard
    When label "testme=go" is added to the "<%= cb.nodes.sample.name %>" node
    Then I do nothing
