Feature: oc_process.feature

  # @author haowang@redhat.com
  Scenario Outline: Should give a error message while generator is nonexistent or the value is invalid
    Given I have a project
    And I obtain test data file "build/sample-php-rhel7.json"
    And I replace lines in "sample-php-rhel7.json":
      | <beforreplace> | <afterreplace> |
    Then I run the :process client command with:
      | f | sample-php-rhel7.json |
    And the output should contain:
      | <output>  |
    Examples:
      | beforreplace | afterreplace | output                  |
      | A-Z          | A-Z0-z       | invalid range specified | # @case_id OCP-12353

  # @author cryan@redhat.com
  # @case_id OCP-10222
  # @bug_id 1253736
  Scenario: oc process can handle different namespace's template
    Given I have a project
    When I process and create template "openshift//jenkins-persistent"
    Then the step should succeed
    Given I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
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
  # @case_id OCP-10276
  # @bug_id 1375275
  Scenario: Deal with multiple equal signs or commas in parameter with oc process or oc new-app
    Given I have a project
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    When I run the :process client command with:
      | f        | application-template-stibuild-without-customize-route.json |
      | template | MYSQL_USER=username                                                                                                           |
      | template | MYSQL_PASSWORD=-Dfoo2=bar -Dbar2=foo                                                                                          |
    Then the step should succeed
    And the output should not contain "invalid parameter assignment"
    And the output should contain:
      | username              |
      | -Dfoo2=bar -Dbar2=foo |
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    When I run the :new_app client command with:
      | file    | application-template-stibuild-without-customize-route.json |
      | p       | MYSQL_USER=username                                                                                                           |
      | p       | MYSQL_PASSWORD=-Dfoo2=bar -Dbar=foo                                                                                           |
      | dry_run | true                                                                                                                          |
    Then the step should succeed
    And the output should contain:
      | MYSQL_USER=username                 |
      | MYSQL_PASSWORD=-Dfoo2=bar -Dbar=foo |
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    When I run the :new_app client command with:
      | file    | application-template-stibuild-without-customize-route.json |
      | p       | MYSQL_USER=username                                                                                                           |
      | p       | MYSQL_PASSWORD=4,5,6                                                                                                          |
      | dry_run | true                                                                                                                          |
    Then the step should succeed
    And the output should not contain "error: environment variables must be of the form key=value"
    And the output should contain:
      | MYSQL_USER=username  |
      | MYSQL_PASSWORD=4,5,6 |
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    When I run the :new_app client command with:
      | file    | application-template-stibuild-without-customize-route.json |
      | p       | MYSQL_USER=username,MYSQL_PASSWORD=4,5                                                                                        |
      | dry_run | true                                                                                                                          |
    # Don't care if the step could be succeed or not
    # only test if values "will be treated as a single key-value pair"
    And the output should contain:
      | treated as a single key-value pair |

  # @case_id OCP-11680
  Scenario: Supply oc process parameter list+env vars via a file
    Given I have a project
    Given a "test1" file is created with the following lines:
    """
    required_param="first\nsecond"
    optional_param=foo
    """
    Given a "test2" file is created with the following lines:
    """
    ADMIN_USERNAME=root
    ADMIN_PASSWORD="adminpass"
    REDIS_PASSWORD='redispass'
    """
    Given a "test3" file is created with the following lines:
    """
    aaa=123
    """
    Given I obtain test data file "cli/OCP-11680/guestbook.json"
    When I run the :process client command with:
      | f          | guestbook.json |
      | param_file | test2                                                                              |
    Then the step should succeed
    And the output should contain:
      | root      |
      | adminpass |
      | redispass |
    Given I obtain test data file "cli/OCP-11680/template_required_params.yaml"
    When I run the :process client command with:
      | f          | template_required_params.yaml |
      | param_file | test1                                                                                             |
    And the output should contain "name": "first\nsecond"
    Given I obtain test data file "cli/OCP-11680/template_required_params.yaml"
    When I run the :process client command with:
      | f          | template_required_params.yaml |
      | param_file | test3                                                                                             |
    And the step should fail
    And the output should contain:
      | unknown parameter name "aaa" |
    Given I obtain test data file "cli/OCP-11680/template_required_params.yaml"
    When I run the :process client command with:
      | f          | template_required_params.yaml |
      | param_file | test1                                                                                             |
      | p          | required_param=good                                                                               |
    And the step should succeed
    And the output should contain:
      | "name": "good" |
    And the step should succeed
