Feature: login related scenario

  # @author: wjiang@redhat.com
  # @case_id: 473847
  Scenario: login and logout via web
    Given I login via web console
    Given I run the :logout web console action
    Then the step should succeed
