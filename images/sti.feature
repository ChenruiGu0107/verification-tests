Feature: sti.feature
  # @author wzheng@redhat.com
  # @case_id OCP-15360
  Scenario: Nodejs image works well with DEV_MODE=true - nodejs-6-rhel7	
    Given I have a project
    When I run the :new_app client command with:
      | template | nodejs-mongodb-example |
      | e | DEV_MODE=true |
    Then the step should succeed
    Given the "nodejs-mongodb-example-1" build completed
    And I wait for the "nodejs-mongodb-example" service to become ready up to 300 seconds
    Then I wait for a web server to become available via the "nodejs-mongodb-example" route
    Then the output should contain "Welcome to your Node.js application on OpenShift"
