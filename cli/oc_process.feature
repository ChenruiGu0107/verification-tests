Feature: oc_process.feature

  # @author haowang@redhat.com
  Scenario Outline: Should give a error message while generator is nonexistent or the value is invalid
    Given I have a project
    And I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/sample-php-rhel7.json"
    And I replace lines in "sample-php-rhel7.json":
      | <beforreplace> | <afterreplace> |
    Then I run the :process client command with:
      | f | sample-php-rhel7.json |
    And the output should contain:
      | <output>  |
    Examples:
      | beforreplace | afterreplace | output                  |
      | expression   | test         | test                    | # @case_id OCP-12334
      | A-Z          | A-Z0-z       | invalid range specified | # @case_id OCP-12353

  # @author haowang@redhat.com
  # @case_id OCP-11087
  Scenario: "oc process" handles invalid json file
    Given I have a project
    Then I run the :process client command with:
      | f | non.json |
    And the step should fail
    And the output should contain:
      | does not exist |
    And I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/sample-php-rhel7.json"
    And I replace lines in "sample-php-rhel7.json":
      | , |  |
    Then I run the :process client command with:
      | f | sample-php-rhel7.json |
    And the step should fail
    And the output should contain:
      | nvalid character |

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
    When I run the :process client command with:
      | f        | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
      | template | MYSQL_USER=username                                                                                                           |
      | template | MYSQL_PASSWORD=-Dfoo2=bar -Dbar2=foo                                                                                          |
    Then the step should succeed
    And the output should not contain "invalid parameter assignment"
    And the output should contain:
      | username              |
      | -Dfoo2=bar -Dbar2=foo |
    When I run the :new_app client command with:
      | file    | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
      | p       | MYSQL_USER=username                                                                                                           |
      | p       | MYSQL_PASSWORD=-Dfoo2=bar -Dbar=foo                                                                                           |
      | dry_run | true                                                                                                                          |
    Then the step should succeed
    And the output should contain:
      | MYSQL_USER=username                 |
      | MYSQL_PASSWORD=-Dfoo2=bar -Dbar=foo |
    When I run the :new_app client command with:
      | file    | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
      | p       | MYSQL_USER=username                                                                                                           |
      | p       | MYSQL_PASSWORD=4,5,6                                                                                                          |
      | dry_run | true                                                                                                                          |
    Then the step should succeed
    And the output should not contain "error: environment variables must be of the form key=value"
    And the output should contain:
      | MYSQL_USER=username  |
      | MYSQL_PASSWORD=4,5,6 |
    When I run the :new_app client command with:
      | file    | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
      | p       | MYSQL_USER=username,MYSQL_PASSWORD=4,5                                                                                        |
      | dry_run | true                                                                                                                          |
    # Don't care if the step could be succeed or not
    # only test if values "will be treated as a single key-value pair"
    And the output should contain:
      | treated as a single key-value pair |

  # @author shiywang@redhat.com
  Scenario Outline: Docker build failure reason display if use incorrect config in buildconfig
    Given I have a project
    When I run the :new_app client command with:
      | app_repo |  <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/ruby22rhel7-template-docker.json |
    Then the step should succeed
    Given the "ruby22-sample-build-1" build was created
    Given the "ruby22-sample-build-1" build completed
    When I run the :patch client command with:
      | resource      | buildconfig                                              |
      | resource_name | ruby22-sample-build                                      |
      | p | {"spec":{"output":{"to":{"name":"origin-ruby22-sample123:latest"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Given the "ruby22-sample-build-2" build was created
    And the "ruby22-sample-build-2" build becomes :new
    When I run the :get client command with:
      | resource      | build                 |
      | resource_name | ruby22-sample-build-2 |
    Then the output should contain "InvalidOutputReference"
    #change back
    When I run the :patch client command with:
      | resource      | buildconfig                                                       |
      | resource_name | ruby22-sample-build                                               |
      | p             | {"spec":{"output":{"to":{"name":"origin-ruby22-sample:latest"}}}} |
    Then the step should succeed
    And I run the :delete client command with:
      | object_type      | build                  |
      | object_name_or_id | ruby22-sample-build-2 |
    # use incorrect
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                                                       |
      | resource_name | ruby22-sample-build                                                                                                                               |
      | p             | {"spec":{"strategy":{"dockerStrategy": {"from":{"kind":"DockerImage","name":"docker.io/openshift/rubyyyy-20-centos7:latest","namespace":null}}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Given the "ruby22-sample-build-3" build was created
    And the "ruby22-sample-build-3" build becomes :failed
    When I run the :get client command with:
      | resource      | build                 |
      | resource_name | ruby22-sample-build-3 |
    Then the output should contain "<error>"
    #change back
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                            |
      | resource_name | ruby22-sample-build                                                                                                    |
      | p             | {"spec":{"strategy":{"dockerStrategy": {"from":{"kind":"ImageStreamTag","name":"ruby:2.5","namespace":"openshift"}}}}} |
    Then the step should succeed
    And I run the :delete client command with:
      | object_type      | build                  |
      | object_name_or_id | ruby22-sample-build-3 |
    #use incorrect
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                              |
      | resource_name | ruby22-sample-build                                                                                      |
      | p             | {"spec":{"source":{"git":{"uri":"https://github123.com/openshift/ruby-hello-world.git"},"type": "Git"}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Given the "ruby22-sample-build-4" build was created
    And the "ruby22-sample-build-4" build becomes :failed
    When I run the :get client command with:
      | resource      | build                 |
      | resource_name | ruby22-sample-build-4 |
    Then the output should contain "FetchSourceFailed"
    #change back
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                         |
      | resource_name | ruby22-sample-build                                                                                 |
      | p             | {"spec":{"source":{"git":{"uri":"git://github.com/openshift/ruby-hello-world.git"},"type": "Git"}}} |
    Then the step should succeed
    And I run the :delete client command with:
      | object_type      | build                  |
      | object_name_or_id | ruby22-sample-build-4 |
    #use incorrect
    When I run the :patch client command with:
      | resource      | buildconfig                                               |
      | resource_name | ruby22-sample-build                                       |
      | p | {"spec":{"postCommit":{"args":["bundle12312","exec","rake","test"]}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Given the "ruby22-sample-build-5" build was created
    And the "ruby22-sample-build-5" build becomes :failed
    When I run the :get client command with:
      | resource      | build                 |
      | resource_name | ruby22-sample-build-5 |
    Then the output should contain "PostCommitHookFailed"
    
    Examples:
      | error                  |
      | PullBuilderImageFailed |  # @case_id OCP-11064
      | DockerBuildFailed      |  # @case_id OCP-15856

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
    When I run the :process client command with:
      | f          | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cli/OCP-11680/guestbook.json |
      | param_file | test2                                                                              |
    Then the step should succeed
    And the output should contain:
      | root      |
      | adminpass |
      | redispass |
    When I run the :process client command with:
      | f          | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cli/OCP-11680/template_required_params.yaml |
      | param_file | test1                                                                                             |
    And the output should contain "name": "first\nsecond"
    When I run the :process client command with:
      | f          | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cli/OCP-11680/template_required_params.yaml |
      | param_file | test3                                                                                             |
    And the step should fail
    And the output should contain:
      | unknown parameter name "aaa" |
    When I run the :process client command with:
      | f          | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cli/OCP-11680/template_required_params.yaml |
      | param_file | test1                                                                                             |
      | p          | required_param=good                                                                               |
    And the step should succeed
    And the output should contain:
      | "name": "good" |
    And the step should succeed
