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
    And the output should contain:
      | <output>  |
    Examples:
      | beforreplace | afterreplace | output                  |
      | expression   | test         | test                    |
      | A-Z          | A-Z0-z       | invalid range specified |

  # @author haowang@redhat.com
  # @case_id 474030
  Scenario: "oc process" handles invalid json file
    Given I have a project
    Then I run the :process client command with:
      | f | non.json |
    And the step should fail
    And the output should contain:
      | does not exist |
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sample-php-rhel7.json"
    And I replace lines in "sample-php-rhel7.json":
      | , |  |
    Then I run the :process client command with:
      | f | sample-php-rhel7.json |
    And the step should fail
    And the output should contain:
      | nvalid character |

  # @author cryan@redhat.com
  # @case_id 534516
  # @bug_id 1253736
  Scenario: oc process can handle different namespace's template
    Given I have a project
    When I process and create template "openshift//jenkins-persistent"
    Then the step should succeed
    When I process and create template "openshift/template/mongodb-persistent"
    Then the step should succeed
    When I run the :process client command with:
      | template | jenkins-persistent |
      | n        | openshift          |
    Then the step should fail
    And the output should contain "cannot create"
    When I run the :process client command with:
      | template | template/jenkins-persistent |
    Then the step should fail
    And the output should contain "could not be found"
    When I run the :process client command with:
      | template | jenkins-persistent |
    Then the step should fail
    And the output should contain "could not be found"
    When I run the :process client command with:
      | template | openshift/jenkins-persistent |
    Then the step should fail
    And the output should contain "invalid resource"

  # @author cryan@redhat.com
  # @case_id 534958
  # @bug_id 1375275
  Scenario: Deal with multiple equal signs or commas in parameter with oc process or oc new-app
    Given I have a project
    When I run the :process client command with:
      | f        | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | template | ADMIN_PASSWORD=-Dfoo=bar -Dbar=foo                                                                               |
      | template | MYSQL_PASSWORD=-Dfoo2=bar -Dbar2=foo                                                                             |
    Then the step should succeed
    And the output should not contain "invalid parameter assignment"
    And the output should contain:
      | "value": "-Dfoo=bar -Dbar=foo    |
      | "value": "-Dfoo2=bar -Dbar2=foo" |
    When I run the :new_app client command with:
      | file    | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | p       | ADMIN_PASSWORD=-Dfoo=bar -Dbar=foo   |
      | p       | MYSQL_PASSWORD=-Dfoo2=bar            |
      | dry_run | true                                                                                                             |
    Then the step should succeed
    And the output should contain:
      | ADMIN_PASSWORD=-Dfoo=bar -Dbar=foo   |
      | MYSQL_PASSWORD=-Dfoo2=bar            |
    When I run the :new_app client command with:
      | file    | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | p       | ADMIN_PASSWORD=1,2,3       |
      | p       | MYSQL_PASSWORD=4,5,6       |             
      | dry_run | true                                                                                                             |
    Then the step should succeed
    And the output should not contain "error: environment variables must be of the form key=value"
    And the output should contain:
      | ADMIN_PASSWORD=1,2,3 |
      | MYSQL_PASSWORD=4,5,6 |
    When I run the :new_app client command with:
      | file    | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | p       | ADMIN_PASSWORD=1,2,MYSQL_PASSWORD=4,5                                                                            |
      | dry_run | true                                                                                                             |
    # Don't care if the step could be succeed or not
    # only test if values "will be treated as a single key-value pair"
    And the output should contain:
      | treated as a single key-value pair |
