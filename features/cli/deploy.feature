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
