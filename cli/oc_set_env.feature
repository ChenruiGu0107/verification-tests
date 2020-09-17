Feature: oc_set_env.feature
  # @author chezhang@redhat.com
  # @author weinliu@redhat.com
  # @case_id OCP-10888
  @smoke
  Scenario: Set pod env vars from configmap
    Given I have a project
    Given I obtain test data file "configmap/configmap.yaml"
    When I run the :create client command with:
      | f | configmap.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | special-config.*2    |
    When I run the :new_app client command with:
      | app_repo | mysql-ephemeral |
    Then the step should succeed
    And the pod named "mysql-1-deploy" becomes ready
    When I run the :set_env client command with:
      | resource | dc/mysql                 |
      | from     | configmap/special-config |
      | prefix   |  MYSQL_                  |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc    |
      | resource_name | mysql |
      | o             | yaml  |
    Then the output by order should match:
      | - name: MYSQL_SPECIAL_HOW  |
      | valueFrom:                 |
      | configMapKeyRef:           |
      | key: special.how           |
      | name: special-config       |
    And the output by order should match:
      | - name: MYSQL_SPECIAL_TYPE |
      | valueFrom:                 |
      | configMapKeyRef:           |
      | key: special.type          |
      | name: special-config       |
    Given a pod becomes ready with labels:
      | deployment=mysql-2         |
    When I run the :exec client command with:
      | pod          | <%= pod.name %> |
      | exec_command | env             |
    Then the step should succeed
    And the output should contain:
      | MYSQL_SPECIAL_HOW=very   |
      | MYSQL_SPECIAL_TYPE=charm |

  # @author chezhang@redhat.com
  # @case_id OCP-11305
  Scenario: Set pod env vars from secrets
    Given I have a project
    Given I obtain test data file "secrets/secret.yaml"
    When I run the :create client command with:
      | f | secret.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | secret |
    Then the output should match:
      | test-secret.*Opaque.*2 |
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json  |
      | param    | MYSQL_VERSION=latest |
    Then the step should succeed
    And the pod named "mysql-1-deploy" becomes ready
    When I run the :set_env client command with:
      | resource | dc/mysql           |
      | from     | secret/test-secret |
      | prefix   |  MYSQL_            |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc    |
      | resource_name | mysql |
      | o             | yaml  |
    Then the output by order should match:
      | - name: MYSQL_DATA_1 |
      | valueFrom:           |
      | secretKeyRef:        |
      | key: data-1          |
      | name: test-secret    |
      | - name: MYSQL_DATA_2 |
      | valueFrom:           |
      | secretKeyRef:        |
      | key: data-2          |
      | name: test-secret    |
    Given a pod becomes ready with labels:
      | deployment=mysql-2   |
    When I run the :exec client command with:
      | pod          | <%= pod.name %> |
      | exec_command | env             |
    Then the step should succeed
    And the output should contain:
      | MYSQL_DATA_1=value-1 |
      | MYSQL_DATA_2=value-2 |

  # @author chezhang@redhat.com
  # @case_id OCP-11607
  Scenario: Special test for set pod env vars
    Given I have a project
    Given I obtain test data file "secrets/secret.yaml"
    When I run the :create client command with:
      | f | secret.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | secret      |
    Then the output should match:
      | test-secret.*Opaque.*2 |
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json |
      | param    | MYSQL_VERSION=5.6 |
    Then the step should succeed
    And the pod named "mysql-1-deploy" becomes ready
    When I run the :set_env client command with:
      | resource | dc/mysql        |
      | from     | secret/no_exist |
      | prefix   |  MYSQL_         |
    Then the step should fail
    And the output should contain:
      | secrets "no_exist" not found  |
    When I run the :set_env client command with:
      | resource | dc/mysql           |
      | from     | secret/test-secret |
    Then the step succeeded
    When I run the :get client command with:
      | resource      | dc    |
      | resource_name | mysql |
      | o             | yaml  |
    Then the output by order should match:
      | - name: DATA_1        |
      | valueFrom:            |
      | secretKeyRef:         |
      | key: data-1           |
      | name: test-secret     |
      | - name: DATA_2        |
      | valueFrom:            |
      | secretKeyRef:         |
      | key: data-2           |
      | name: test-secret     |
    Given a pod becomes ready with labels:
      | deployment=mysql-2    |
    When I run the :exec client command with:
      | pod          | <%= pod.name %> |
      | exec_command | env             |
    Then the step should succeed
    And the output should contain:
      | DATA_1=value-1 |
      | DATA_2=value-2 |
    When I run the :set_env client command with:
      | resource | dc/mysql    |
      | prefix   |  MYSQL_     |
      | e        | NAME=mytest |
    Then the step succeeded
    When I run the :get client command with:
      | resource      | dc     |
      | resource_name | mysql  |
      | o             | yaml   |
    Then the output by order should match:
      | - name: MYSQL_NAME     |
      | value: mytest          |
    Given a pod becomes ready with labels:
      | deployment=mysql-3     |
    When I run the :exec client command with:
      | pod          | <%= pod.name %> |
      | exec_command | env                |
    Then the step should succeed
    And the output should contain:
      | MYSQL_NAME=mytest |
