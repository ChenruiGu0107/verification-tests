Feature: oc_process.feature

  # @author haowang@redhat.com
  # @case_id 439003
  Scenario: Should give a error message while generator is nonexistent
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sample-php-rhel7.json"
    And I replace lines in "sample-php-rhel7.json":
      | expression | test |
    Then I run the :process client command with:
      | f | sample-php-rhel7.json |
    And the step should succeed
    And the output should contain:
      | Unable to find the 'test' generator |
