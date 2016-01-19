Feature: oc_process.feature

  # @author haowang@redhat.com
  # @case_id 439003 439004
  Scenario Outline: Should give a error message while generator is nonexistent or the value is invalid
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sample-php-rhel7.json"
    And I replace lines in "sample-php-rhel7.json":
      | <beforreplace> | <afterreplace> |
    Then I run the :process client command with:
      | f | sample-php-rhel7.json |
    And the step should succeed
    And the output should contain:
      | <output>  |
    Examples:
      | beforreplace | afterreplace | output                              |
      | expression   | test         | Unable to find the 'test' generator |
      | A-Z          | A-Z0-z       | invalid range specified             |
