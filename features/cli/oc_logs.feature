Feature: oc logs related features
  #@ author wzheng@redhat.com
  #@case_id 438848
  Scenario: Get buildlogs with invalid parameters
    Given I have a project
    When I run the :logs client command with:
      | resource_name | 123 |
    Then the step should fail
    And the output should contain "Error from server: pods "123" not found"
    When I run the :logs client command with:
      | resource_name |   |
    Then the step should fail
    And the output should contain "error: a pod must be specified"
