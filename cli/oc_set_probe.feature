Feature: oc_set_probe.feature
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

