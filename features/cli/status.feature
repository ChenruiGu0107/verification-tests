Feature: Check oc status cli
  # @author yapei@redhat.com
  # @case_id 497402
  Scenario: Show RC info and indicate bad secrets reference in 'oc status'
    Given I have a project

    # Check project status when project is empty
    When I run the :status client command
    Then the output should contain:
      | You have no services, deployment configs, or build configs |


    # Check standalone RC info is dispalyed in oc status output
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/secret.json |
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/standalone-rc.yaml |
    When I run the :status client command
    Then the output should contain:
      | rc/stdalonerc runs openshift/origin |
      | rc/stdalonerc created |
      | Warnings: |
      | rc/stdalonerc is attempting to mount a secret secret/mysecret disallowed by sa/default |

    # Check DC,RC info when has missing/bad secret reference
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/application-template-stibuild-with-mount-secret.json |
    When I create a new application with:
      | template | ruby-helloworld-sample |
    Then the step should succeed
    When I run the :status client command
    And the output should contain:
      | dc/frontend is attempting to mount a secret secret/my-secret disallowed by sa/default |
      | dc/frontend is attempting to mount a missing secret secret/my-secret |

    # Show RCs for services in oc status
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/replication-controller-match-a-service.yaml |
    Then I run the :describe client command with:
      | resource    | rc |
      | name | rcmatchse |
    And the output should match:
      | Selector:\s+name=database |
    When I run the :status client command
    Then the output should contain:
      | service/database |
      | dc/database deploys |
      | rc/rcmatchse runs |
      | rc/rcmatchse created |
      | service/frontend |

  # @author akostadi@redhat.com
  # @case_id 476320
  Scenario: [origin_runtime_613]Get project status from CLI
    Given I have a project
    # And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/e21d95cedad8f0ce06ff5d04ae9b978ce3d04d87/examples/sample-app/application-template-stibuild.json"

    And I run the :process client command with:
      |f|application-template-stibuild.json|
    And the step should succeed
    And I save the output to file> processed-stibuild.json

    When I run the :create client command with:
      |f|processed-stibuild.json|
    Then the step should succeed
    And I run the :status client command
    Then the step should succeed
    And the output should match:
      |n\s+project\s+<%= project.name %>|
      |service/database\s+-\s+(?:[0-9]{1,3}\.){3}[0-9]{1,3}:\d+\s+->\s+3306|
      |service/frontend\s+-\s+(?:[0-9]{1,3}\.){3}[0-9]{1,3}:\d+\s+->\s+8080|
        ## "\x7C" is '|' character
      |not built yet<%= "\x7C" %>build 1 pending<%= "\x7C" %>build 1 new|
      |deployment|

    # When I run the :start_build client command with:
    #   |buildconfig|ruby-sample-build|
    #Then the step should succeed
    Given the "ruby-sample-build-1" was created
    And the "ruby-sample-build-1" build becomes running
    When I run the :status client command
    Then the step should succeed
    And the output should contain:
      |build 1 running|
      |deployment waiting|

    Given the "ruby-sample-build-1" build completed
    When I run the :status client command
    Then the step should succeed
    And the output should contain:
      |deployment running|

    # check build with wrong URL
    Given I delete the project
    And I have a project
    And I replace lines in "application-template-stibuild.json":
      |https://github.com/openshift/ruby-hello-world.git|https://github.com/openshift/invalid_test_repo.gah|
    And I run the :process client command with:
      |f|application-template-stibuild.json|
    And the step should succeed
    And I save the output to file> processed-stibuild-bad-url.json

    When I run the :create client command with:
      |f|processed-stibuild-bad-url.json|
    Then the step should succeed

    Given the "ruby-sample-build-1" was created
    And the "ruby-sample-build-1" build failed
    When I run the :status client command
    Then the step should succeed
    And the output should match:
      |build 1 failed|
