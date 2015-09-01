Feature: deployment related features

  #@author: xxing@redhat.com
  #@case_id: 483193
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

  #@author: xxing@redhat.com
  #@case_id: 457713
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

  #@author: xxing@redhat.com
  #@case_id: 489262
  Scenario: Can't stop a deployment in Complete status
    Given I have a project
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given I save the output to file>app-stibuild.json
    When I run the :create client command with:
      | f | app-stibuild.json |
    Then the step should succeed
    #wait till the deploy complete
    Given a pod becomes ready with labels:
      | deployment=database-1 |
    Given I wait for the "database" service to become ready
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
