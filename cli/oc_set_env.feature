Feature: oc_set_env.feature

  # @author wewang@redhat.com
  # @case_id OCP-11567
  Scenario: Update environment variables for resources using oc set env
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc470422/application-template-stibuild.json | 
    And the step succeeded
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build    |
      | e        | FOO=bar |
    Then the step succeeded
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build    |
      | list     | true |
    Then the step succeeded
    And the output should contain:
      | FOO=bar      |
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build   |
      | e        |  FOO=foo |
    Then the step succeeded
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build   |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      |  FOO=foo      |
    #Output modified build config in YAML, and does not alter the object on the server
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build    |
      | e        | STORAGE_DIR=/data  |
      | o        | yaml  |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build    |
      | list     | true  |
    Then the step should succeed
    And the output should contain:
      |  STORAGE_DIR=/data      |
    When I run the :set_env client command with:
      | resource | rc/database-1    |
      | e        | ENV=prod  |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | rc/database-1   |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      | ENV=prod |

  # @author chezhang@redhat.com
  # @case_id OCP-10888
  @smoke
  Scenario: Set pod env vars from configmap
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | special-config.*2    |
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json |
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
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/secret.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | secret |
    Then the output should match:
      | test-secret.*Opaque.*2 |
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json  |
      | param    | MYSQL_VERSION=5.6 |
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
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/secret.yaml |
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

  # @author wewang@redhat.com
  # @case_id OCP-11299
  Scenario: Set environment variables for resources using oc set env --overwrite=false
    Given I have a project
    When I run the :run client command with:
      | name  | hello-rc  |
      | image | openshift/hello-openshift |
      | generator | run-controller/v1 |
    And the step succeeded
    # Set an env variable into rc pod template
    When I run the :set_env client command with:
      | resource | rc/hello-rc  |
      | e        | MY_ENV=VALUE-1 |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | rc/hello-rc |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      | MY_ENV=VALUE-1  |
    # Use "--overwrite=false" when using "oc env -e"
    When I run the :set_env client command with:
      | resource  | rc/hello-rc    |
      | e         | MY_ENV=VALUE-2 |
      | overwrite | false          |
    Then the step should fail
    When I run the :set_env client command with:
      | resource | rc/hello-rc |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      | MY_ENV=VALUE-1  |
    #Use "--overwrite=false" when not using "-e" flag
    When I run the :set_env client command with:
      | resource  | rc/hello-rc    |
      |          | MY_ENV=VALUE-3 |
      | overwrite | false          |
    Then the step should fail
    When I run the :set_env client command with:
      | resource | rc/hello-rc |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      | MY_ENV=VALUE-1  |
