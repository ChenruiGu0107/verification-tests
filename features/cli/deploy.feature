Feature: deployment related features

  # @author: xxing@redhat.com
  # @case_id: 483193
  Scenario: Restart a failed deployment by oc deploy
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
    And I run the :deploy client command with:
      | deployment_config | hooks |
      | cancel            ||
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should contain "hooks #1 deployment failed"
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | retry             ||
    Then the output should contain "retried #1"
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should contain "hooks #1 deployment running"

  # @author: xxing@redhat.com
  # @case_id: 457713
  Scenario: CLI rollback dry run
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :replace client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/updatev1.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc |
      | resource_name | hooks |
    Then the output should match:
      | NAME\s+TRIGGERS\s+LATEST VERSION |
      | hooks\s+ImageChange\s+2          |
    When I run the :rollback client command with:
      | deployment_name | hooks-1 |
      | dry_run         ||
    Then the output should match:
      | Strategy:\s+Rolling |
    When I run the :rollback client command with:
      | deployment_name         | hooks-1 |
      | dry_run                 ||
      | change_scaling_settings ||
      | change_strategy         ||
      | change_triggers         ||
    Then the output should match:
      | Triggers:\s+Config   |
      | Strategy:\s+Recreate |
      | Replicas:\s+1        |

  # @author: xxing@redhat.com
  # @case_id: 489262
  Scenario: Can't stop a deployment in Complete status
    Given I have a project
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given I save the output to file>app-stibuild.json
    When I run the :create client command with:
      | f | app-stibuild.json |
    Then the step should succeed
    # Wait till the deploy complete
    Given I wait for the pod named "database-1-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | database |
    Then the output should contain "database #1 deployed"
    When  I run the :describe client command with:
      | resource | dc |
      | name     | database |
    Then the output should match:
      | Deployment #1 \(latest\) |
      | Status:\s+Complete       |
      | Pods Status:\s+1 Running |
    When I run the :deploy client command with:
      | deployment_config | database |
      | cancel            ||
    Then the output should contain "no active deployments to cancel"
    When I run the :deploy client command with:
      | deployment_config | database |
    Then the output should contain "database #1 deployed"
    When I run the :describe client command with:
      | resource | dc |
      | name     | database |
    Then the output should match:
      | Status:\s+Complete |
    When I run the :deploy client command with:
      | deployment_config | database |
      | retry             ||
    Then the output should contain:
      | error: #1 is Complete; only failed deployments can be retried |
      | You can start a new deployment using the --latest option      |
    When I run the :get client command with:
      | resource | pod |
    Then the output should not contain:
      | database-1-deploy   |
      | database-1-prehook  |
      | database-1-posthook |

  # @author xxing@redhat.com
  # @case_id 454714
  Scenario: Negative test for rollback
    Given I have a project
    When I run the :rollback client command with:
      | deployment_name | non-exist |
    Then the output should contain:
      | error: non-exist is not a valid deployment or deploymentconfig |
    When I run the :rollback client command with:
      | deployment_name         | non-exist |
      | change_strategy         ||
      | change_triggers         ||
      | change_scaling_settings ||
    Then the output should contain:
      | error: non-exist is not a valid deployment or deploymentconfig |
    When I run the :rollback client command with:
      | deployment_name         | non-exist |
      | change_strategy         ||
      | change_triggers         ||
      | change_scaling_settings ||
      | dry_run                 ||
    Then the output should contain:
      | error: non-exist is not a valid deployment or deploymentconfig |
    When I run the :rollback client command with:
      | deployment_name         | non-exist |
      | output                  | yaml      |
      | change_strategy         ||
      | change_triggers         ||
      | change_scaling_settings ||
    Then the output should contain:
      | error: non-exist is not a valid deployment or deploymentconfig |

  # @author xxing@redhat.com
  # @case_id 491013
  Scenario: Manually make deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/manual.json |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should contain "hooks #1 deployment waiting for manual"
    When I run the :get client command with:
      | resource      | dc |
      | resource_name | hooks |
    Then the output should match:
      |NAME\s+TRIGGERS\s+LATEST VERSION |
      | hooks\s+0                       |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            ||
    Then the output should contain "Started deployment #1"
    # Wait the deployment till complete
    Given I wait for the pod named "hooks-1-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should contain "hooks #1 deployed"
    When I run the :get client command with:
      | resource      | dc |
      | resource_name | hooks |
    Then the output should match:
      |NAME\s+TRIGGERS\s+LATEST VERSION |
      | hooks\s+1                       |
    # Make the edit action
    When I run the :get client command with:
      | resource      | dc |
      | resource_name | hooks |
      | o             | json |
    And I save the output to file>hooks.json
    And I replace lines in "hooks.json":
      | Recreate | Rolling |
    When I run the :replace client command with:
      | f | hooks.json |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            ||
    Then the output should contain "Started deployment #2"
    When I run the :get client command with:
      | resource      | dc |
      | resource_name | hooks |
      | o             | yaml |
    Then the output should contain:
      | type: Rolling |

  # @author xxing@redhat.com
  # @case_id 457715
  Scenario: CLI rollback output to file
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :replace client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/updatev1.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hooks |
    Then the output should match:
      | NAME\s+TRIGGERS\s+LATEST VERSION |
      | hooks\s+ImageChange\s+2          |
    When I run the :rollback client command with:
      | deployment_name         | hooks-1 |
      | output                  | json  |
    #Show the container config only
    Then the output should match:
      | "value": "Plqe5Wev" |
    When I run the :rollback client command with:
      | deployment_name         | hooks-1 |
      | output                  | yaml  |
      | change_strategy         ||
      | change_triggers         ||
      | change_scaling_settings ||
    Then the output should match:
      | replicas:\s+1        |
      | type:\s+Recreate     |
      | value:\s+Plqe5Wev    |
      | type:\s+ConfigChange |

  # @author xxing@redhat.com
  # @case_id 457712 457717 457718
  Scenario Outline: CLI rollback two more components of deploymentconfig
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hooks |
      | o             | json |
    Then the output should contain:
      | "type": "Recreate"     |
      | "type": "ConfigChange" |
      | "replicas": 1          |
      | "value": "Plqe5Wev"    |
    When I run the :replace client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/updatev1.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hooks |
      | o             | json |
    Then the output should contain:
      | "type": "Rolling"         |
      | "type": "ImageChange"     |
      | "replicas": 2             |
      | "value": "Plqe5Wevchange" |
    When I run the :rollback client command with:
      | deployment_name         | hooks-1 |
      | change_triggers         ||
      | change_scaling_settings | <change_scaling_settings> |
      | change_strategy         | <change_strategy> |
    Then the output should contain:
      | #3 rolled back to hooks-1 |
    Given I wait for the pod named "hooks-3-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should contain:
      | hooks #3 deployed |
    When I run the :get client command with:
      | resource | pod |
    Then the output should match:
      | READY\s+STATUS |
      | 1/1\s+Running  |
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hooks |
      | o             | json |
    Then the output should contain:
      | "type": "ConfigChange" |
      | "value": "Plqe5Wev"    |
      | <changed_val1>         |
      | <changed_val2>         |
    Examples:
      | change_scaling_settings | change_strategy | changed_val1  | changed_val2       |
      | :false                  | :false          |               |                    |
      |                         | :false          | "replicas": 1 |                    |
      |                         |                 | "replicas": 1 | "type": "Recreate" |

  # @author xxing@redhat.com
  # @case_id 457716
  Scenario: CLI rollback with one component
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hooks |
      | o             | json |
    Then the output should contain:
      | "type": "Recreate"     |
      | "type": "ConfigChange" |
      | "replicas": 1          |
      | "value": "Plqe5Wev"    |
    When I run the :replace client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/updatev1.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hooks |
      | o             | json |
    Then the output should contain:
      | "type": "Rolling"         |
      | "type": "ImageChange"     |
      | "replicas": 2             |
      | "value": "Plqe5Wevchange" |
    When I run the :rollback client command with:
      | deployment_name         | hooks-1 |
    Then the output should contain:
      | #3 rolled back to hooks-1                                      |
      | Warning: the following images triggers were disabled           |
      | You can re-enable them with: oc deploy hooks --enable-triggers |
    Given I wait for the pod named "hooks-3-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should contain:
      | hooks #3 deployed |
    When I run the :get client command with:
      | resource | pod |
    Then the output should match:
      | READY\s+STATUS |
      | 1/1\s+Running  |
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hooks |
      | o             | json |
    Then the output should contain:
      | "value": "Plqe5Wev"    |
    And the output should not contain:
      | "type": "ConfigChange" |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | enable_triggers   ||
    Then the output should contain:
      | enabled image triggers |

  # @author pruan@redhat.com
  # @case_id 483192
  Scenario: oc deploy negative test
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hooks            |
      | o             | json             |
    And the output is parsed as JSON
    Then the expression should be true> @result[:parsed]['status']['latestVersion'] == 1
    When I get project deploymentconfig as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :dc_name clipboard
    When I run the :deploy client command with:
      | deployment_config | notreal |
    Then the step should fail
    Then the output should contain:
      | Error from server: deploymentConfig "notreal" not found |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | retry | true |
    Then the step should fail
    And the output should contain:
      | only failed deployments can be retried |
    Given I wait for the pod named "hooks-1-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |true |
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hooks |
      | o             | json  |
    And the output is parsed as JSON
    Then the expression should be true> @result[:parsed]['status']['latestVersion'] == 2

  # @author pruan@redhat.com
  # @case_id 483192
  Scenario: Negative test for deployment history
    Given I have a project
    When I run the :describe client command with:
      | resource | dc         |
      | name     | no-such-dc |
    Then the step should fail
    And the output should contain:
      | Error from server: deploymentConfig "no-such-dc" not found |
    When I run the :describe client command with:
      | resource | dc              |
      | name     | docker-registry |
    Then the step should fail
    And the output should contain:
      | Error from server: deploymentConfig "docker-registry" not found |

  # @author pruan@redhat.com
  # @case_id 487644
  Scenario: New depployment will be created once the old one is complete - single deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/sleepv1.json |
    # simulate 'oc edit'
    When I run the :get client command with:
      | resource      | dc |
      | resource_name | hooks |
      | o             | yaml |
    And I save the output to file>hooks.yaml
    And I replace lines in "hooks.yaml":
      | 200 | 10 |
      | latestVersion: 1 | latestVersion: 2 |
    When I run the :replace client command with:
      | f      | hooks.yaml |
    Then the step should succeed
    And I wait until the status of depolyment config "hooks" with version "1" is :running
    When I run the :deploy client command with:
      | deployment_config      | hooks |
    Then the step should succeed
    And the output should contain:
      | hooks #2 deployment pending on update |
      | hooks #1 deployment running |
    And I wait until the status of depolyment config "hooks" with version "2" is :running
    And I run the :describe client command with:
      | resource | dc |
      | name     | hooks |
    Then the step should succeed
    And the output should contain:
      | <%= "Latest Version:\\t2" %>|
      | Deployment #2 (latest) |
      | <%= "Status:\\t\\tRunning" %> |
      | Deployment #1:   | 
      | <%= "Status:\\t\\tComplete" %> |


  # @author pruan@redhat.com
  # @case_id 484483
  Scenario: Deployment succeed when running time is less than ActiveDeadlineSeconds
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
       # simulate 'oc edit'
    When the pod named "hooks-1-deploy" becomes ready

    When I run the :get client command with:
      | resource      | pod            |
      | resource_name | hooks-1-deploy |
      | o             | yaml           |
    And I save the output to file>hooks.yaml
   And I replace lines in "hooks.yaml":
      | activeDeadlineSeconds: 21600 | activeDeadlineSeconds: 300 |
    When I run the :replace client command with:
      | f | hooks.yaml |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=hooks-1 |
      | deploymentconfig=hooks |

