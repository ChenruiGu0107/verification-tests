Feature: oc_set_env.feature
  # @author wewang@redhat.com
  # @case_id 520276
  Scenario: Set environment variables for resources using oc set env
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json  |
    And the step succeeded
    # set one enviroment variable
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build |
      | e        | key=value     |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      | key=value      |
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build |
      | e        | key=value,key1=value1,key2=value2 |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      | key=value      |
      | key1=value1    |
      | key2=value2    |
    # set enviroment variable via STDIN
    When I run the :set_env client command with:
      | resource |  bc/ruby-sample-build  |
      | e        | -             |
      | _stdin   | key3=value3   |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build |
      | list     | true |
    Then the step should succeed
    And the output should contain:
      | key=value      |
      | key1=value1    |
      | key2=value2    |
      | key3=value3    |
    # set invalid enviroment variable
    When I run the :env client command with:
      | resource | bc/ruby-sample-build |
      | e        | pe#cial%=1234 |
    Then the step should fail
    And the output should contain:
      | Invalid value: "pe#cial%"   |
      | must be a C identifier   |

  # @author wewang@redhat.com
  # @case_id 520277
  Scenario: Update environment variables for resources using oc set env
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json  |
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
    And the output should not contain:
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

  # @author wewang@redhat.com
  # @case_id 520275
  Scenario: Remove environment variables for resources using oc set env
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json  |
    And the step succeeded
    # set environment variables
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build |
      | all      | true       |
      | e        |  FOO=bar   |
    Then the step succeeded
    # list environment variables
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build |
      | list     | true        |
    Then the step should succeed
    And the output should contain:
      | FOO=bar |
    # remove environment variables
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build  |
      | env_name | FOO-       |
    Then the step succeeded
    # list environment variables
    When I run the :set_env client command with:
      | resource | bc/ruby-sample-build |
      | list     | true        |
    Then the step should succeed
    And the output should not contain:
      | FOO=bar |
    #Remove variables in json file and update dc in server
    When I run the :get client command with:
      | resource | dc   |
      | o        | json |
    Then the step succeeded
    Given evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :dc_one clipboard
    Given evaluation of `@result[:parsed]['items'][1]['metadata']['name']` is stored in the :dc_two clipboard
    # set environment variables
    When I run the :set_env client command with:
      | resource | dc   |
      | all      | true |
      | e        | FOO=bar |
    Then the step succeeded
    When I run the :set_env client command with:
      | resource | dc   |
      | list     | true |
      | all      | true |
    Then the step should succeed
    And the output by order should contain:
      | # deploymentconfigs <%= cb.dc_one %> |
      | FOO=bar |
      | # deploymentconfigs <%= cb.dc_two %> |
      | FOO=bar |
    #remove env from json and update service
    And I run the :get client command with:
      | resource      | dc                 |
      | o             | json               |
    Then the step should succeed
    When I save the output to file>dc.json
    When I run the :set_env client command with:
      | f        | dc.json   |
      | env_name | FOO- |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | dc   |
      | list     | true |
      | all      | true |
    And the output by order should not contain:
      | # deploymentconfigs <%= cb.dc_one %> |
      | FOO=bar |
      | # deploymentconfigs <%= cb.dc_two %> |
      | FOO=bar |
    #Remove the environment variable ENV from container in all deployment configs
    When I run the :set_env client command with:
      | resource | dc/frontend |
      | c        | ruby-helloworld |
      | env_name | MYSQL_USER- |
    Then the step should succeed
    And the output should not contain:
      | MYSQL_USER= |

  # @author chezhang@redhat.com
  # @case_id 531278
  Scenario: Set pod env vars from configmap
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | special-config.*2    |
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json  |
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
  # @case_id 531279
  Scenario: Set pod env vars from secrets
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | secret |
    Then the output should match:
      | test-secret.*Opaque.*2 |
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json  |
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
  # @case_id 531280
  Scenario: Special test for set pod env vars
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | secret      |
    Then the output should match:
      | test-secret.*Opaque.*2 |
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json  |
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
