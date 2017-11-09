Feature: Check oc status cli
  # @author yapei@redhat.com
  # @case_id OCP-11147
  Scenario: Show RC info and indicate bad secrets reference in 'oc status'
    Given I have a project

    # Check standalone RC info is dispalyed in oc status output
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/standalone-rc.yaml |
    Then the step should succeed
    And evaluation of `"stdalonerc"` is stored in the :stdrc_name clipboard
    When I run the :status client command
    Then the step should succeed
    Then the output should match:
      | rc/<%= cb.stdrc_name %> runs openshift/origin |
      | rc/<%= cb.stdrc_name %> created               |
      | \\d warning.*'oc status -v' to see details    |
    When I run the :status client command with:
      | v ||
    Then the step should succeed
    Then the output should match:
      | rc/<%= cb.stdrc_name %> is attempting to mount a missing secret secret/<%= cb.mysecret_name %> |
    # Clear out memory and cpu usage to fit into online quota limits
    Given I ensure "<%= cb.stdrc_name %>" rc is deleted

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    When I run the :status client command
    Then the step should succeed
    And the output should contain:
      | pod/hello-openshift runs aosqe/hello-openshift |
    # Clear out memory and cpu usage to fit into online quota limits
    And I ensure "hello-openshift" pod is deleted

    # Check DC,RC info when has missing/bad secret reference
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/application-template-stibuild-with-mount-secret.json |
    Then the step should succeed
    And evaluation of `"my-secret"` is stored in the :missingscrt_name clipboard
    When I create a new application with:
      | template | ruby-helloworld-sample |
    # TODO: yapei, this is a work around for AEP, please add step `the step should succeed` according to latest good solution
    Then I wait for the "database" service to be created
    When I run the :status client command with:
      | v ||
    Then the step should succeed
    And the output should match:
      | dc/frontend is attempting to mount a missing secret secret/<%= cb.missingscrt_name %> |

    # Show RCs for services in oc status
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/replication-controller-match-a-service.yaml |
    Then the step should succeed
    And evaluation of `"rcmatchse"` is stored in the :matchrc_name clipboard
    Then I run the :describe client command with:
      | resource | rc        |
      | name     | rcmatchse |
    Then the step should succeed
    And the output should match:
      | Selector:\\s+name=database |
    When I run the :status client command with:
      | v ||
    Then the step should succeed
    Then the output should match:
      | svc/database                      |
      | dc/database deploys               |
      | rc/<%= cb.matchrc_name %> runs    |
      | rc/<%= cb.matchrc_name %> created |
      | svc/frontend                      |

  # @author akostadi@redhat.com xxia@redhat.com
  # @case_id OCP-12383
  Scenario: [origin_runtime_613]Get project status from CLI
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/ui/application-template-stibuild-without-customize-route.json"

    When I create a new application with:
      | file     | application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    Given the "ruby-sample-build-1" build becomes :running
    When I run the :status client command
    Then the step should succeed
    And the output should match:
      |svc\/database\\s+-\\s+(?:[0-9]{1,3}\.){3}[0-9]{1,3}:\\d+\\s+->\\s+3306|
      |svc\/frontend|
      |build.*1.*running    |
      |deployment.*waiting  |

    Given the "ruby-sample-build-1" build completed
    When I run the :status client command
    Then the step should succeed
    And the output should contain:
      |frontend deploys |

    # check failed build
    When I run the :start_build client command with:
      |buildconfig|ruby-sample-build|
      |commit     |notexist         |
    Then the step should succeed
    Given the "ruby-sample-build-2" build failed
    When I run the :status client command
    Then the step should succeed
    And the output should match:
      |build.*2.*fail|

  # @author cryan@redhat.com
  # @case_id 497403
  Scenario: Show RCs for services in 'oc status'
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    And I run the :process client command with:
      |f|application-template-stibuild.json|
    And the step should succeed
    And I save the output to file> processed-stibuild.json

    When I run the :create client command with:
      |f|processed-stibuild.json|
    Then the step should succeed

    When I run the :get client command with:
      | resource | svc |
    Then the step should succeed
    And the output should contain:
      | frontend |
      | database |

    When I run the :status client command
    Then the step should succeed
    And the output should contain "1 deployment new"

  # @author cryan@redhat.com
  # @case_id OCP-12478
  Scenario: Show Project.Status when listing the project
    Given I have a project
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    # TODO: cryan, this is a work around for AEP, please add step `the step should succeed` according to latest good solution
    Then I wait for the "myapp" service to be created
    When I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should match "<%= project.name %>\s+Active"
    When I run the :status client command
    Then the step should succeed
    And the output should contain "In project <%= project.name %> on server"

    When I run the :delete background client command with:
      | object_type | projects |
      | object_name_or_id | <%= project.name %> |
    Then the step should succeed

    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should match "<%= project.name %>\s+Terminating"
    """
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    Then the step should fail

  # @author pruan@redhat.com
  # @case_id 515694
  Scenario: oc status looks nice in display and suggestion
    Given I have a project
    And I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    And I run the :get client command with:
      | resource | build |
    And the "ruby-sample-build-1" build becomes :running
    And I run the :status client command
    Then the output should contain:
      | use 'oc status -v' to see details |
    And the "ruby-sample-build-1" build becomes :complete
    And I run the :status client command
    Then the output should not contain:
      | use 'oc status -v' to see details |

  # @author yapei@redhat.com
  # @case_id OCP-10650
  Scenario: Indicate when build failed to push in 'oc status'
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc544375/ruby22rhel7-template-docker.json.failtopush"
    Then the step should succeed
    When I run the :new_app client command with:
      | file | ruby22rhel7-template-docker.json.failtopush |
    Then the step should succeed
    Given the "ruby22-sample-build-1" build becomes :running
    And I run the :status client command
    Then the output should contain:
      | can't push to image |
