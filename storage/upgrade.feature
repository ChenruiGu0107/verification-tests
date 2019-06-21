Feature: Scenarios which will be used both for function checking and upgrade checking
  # @author lxia@redhat.com
  Scenario Outline: There should be one and only one default storage class
    When I run the :get client command with:
      | resource | storageclass |
    Then the step should succeed
    And the output should contain:
      | default |
    When I run the :get client command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should contain 1 times:
      | is-default-class: "true" |
    When I run the :describe client command with:
      | resource | storageclass |
    Then the step should succeed
    And the output should contain 1 times:
      | is-default-class=true |
    Examples:
      | for      |
      | function | # @case_id OCP-22125
      | upgrade  | # @case_id OCP-23499
