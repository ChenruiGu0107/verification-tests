Feature: Check status via oc status, wait etc

  # @author akostadi@redhat.com
  # @author xxia@redhat.com
  # @case_id OCP-12383
  Scenario: [origin_runtime_613]Get project status from CLI
    Given I have a project
    And I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"

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


  # @author yapei@redhat.com
  # @case_id OCP-10650
  Scenario: Indicate when build failed to push in 'oc status'
    Given I have a project
    Given I obtain test data file "templates/tc544375/ruby22rhel7-template-docker.json.failtopush"
    Then the step should succeed
    When I run the :new_app client command with:
      | file | ruby22rhel7-template-docker.json.failtopush |
    Then the step should succeed
    Given the "ruby22-sample-build-1" build becomes :running
    And I run the :status client command
    Then the output should contain:
      | can't push to image |

  # @author xxia@redhat.com
  # @case_id OCP-19965
  Scenario: oc wait for specific condition of resources
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    When I run the :wait client command with:
      | resource      | dc                  |
      | resource_name | ruby-ex             |
      | for           | condition=available |
      | timeout       | 10m                 |
    Then the step should succeed
    And the output should match "ruby-ex.*condition"
    When I run the :wait client command with:
      | resource  | po              |
      | l         | app=ruby-ex     |
      | for       | condition=ready |
    Then the step should succeed
    And the output should match "pod.*ruby-ex.*condition"
    When I run the :wait background client command with:
      | resource  | po          |
      | l         | app=ruby-ex |
      | for       | delete      |
      | timeout   | 2m          |
    Then the step should succeed
    Given I ensure "ruby-ex" dc is deleted
    When I check status of last background process
    Then the output should match "pod.*ruby-ex.*condition"
    When I run the :wait client command with:
      | resource      | bc/ruby-ex          |
      | for           | condition=available |
    Then the step should fail
    And the output should match "[Ee]rror.*condition"
