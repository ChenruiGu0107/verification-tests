Feature: oc_set_probe.feature

    #   And the pod status is restart

  # @author dyan@redhat.com
  # @case_id OCP-9874
  Scenario: Remove probe in dc
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/mysql:5.6 |
      | env          | MYSQL_USER=user     |
      | env          | MYSQL_PASSWORD=pass |
      | env          | MYSQL_DATABASE=db   |
    Then the step should succeed
    When I run the :new_app client command with:
      | image_stream | openshift/mongodb:2.6 |
      | env          | MONGODB_USER=test     |
      | env          | MONGODB_PASSWORD=test |
      | env          | MONGODB_DATABASE=test |
      | env          | MONGODB_ADMIN_PASSWORD=test |
    Then the step should succeed
    Given I wait until the status of deployment "mysql" becomes :complete
    And I wait until the status of deployment "mongodb" becomes :complete
    # set probe in both dc
    When I run the :set_probe client command with:
      | resource    | dc/mysql |
      | readiness   |          |
      | open_tcp    | 3306     |
    Then the step should succeed
    Given I wait until the status of deployment "mysql" becomes :complete
    And a pod becomes ready with labels:
      | deployment=mysql-2 |
    When I run the :describe client command with:
      | resource | pod |
      | l    | deployment=mysql-2 |
    Then the output should contain:
      | Readiness |
      | tcp-socket :3306 |
    When I run the :set_probe client command with:
      | resource   | dc/mongodb |
      | liveness   |            |
      | oc_opts_end  |          |
      | exec_command | true     |
    Then the step should succeed
    Given I wait until the status of deployment "mongodb" becomes :complete
    And a pod becomes ready with labels:
      | deployment=mongodb-2 |
    When I run the :describe client command with:
      | resource | pod |
      | l    | deployment=mongodb-2 |
    Then the output should contain:
      | Liveness |
      | true     |
    # remove probe in both dc on the same time
    When I run the :set_probe client command with:
      | resource | dc       |
      | all      |          |
      | remove   |          |
      | liveness |          |
      | readiness |         |
    Then the step should succeed
    Given I wait until the status of deployment "mysql" becomes :complete
    And I wait until the status of deployment "mongodb" becomes :complete
    When I run the :describe client command with:
      | resource | pod |
      | l    | deployment=mysql-3 |
    Then the output should not contain:
      | Readiness |
      | tcp-socket :3306 |
    When I run the :describe client command with:
      | resource | pod |
      | l    | deployment=mongodb-3 |
    Then the output should not contain:
      | Liveness |
    #set two kind probe in one dc
    When I run the :set_probe client command with:
      | resource  | dc/mysql |
      | readiness |          |
      | open_tcp  | 3306 |
    Then the step should succeed
    When I run the :set_probe client command with:
      | resource  | dc/mysql |
      | liveness  |          |
      | oc_opts_end  |       |
      | exec_command | true  |
    Then the step should succeed
    Given I wait until the status of deployment "mysql" becomes :complete
    And a pod becomes ready with labels:
      | deployment=mysql-5 |
    When I run the :describe client command with:
      | resource | pod |
      | l    | deployment=mysql-5 |
    Then the output should contain:
      | Liveness  |
      | true      |
      | Readiness |
      | tcp-socket :3306 |
    # remove one probe
    When I run the :set_probe client command with:
      | resource | dc        |
      | l        | app=mysql |
      | remove   |           |
      | readiness |           |
    Then the step should succeed
    Given I wait until the status of deployment "mysql" becomes :complete
    And a pod becomes ready with labels:
      | deployment=mysql-6 |
    When I run the :describe client command with:
      | resource | pod |
      | l    | deployment=mysql-6 |
    Then the output should contain:
      | Liveness  |
      | true      |
    And the output should not contain:
      | Readiness |
      | tcp-socket :3306 |

  # @author dyan@redhat.com
  # @case_id OCP-9876
  Scenario: Set a invalid probe in dc
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/mysql:latest |
      | env          | MYSQL_USER=user        |
      | env          | MYSQL_PASSWORD=pass    |
      | env          | MYSQL_DATABASE=db      |
    Then the step should succeed
    When I run the :set_probe client command with:
      | resource   | dc/mysql |
      | readiness |       |
      | open_tcp  | 65536 |
    Then the output should contain:
      | error |
      | open-tcp |
      | between 1 and 65535 |
    When I run the :set_probe client command with:
      | resource  | dc/mysql |
      | readiness |      |
      | open_tcp  | 3306 |
      | failure_threshold | 0     |
    Then the output should contain:
      | error |
      | failure-threshold |
      | less than one |
    When I run the :set_probe client command with:
      | resource  | dc/mysql |
      | readiness |          |
      | open_tcp  | 3306 |
      | success_threshold | 0     |
    Then the output should contain:
      | error |
      | success-threshold |
      | less than one |
    When I run the :set_probe client command with:
      | resource  | dc/mysql |
      | readiness |          |
      | open_tcp  | 3306 |
      | initial_delay_seconds | -5     |
    Then the output should contain:
      | error |
      | initial-delay-seconds |
      | not be negative |
    When I run the :set_probe client command with:
      | resource  | dc/mysql |
      | readiness |          |
      | open_tcp  | 3306 |
      | timeout_seconds | -10     |
    Then the output should contain:
      | error |
      | timeout-seconds |
      | not be negative |
    When I run the :set_probe client command with:
      | resource  | dc/mysql |
      | readiness |          |
      | open_tcp  | 3306 |
      | period_seconds | -10     |
    Then the output should contain:
      | error |
      | period-seconds |
      | not be negative |
    When I run the :set_probe client command with:
      | resource  | dc/mysql |
      | c         | openshift |
      | readiness |           |
      | open_tcp  | 3306 |
    Then the output should contain:
      | deploymentconfigs/mysql |
      | does not |
      | containers matching |
      | openshift |

