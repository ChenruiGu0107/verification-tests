Feature: deployment related features

  # @author xxing@redhat.com
  # @case_id OCP-12543
  Scenario: Restart a failed deployment by oc deploy
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    # Wait and make the cancel succeed stably
    And I wait until the status of deployment "hooks" becomes :running
    When  I run the :deploy client command with:
      | deployment_config | hooks |
      | cancel            |       |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :failed
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should match "hooks.*#1.*failed"
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | retry             |       |
    Then the output should contain "etried #1"
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should match "hooks.*#1.*deployed"

  # @author xxing@redhat.com
  # @case_id OCP-11072
  Scenario: CLI rollback dry run
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :replace client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/updatev1.json |
    Then the step should succeed
    When I get project dc named "hooks"
    Then the output should match:
      | hooks.*|
    When I run the :rollback client command with:
      | deployment_name | hooks-1 |
      | dry_run         |         |
    Then the output should match:
      | Strategy:\\s+Rolling |
    When I run the :rollback client command with:
      | deployment_name         | hooks-1 |
      | dry_run                 |         |
      | change_scaling_settings |         |
      | change_strategy         |         |
      | change_triggers         |         |
    Then the output should match:
      | Triggers:\\s+Config   |
      | Strategy:\\s+Recreate |
      | Replicas:\\s+1        |

  # @author xxing@redhat.com
  # @case_id OCP-12034
  Scenario: Can't stop a deployment in Complete status
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    # Wait till the deploy complete
    And the pod named "deployment-example-1-deploy" becomes ready
    Given I wait for the pod named "deployment-example-1-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | deployment-example |
    Then the output should match "deployment-example.+#1.+deployed"
    When  I run the :describe client command with:
      | resource | dc                 |
      | name     | deployment-example |
    Then the output should match:
      | Deployment\\s+#1.*latest |
      | Status:\\s+Complete       |
      | Pods Status:\\s+1 Running |
    When I run the :deploy client command with:
      | deployment_config | deployment-example |
      | cancel            |                    |
    Then the output should contain "No deployments are in progress"
    When I run the :deploy client command with:
      | deployment_config | deployment-example |
    Then the output should match "deployment-example.+#1.+deployed"
    When I run the :describe client command with:
      | resource | dc                 |
      | name     | deployment-example |
    Then the output should match:
      | Status:\\s+Complete |
    When I run the :deploy client command with:
      | deployment_config | deployment-example |
      | retry             |                    |
    Then the output should contain:
      | #1 is Complete; only failed deployments can be retried |
      | You can start a new deployment                         |
    When I get project pod
    Then the output should not contain:
      | deployment-example-1-deploy |

  # @author xxing@redhat.com
  # @case_id OCP-12623
  Scenario: Negative test for rollback
    Given I have a project
    When I run the :rollback client command with:
      | deployment_name | non-exist |
    Then the output should contain:
      | error: non-exist |
    When I run the :rollback client command with:
      | deployment_name         | non-exist |
      | change_strategy         |           |
      | change_triggers         |           |
      | change_scaling_settings |           |
    Then the output should contain:
      | error: non-exist |
    When I run the :rollback client command with:
      | deployment_name         | non-exist |
      | change_strategy         |           |
      | change_triggers         |           |
      | change_scaling_settings |           |
      | dry_run                 |           |
    Then the output should contain:
      | error: non-exist |
    When I run the :rollback client command with:
      | deployment_name         | non-exist |
      | output                  | yaml      |
      | change_strategy         |           |
      | change_triggers         |           |
      | change_scaling_settings |           |
    Then the output should contain:
      | error: non-exist |

  # @author xxing@redhat.com
  # @case_id OCP-10643
  @smoke
  Scenario: Manually make deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/manual.json |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should match "hooks.+#1.+waiting for manual"
    When I get project dc named "hooks"
    Then the output should match:
      | hooks\\s+0 |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the output should contain "Started deployment #1"
    # Wait the deployment till complete
    And the pod named "hooks-1-deploy" becomes ready
    Given I wait for the pod named "hooks-1-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should match "hooks.+#1.+deployed"
    When I get project dc named "hooks"
    Then the output should match:
      | hooks\\s+1 |
    # Make the edit action
    When I get project dc named "hooks" as JSON
    And I save the output to file>hooks.json
    And I replace lines in "hooks.json":
      | Recreate | Rolling |
    When I run the :replace client command with:
      | f | hooks.json |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the output should contain "Started deployment #2"
    When I get project dc named "hooks" as YAML
    Then the output should contain:
      | type: Rolling |

  # @author xxing@redhat.com
  # @case_id OCP-11695
  Scenario: CLI rollback output to file
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :replace client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/updatev1.json |
    Then the step should succeed
    When I get project dc named "hooks"
    Then the output should match:
      | hooks.*|
    When I run the :rollback client command with:
      | deployment_name         | hooks-1 |
      | output                  | json    |
    #Show the container config only
    Then the output should match:
      | "[vV]alue": "Plqe5Wev" |
    When I run the :rollback client command with:
      | deployment_name         | hooks-1 |
      | output                  | yaml    |
      | change_strategy         |         |
      | change_triggers         |         |
      | change_scaling_settings |         |
    Then the output should match:
      | [rR]eplicas:\\s+1        |
      | [tT]ype:\\s+Recreate     |
      | [vV]alue:\\s+Plqe5Wev    |
      | [tT]ype:\\s+ConfigChange |

  # @author xxing@redhat.com
  # @case_id OCP-12624 OCP-12018 OCP-12116
  Scenario Outline: CLI rollback two more components of deploymentconfig
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I get project dc named "hooks" as JSON
    Then the output should contain:
      | "type": "Recreate"     |
      | "type": "ConfigChange" |
      | "replicas": 1          |
      | "value": "Plqe5Wev"    |
    When I run the :replace client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/updatev1.json |
    Then the step should succeed
    When I get project dc named "hooks" as JSON
    Then the output should contain:
      | "type": "Rolling"         |
      | "type": "ImageChange"     |
      | "replicas": 2             |
      | "value": "Plqe5Wevchange" |
    When I run the :rollback client command with:
      | deployment_name         | hooks-1                   |
      | change_triggers         |                           |
      | change_scaling_settings | <change_scaling_settings> |
      | change_strategy         | <change_strategy>         |
    Then the output should contain:
      | #3 rolled back to hooks-1 |
    And the pod named "hooks-3-deploy" becomes ready
    Given I wait for the pod named "hooks-3-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should match:
      | hooks.+#3.+deployed |
    When I get project pod
    Then the output should match:
      | READY\\s+STATUS |
      | 1/1\\s+Running  |
    When I get project dc named "hooks" as JSON
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
  # @case_id OCP-11877
  Scenario: CLI rollback with one component
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I get project dc named "hooks" as JSON
    Then the output should contain:
      | "type": "Recreate"     |
      | "type": "ConfigChange" |
      | "replicas": 1          |
      | "value": "Plqe5Wev"    |
    When I run the :replace client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/updatev1.json |
    Then the step should succeed
    When I get project dc named "hooks" as JSON
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
      | You can re-enable them with |
    And the pod named "hooks-3-deploy" becomes ready
    Given I wait for the pod named "hooks-3-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should match:
      | hooks.*#3.*deployed |
    When I get project pod
    Then the output should match:
      | READY\\s+STATUS |
      | (Running)?(Pending)?  |
    When I get project dc named "hooks" as JSON
    Then the output should contain:
      | "value": "Plqe5Wev"    |
    And the output should contain:
      | "type": "ImageChange" |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | enable_triggers   |       |
    Then the output should contain:
      | Enabled image triggers |

  # @author pruan@redhat.com
  # @case_id OCP-12536
  Scenario: oc deploy negative test
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I get project dc named "hooks" as JSON
    Then the expression should be true> @result[:parsed]['status']['latestVersion'] == 1
    When I get project deploymentconfig as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :dc_name clipboard
    When I run the :deploy client command with:
      | deployment_config | notreal |
    Then the step should fail
    Then the output should match:
      | Error\\s+.*\\s+"notreal" not found |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | retry             | true  |
    Then the step should fail
    And the output should contain:
      | only failed deployments can be retried |
    Given I wait for the pod named "hooks-1-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    When I get project dc named "hooks" as JSON
    Then the expression should be true> @result[:parsed]['status']['latestVersion'] == 2

  # @author pruan@redhat.com
  # @case_id OCP-12402
  Scenario: Negative test for deployment history
    Given I have a project
    When I run the :describe client command with:
      | resource | dc         |
      | name     | no-such-dc |
    Then the step should fail
    And the output should match:
      | Error\\s+.*\\s+"no-such-dc" not found |
    When I run the :describe client command with:
      | resource | dc              |
      | name     | docker-registry |
    Then the step should fail
    And the output should match:
      | Error\\s+.*\\s+"docker-registry" not found |

  # @author pruan@redhat.com
  # @case_id 487644
  Scenario: New deployment will be created once the old one is complete - single deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/sleepv1.json |
    # simulate 'oc edit'
    When I get project dc named "hooks" as YAML
    And I save the output to file>hooks.yaml
    And I replace lines in "hooks.yaml":
      | 200              | 10               |
      | latestVersion: 1 | latestVersion: 2 |
    When I run the :replace client command with:
      | f | hooks.yaml |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :running
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the step should succeed
    And the output should contain:
      | hooks #2 deployment pending on update |
      | hooks #1 deployment running           |
    And I wait until the status of deployment "hooks" becomes :complete
    And I run the :describe client command with:
      | resource | dc    |
      | name     | hooks |
    Then the step should succeed
    And the output should match:
      | Latest Version:\\s+2 |
      | Deployment\\s+#2\\s+ |
      | Status:\\s+Complete  |
      | Deployment #1:       |
      | Status:\\s+Complete  |


  # @author pruan@redhat.com
  # @case_id 484483
  Scenario: Deployment succeed when running time is less than ActiveDeadlineSeconds
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    # simulate 'oc edit'
    When the pod named "hooks-1-deploy" becomes ready
    When I get project pod named "hooks-1-deploy" as YAML
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
      | deployment=hooks-1     |
      | deploymentconfig=hooks |

  # @author pruan@redhat.com
  # @case_id OCP-12133
  Scenario: Can't stop a deployment in Failed status
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/test-stop-failed-deployment.json |
    When the pod named "test-stop-failed-deployment-1-deploy" becomes ready
    When I run the :deploy client command with:
      | deployment_config | test-stop-failed-deployment |
    Then the step should succeed
    And I run the :deploy client command with:
      | deployment_config | test-stop-failed-deployment |
      | cancel            | true                        |
    Then the step should succeed
    And the output should contain:
      | Cancelled deployment #1 |
    Given I wait up to 40 seconds for the steps to pass:
    """
    When  I run the :describe client command with:
      | resource | dc                           |
      | name     | test-stop-failed-deployment  |
    Then the step should succeed
    Then the output by order should match:
      | Deployment #1      |
      | Status:\\s+Failed  |
    """
    And I run the :deploy client command with:
      | deployment_config | test-stop-failed-deployment |
      | cancel            | true                        |
    Then the step should succeed
    And the output should contain:
      | No deployments are in progress |
    And I run the :deploy client command with:
      | deployment_config | test-stop-failed-deployment |
    Then the step should succeed
    And the output should match:
      | test-stop-failed-deployment.*#1.*cancelled |

  # @author pruan@redhat.com
  # @case_id OCP-10633
  Scenario: Deployment is automatically stopped when running time is more than ActiveDeadlineSeconds
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/sleepv1.json|
    # simulate 'oc edit'
    When the pod named "hooks-1-deploy" becomes ready
    When I get project pod named "hooks-1-deploy" as YAML
    And I save the output to file>hooks.yaml
    And I replace lines in "hooks.yaml":
      | activeDeadlineSeconds: 21600 | activeDeadlineSeconds: 2 |
    When I run the :replace client command with:
      | f | hooks.yaml |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the step should succeed
    And the output should match:
      | hooks.*#1.*failed |


  # @author pruan@redhat.com
  # @case_id OCP-12196
  Scenario: Stop a "Pending" deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    And I wait until the status of deployment "hooks" becomes :running
    And I run the :deploy client command with:
      | deployment_config | hooks |
      | cancel            |       |
    Then the step should succeed
    And the output should match:
      | [Cc]ancelled deployment #1 |
    And I wait until the status of deployment "hooks" becomes :failed
    And I run the :deploy client command with:
      | deployment_config | hooks |
      | retry             |       |
    Then the output should match:
      | etried #1 |
    And I run the :describe client command with:
      | resource | dc   |
      | name     | hook |
    Then the step should succeed
    And I run the :deploy client command with:
      | deployment_config | hooks |
    And I wait until the status of deployment "hooks" becomes :complete

  # @author pruan@redhat.com
  # @case_id OCP-12246
  Scenario: Stop a "Running" deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    And I wait until the status of deployment "hooks" becomes :running
    And I wait up to 60 seconds for the steps to pass:
    """
    And I run the :deploy client command with:
      | deployment_config | hooks |
      | cancel            |       |
    Then the step should succeed
    """
    And the output should match:
      | ancelled deployment #1 |
    And I wait until the status of deployment "hooks" becomes :failed
    And I run the :deploy client command with:
      | deployment_config | hooks |
      | retry             |       |
    Then the output should match:
      | etried #1 |
    And I run the :describe client command with:
      | resource | dc   |
      | name     | hook |
    Then the step should succeed
    And I run the :deploy client command with:
      | deployment_config | hooks |
    And I wait until the status of deployment "hooks" becomes :complete

  # @author pruan@redhat.com
  # @case_id 490716
  Scenario: Make a new deployment by using a invalid LatestVersion
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And I wait until the status of deployment "hooks" becomes :complete
    And I replace resource "dc" named "hooks" saving edit to "tmp_out.yaml":
      | latestVersion: 2 | latestVersion: -1 |
    Then the step should fail
    When I run the :get client command with:
      | resource      | dc    |
      | resource_name | hooks |
      | template      | {{.status.latestVersion}} |
    Then the output should match "2"
    And I replace resource "dc" named "hooks":
      | latestVersion: 2 | latestVersion: 0 |
    Then the step should fail
    When I run the :get client command with:
      | resource      | dc                        |
      | resource_name | hooks                     |
      | template      | {{.status.latestVersion}} |
    Then the output should match "2"
    And I replace resource "dc" named "hooks":
      | latestVersion: 2 | latestVersion: 5 |
    Then the step should fail
    When I run the :get client command with:
      | resource      | dc                        |
      | resource_name | hooks                     |
      | template      | {{.status.latestVersion}} |
    Then the output should match "2"

  # @author pruan@redhat.com
  # @case_id OCP-10635
  Scenario: Deployment will be failed if deployer pod no longer exists
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    # deployment 1
    And I wait until the status of deployment "hooks" becomes :complete
    # deployment 2
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And I wait until the status of deployment "hooks" becomes :complete
    # deployment 3
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    Then I run the :describe client command with:
      | resource | dc    |
      | name     | hooks |
    And the output by order should contain:
      | Deployment #3 (latest):   |
      |  Status:		Complete      |
      | Deployment #2:            |
      |  Status:		Complete      |
      | Deployment #1:            |
      | Status:		Complete        |
    And I replace resource "rc" named "hooks-2":
      | Complete | Running |
    Then the step should succeed
    And I replace resource "rc" named "hooks-3":
      | Complete | Pending |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :rollout_latest client command with:
      | resource | hooks |
    Then the step should succeed
    """
    And I wait until the status of deployment "hooks" becomes :complete
    Then I run the :describe client command with:
      | resource | dc    |
      | name     | hooks |
    And the output by order should contain:
      | Deployment #4 (latest): |
      | Status:		Complete      |
      | Deployment #3:          |
      | Status:		Failed        |
      | Deployment #2:          |
      | Status:		Failed        |

  # @author cryan@redhat.com
  # @case_id OCP-10648
  Scenario: Roll back via CLI
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json"
    Then the step should succeed
    And I replace lines in "deployment1.json":
      | user8Y2      | usernew                         |
      | "status": {} | "status": {"latestVersion":"2"} |
    Given I wait until the status of deployment "hooks" becomes :complete
    When I run the :replace client command with:
      | f | deployment1.json |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete

    # Workaround: the below steps make a failed deployment instead of --cancel
    Given I successfully patch resource "dc/hooks" with:
      | {"spec":{"strategy":{"recreateParams":{"pre":{ "execNewPod": { "command": [ "/bin/false" ], "containerName": "hello-openshift" }, "failurePolicy": "Abort" }}}}} |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should succeed
    And the output should contain "Started deployment #3"
    And I wait until the status of deployment "hooks" becomes :failed

    # Remove the pre-hook introduced by the above workaround,
    # otherwise later deployment will always fail
    Given I successfully patch resource "dc/hooks" with:
      | {"spec":{"strategy":{"recreateParams":{"pre":null}}}} |
    When I run the :rollback client command with:
      | deployment_name   | hooks |
    Then the step should succeed
    # Deployment #4
    And the output should contain "rolled back to hooks-2"

    Given I wait until the status of deployment "hooks" becomes :complete
    When I run the :rollback client command with:
      | deployment_name   | hooks |
      | to_version        | 1     |
    Then the step should succeed
    # Deployment #5
    And the output should contain "rolled back to hooks-1"

    Given I wait until the status of deployment "hooks" becomes :complete
    When I run the :rollback client command with:
      | deployment_name | dc/hooks |
    Then the step should succeed
    # Deployment #6
    And the output should contain "rolled back to hooks-4"

  # @author pruan@redhat.com
  # @case_id OCP-12528
  Scenario: Make multiple deployment by oc deploy
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I get project dc named "hooks"
    Then the output should match:
      |NAME         |
      |hooks.*onfig |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should fail
    And the output should contain:
      | error       |
      | in progress |
    Given I wait for the pod named "hooks-1-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should succeed
    # Given I wait for the pod named "hooks-2-deploy" to die
    When I get project dc named "hooks"
    Then the step should succeed
    And the output should match:
      |NAME         |
      |hooks.*onfig |
    # This deviate form the testplan a little in that we are not doing more than one deploy, which should be sufficient since we are checking two deployments already (while the testcase called for 5)

  # @author cryan@redhat.com
  # @case_id OCP-11131
  @admin
  Scenario: Check the default option value for command oadm prune deployments
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given I wait for the pod named "database-1-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | database            |
      | n                 | <%= project.name %> |
      | latest            |                     |
    Then the step should succeed
    Given I wait for the pod named "database-2-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | database            |
      | n                 | <%= project.name %> |
      | latest            |                     |
    Then the step should succeed
    Given I wait for the pod named "database-3-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | database            |
      | n                 | <%= project.name %> |
      | latest            |                     |
    Then the step should succeed
    Given I wait for the pod named "database-4-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | database            |
      | n                 | <%= project.name %> |
      | latest            |                     |
    Then the step should succeed
    Given I wait for the pod named "database-5-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | database            |
      | n                 | <%= project.name %> |
      | latest            |                     |
    Then the step should succeed
    Given I wait for the pod named "database-6-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | database            |
      | n                 | <%= project.name %> |
      | latest            |                     |
    Then the step should succeed
    Given I wait for the pod named "database-7-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | database            |
      | n                 | <%= project.name %> |
      | latest            |                     |
    Then the step should succeed
    Given I wait for the pod named "database-8-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | database            |
      | n                 | <%= project.name %> |
      | latest            |                     |
    Then the step should succeed
    Given I wait for the pod named "database-9-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | database            |
      | n                 | <%= project.name %> |
      | cancel            |                     |
    Then the step should succeed
    When I run the :get client command with:
      | resource | rc                  |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | database-1 |
      | database-9 |
    When I run the :oadm_prune_deployments client command with:
      |h||
    Then the step should succeed
    And the output should contain "completed and failed deployments"
    Given 60 seconds have passed
    When I run the :oadm_prune_deployments admin command with:
      | keep_younger_than | 1m |
    Then the step should succeed
    And the output should match:
      |NAMESPACE\\s+NAME                   |
      |<%= project.name %>\\s+database-\\d+|
    When I run the :oadm_prune_deployments admin command with:
      | confirm | false |
    Then the step should succeed
    And the output should not match:
      |<%= project.name %>\\s+database-\\d+|

  # @author xiaocwan@redhat.com
  # @case_id OCP-10717
  Scenario: View the logs of the latest deployment
    # check deploy log when deploying
    Given I have a project
    When I run the :run client command with:
      |  name  | hooks                                                     |
      | image  | <%= project_docker_repo %>openshift/hello-openshift:latest|
    Then the step should succeed
    When I run the :logs client command with:
      | resource_name | dc/hooks |
      | f             |          |
    Then the output should match:
      | caling.*to\\s+1 |

    Given I collect the deployment log for pod "hooks-1-deploy" until it disappears
    And I run the :logs client command with:
      | resource_name | dc/hooks |
    Then the step should succeed
    And the output should contain "erving"

    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Given I wait until the status of deployment "hooks" becomes :running
    And I run the :deploy client command with:
      | deployment_config | hooks |
      | cancel            |       |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :failed
    # When deploy failed by cancelled 3.2 keeps the deploy pod, 3.3 will discard the pod,
    # logs are different, so better to check by `oc deploy dc` instead of `oc logs`
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the step should succeed
    And the output should match:
      | [Cc]ancelled.*user |
    # check for non-existent dc
    When I run the :logs client command with:
      | resource_name | dc/nonexistent |
    Then the step should fail
    And the output should match:
      | [Dd]eploymentconfigs.*not found |

  # @author yinzhou@redhat.com
  # @case_id OCP-9563
  Scenario: A/B Deployment
    Given I have a project
    When I run the :new_app client command with:
      | docker_image | <%= project_docker_repo %>openshift/deployment-example |
      | name         | ab-example-a                                           |
      | l            | ab-example=true                                        |
      | env          | SUBTITLE=shardA                                        |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | deploymentconfig |
      | resource_name | ab-example-a     |
      | name          | ab-example       |
      | selector      | ab-example=true  |
    Then the step should succeed
    When I expose the "ab-example" service
    Then I wait for a web server to become available via the "ab-example" route
    And the output should contain "shardA"
    When I run the :new_app client command with:
      | docker_image | <%= project_docker_repo %>openshift/deployment-example |
      | name         | ab-example-b                                           |
      | l            | ab-example=true                                        |
      | env          | SUBTITLE=shardB                                        |
    Then the step should succeed
    Then I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | ab-example-a     |
      | replicas | 0                |
    Given I wait until number of replicas match "0" for replicationController "ab-example-a-1"
    When I use the "ab-example" service
    Then I wait for a web server to become available via the "ab-example" route
    And the output should contain "shardB"
    Then I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | ab-example-b     |
      | replicas | 0                |
    Then I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | ab-example-a     |
      | replicas | 1                |
    Given I wait until number of replicas match "0" for replicationController "ab-example-b-1"
    When I use the "ab-example" service
    Then I wait for a web server to become available via the "ab-example" route
    And the output should contain "shardA"

  # @author yinzhou@redhat.com
  # @case_id OCP-9566
  Scenario: Blue-Green Deployment
    Given I have a project
    When I run the :new_app client command with:
      | docker_image | <%= project_docker_repo %>openshift/deployment-example:v1 |
      | name         | bluegreen-example-old                                     |
    Then the step should succeed
    When I run the :new_app client command with:
      | docker_image | <%= project_docker_repo %>openshift/deployment-example:v2 |
      | name         | bluegreen-example-new                                     |
    Then the step should succeed
    #When I expose the "bluegreen-example-old" service
    When I run the :expose client command with:
      | resource      | svc                   |
      | resource_name | bluegreen-example-old |
      | name          | bluegreen-example     |
    Then the step should succeed
    #And I wait for a web server to become available via the route
    When I use the "bluegreen-example-old" service
    And I wait for a web server to become available via the "bluegreen-example" route
    And the output should contain "v1"
    And I replace resource "route" named "bluegreen-example":
      | name: bluegreen-example-old | name: bluegreen-example-new |
    Then the step should succeed
    When I use the "bluegreen-example-new" service
    And I wait for the steps to pass:
    """
    And I wait for a web server to become available via the "bluegreen-example" route
    And the output should contain "v2"
    """

  # @author pruan@redhat.com
  # @case_id OCP-12532
  Scenario: Manually start deployment by oc deploy
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I get project dc named "hooks"
    Then the output should match:
      | hooks.*onfig |
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should succeed
    When I get project dc named "hooks"
    Then the output should match:
      | hooks.*onfig |

  # @author yinzhou@redhat.com
  # @case_id OCP-12468,510608
  Scenario: Pre and post deployment hooks
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/testhook.json |
    Then the step should succeed
    When the pod named "hooks-1-hook-pre" becomes ready
    And I get project pod named "hooks-1-hook-pre" as YAML
    And the output should match:
      | mountPath:\\s+/var/lib/origin |
      | emptyDir:                     |
      | name:\\s+dataem               |
    When the pod named "hooks-1-hook-post" becomes ready
    And I get project pod named "hooks-1-hook-post" as YAML
    And the output should match:
      | mountPath:\\s+/var/lib/origin |
      | emptyDir:                     |
      | name:\\s+dataem               |

  # @author pruan@redhat.com
  # @case_id OCP-12452, OCP-12460
  Scenario Outline: Failure handler of pre-post deployment hook
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/<file_name>|
    Then the step should succeed
    When the pod named "<pod_name>" is present
    And I wait up to 300 seconds for the steps to pass:

    """
      When I get project pod named "<pod_name>" as JSON
      Then the expression should be true> @result[:parsed]['status']['containerStatuses'][0]['restartCount'] > 1
    """
    Examples:
      | file_name | pod_name          |
      | pre.json  | hooks-1-hook-pre  |
      | post.json | hooks-1-hook-post |

  # @author cryan@redhat.com
  # @case_id OCP-9768
  Scenario: Could edit the deployer pod during deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc515805/tc515805.json |
    Then the step should succeed
    Given the pod named "database-1-deploy" becomes ready
    When I replace resource "pod" named "database-1-deploy":
      | activeDeadlineSeconds: 21600 | activeDeadlineSeconds: 55 |
    Then the step should succeed
    Given the pod named "database-1-deploy" status becomes :failed
    When I get project pods
    Then the output should contain "DeadlineExceeded"

  # @author yinzhou@redhat.com
  # @case_id OCP-10724
  Scenario: deployment hook volume inheritance that volume name was null
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc510606/hooks-null-volume.json |
    Then the step should fail
    And the output should contain "must not be empty"


  # @author yinzhou@redhat.com
  # @case_id OCP-11203
  Scenario: deployment hook volume inheritance -- that volume names which are not found
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc510607/hooks-unexist-volume.json |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain:
      | NAME            |
      | hooks-1-hook-pre|
    """

  # @author yadu@redhat.com
  # @case_id OCP-9567
  @smoke
  Scenario: Recreate deployment strategy
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/deployment/recreate-example.yaml |
    Then the step should succeed
    And I wait until the status of deployment "recreate-example" becomes :complete
    When I use the "recreate-example" service
    And I wait for a web server to become available via the "recreate-example" route
    Then the output should contain:
      | v1 |
    When I run the :tag client command with:
      | source | recreate-example:v2     |
      | dest   | recreate-example:latest |
    Then the step should succeed
    And I wait until the status of deployment "recreate-example" becomes :complete
    When I use the "recreate-example" service
    And I wait for a web server to become available via the "recreate-example" route
    Then the output should contain:
      | v2 |

  # @author pruan@redhat.com
  # @case_id OCP-11939
  Scenario: start deployment when the latest deployment is completed
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    And I replace resource "dc" named "hooks" saving edit to "tmp_out.yaml":
      | replicas: 1 | replicas: 2 |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    And I get project rc as JSON
    Then the expression should be true> @result[:parsed]['items'][0]['status']['replicas'] == 2

  # @author pruan@redhat.com
  # @case_id OCP-12056
  Scenario: Manual scale dc will update the deploymentconfig's replicas
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | dc    |
      | name     | hooks |
      | replicas | 2     |
    Then the step should succeed
    When I get project dc named "hooks" as JSON
    Then the expression should be true> @result[:parsed]['spec']['replicas'] == 2

    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    And I wait until number of replicas match "2" for replicationController "hooks-1"
#      And 10 pods become ready with labels:
#        |name=mysql|
    Then I run the :scale client command with:
      | resource | dc    |
      | name     | hooks |
      | replicas | 1     |
    And I wait until number of replicas match "1" for replicationController "hooks-1"


  # @author pruan@redhat.com
  # @case_id OCP-10728
  Scenario: Inline deployer hook logs
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/Inline-logs.json |
    And I run the :logs client command with:
      | f             | true     |
      | resource_name | dc/hooks |
    Then the output should contain:
      | pre:                                 |
      | Can't read /etc/scl/prefixes/mysql55 |
      | pre: Success                         |
      | post:                                |
      | Can't read /etc/scl/prefixes/mysql55 |
      | post: Success                        |

  # @author yinzhou@redhat.com
  # @case_id OCP-11070
  Scenario: Trigger info is retained for deployment caused by image changes
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    Given I wait until the status of deployment "frontend" becomes :complete
    When I get project dc named "frontend" as YAML
    Then the output by order should match:
      | causes:           |
      | - imageTrigger:   |
      | from:             |
      | type: ImageChange |

  # @author yinzhou@redhat.com
  # @case_id OCP-12622
  Scenario: Trigger info is retained for deployment caused by config changes
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    And I replace resource "dc" named "deployment-example":
      | terminationGracePeriodSeconds: 30 | terminationGracePeriodSeconds: 36 |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I get project dc named "deployment-example" as YAML
    Then the output by order should match:
      | terminationGracePeriodSeconds: 36 |
      | causes:                           |
      | - type: ConfigChange              |

  # @author yinzhou@redhat.com
  # @case_id OCP-11769
  Scenario: Start new deployment when deployment running
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/sleepv1.json |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :running
    And I replace resource "dc" named "hooks":
      | latestVersion: 1 | latestVersion: 2 |
    Then the step should succeed
    Given the pod named "hooks-2-deploy" status becomes :running
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the step should succeed
    And the output should match ".*newer.*running"

  # @author yinzhou@redhat.com
  # @case_id OCP-9829
  Scenario: Check the deployments in a completed state on test deployment configs
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/test-deployment.json |
    Then the step should succeed
    And I run the :logs client command with:
      | f | true |
      | resource_name | dc/hooks |
    Then the output should contain:
      | Scaling hooks-1 to 1 |
    And I wait until the status of deployment "hooks" becomes :complete
    When I get project rc named "hooks-1" as YAML
    Then the output by order should match:
      | phase: Complete |
      | status:         |
      | replicas: 0     |

  # @author yinzhou@redhat.com
  # @case_id OCP-9830
  Scenario: Check the deployments in a failed state on test deployment configs
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/test-deployment.json |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :running
    Given I successfully patch resource "pod/hooks-1-deploy" with:
      | {"spec":{"activeDeadlineSeconds":3}} |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the step should succeed
    And the output should match:
      | hooks.*#1.*failed |
    """
    When I get project rc named "hooks-1" as YAML
    Then the output by order should match:
      | phase: Failed |
      | status:       |
      | replicas: 0   |

  # @author pruan@redhat.com
  # @case_id OCP-9831
  Scenario: Scale the deployments will failed on test deployment config
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc518650/test.json |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    Then I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | hooks            |
      | replicas | 2                |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    And I wait until number of replicas match "0" for replicationController "hooks"

  # @author yinzhou@redhat.com
  # @case_id OCP-11769
  Scenario: Start new deployment when deployment running
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/testhook.json |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :running
    And I replace resource "dc" named "hooks":
      | latestVersion: 1 | latestVersion: 2 |
    Then the step should succeed
    Given  I wait up to 60 seconds for the steps to pass:
    """
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should contain "newer deployment was found running"
    """

  # @author cryan@redhat.com
  # @case_id OCP-12151
  Scenario: When the latest deployment failed auto rollback to the active deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Given a pod becomes ready with labels:
    | deployment=hooks-1 |
    Then I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | hooks            |
      | replicas | 2                |
    Given I wait until number of replicas match "2" for replicationController "hooks"
    Then I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | hooks            |
      | replicas | 1                |
    Given I wait until number of replicas match "1" for replicationController "hooks"
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    Then the step should succeed
    Given the pod named "hooks-2-deploy" is present
    When I run the :patch client command with:
      | resource      | pod                                   |
      | resource_name | hooks-2-deploy                        |
      | p             | {"spec":{"activeDeadlineSeconds": 5}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      |dc                        |
      | resource_name | hooks                    |
      | p             | {"spec":{"replicas": 2}} |
    Then the step should succeed
    When I get project pod named "hooks-2-deploy" as JSON
    Then the output should contain ""activeDeadlineSeconds": 5"
    When I get project dc named "hooks" as JSON
    Then the output should contain ""replicas": 2"
    Given all existing pods die with labels:
      | deployment=hooks-2 |
    When I get project pods with labels:
      | l | deployment=hooks-2 |
    Then the output should not contain "hooks-2"
    Given a pod becomes ready with labels:
      | deployment=hooks-1 |
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I get project pods
    And the output should contain:
      | DeadlineExceeded |
      | hooks-1          |
    """

  # @author yinzhou@redhat.com
  # @case_id OCP-10617
  @admin
  Scenario: DeploymentConfig should allow valid value of resource requirements
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/quota.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-with-resources.json |
      | n | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pod named "hooks-1-deploy" as YAML
    Then the output should match:
      | \\s+limits:\n\\s+cpu: 30m\n\\s+memory: 150Mi\n   |
      | \\s+requests:\n\\s+cpu: 30m\n\\s+memory: 150Mi\n |
    """
    And I wait until the status of deployment "hooks" becomes :complete
    And I wait for the steps to pass:
    """
    When I get project pod as YAML
    Then the output should match:
      | \\s+limits:\n\\s+cpu: 400m\n\\s+memory: 200Mi\n   |
      | \\s+requests:\n\\s+cpu: 400m\n\\s+memory: 200Mi\n |
    """

  # @author yinzhou@redhat.com
  # @case_id OCP-10850
  Scenario: Automatic set to false with ConfigChangeController on the DeploymentConfig
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    And I replace lines in "application-template-stibuild.json":
      |"automatic": true|"automatic": false|
    When I process and create "application-template-stibuild.json"
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    And I wait until the status of deployment "frontend" becomes :complete
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | lastTriggeredImage |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :imagestreamimage clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build finishes
    When I get project imagestream named "origin-ruby-sample" as JSON
    And evaluation of `@result[:parsed]['status']['tags'][0]['items']` is stored in the :imagestreamitems clipboard
    And the expression should be true> cb.imagestreamitems.length == 2
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | "latestVersion": 1 |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :sed_imagestreamimage clipboard
    And the expression should be true> cb.imagestreamimage == cb.sed_imagestreamimage

  # @author yinzhou@redhat.com
  # @case_id OCP-11586
  Scenario: Automatic set to true with ConfigChangeController on the DeploymentConfig
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    And I wait until the status of deployment "frontend" becomes :complete
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | lastTriggeredImage |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :imagestreamimage clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build finishes
    When I get project imagestream named "origin-ruby-sample" as JSON
    And evaluation of `@result[:parsed]['status']['tags'][0]['items']` is stored in the :imagestreamitems clipboard
    And the expression should be true> cb.imagestreamitems.length == 2
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | "latestVersion": 2 |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :sed_imagestreamimage clipboard
    And the expression should be true> cb.imagestreamimage != cb.sed_imagestreamimage

  # @author yinzhou@redhat.com
  # @case_id OCP-11489
  Scenario: app deploy successfully with correct registry credentials
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    Given the "ruby-hello-world-1" build was created
    Given the "ruby-hello-world-1" build completed
    Given I wait for the "ruby-hello-world" service to become ready
    When I expose the "ruby-hello-world" service
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And the output should contain "Demo App!"
    When I git clone the repo "https://github.com/openshift/ruby-hello-world" to "dummy"
    Given I replace lines in "dummy/views/main.erb":
      | Demo App | zhouying |
    Then the step should succeed
    And I commit all changes in repo "dummy" with message "test"
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | from_dir    | dummy            |
    Then the step should succeed
    Given the "ruby-hello-world-2" build completed
    And I wait until the status of deployment "ruby-hello-world" becomes :complete
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And the output should contain "zhouying"
    When I run the :rollback client command with:
      | deployment_name | ruby-hello-world |
      | to_version      | 1                |
    Then the step should succeed
    And I wait until the status of deployment "ruby-hello-world" becomes :complete
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And the output should contain "Demo App!"

  # @author yinzhou@redhat.com
  # @case_id OCP-11790
  Scenario: Automatic set to true without ConfigChangeController on the DeploymentConfig
    Given I have a project
    Given I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/build-deploy-without-configchange.json"
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    And I wait for the steps to pass:
    """
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | lastTriggeredImage     |
      | "latestVersion": 1     |
    """
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :imagestreamimage clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build finishes
    When I get project imagestream named "origin-ruby-sample" as JSON
    And evaluation of `@result[:parsed]['status']['tags'][0]['items']` is stored in the :imagestreamitems clipboard
    And the expression should be true> cb.imagestreamitems.length == 2
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | "latestVersion": 2 |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :sed_imagestreamimage clipboard
    And the expression should be true> cb.imagestreamimage != cb.sed_imagestreamimage

  # @author yinzhou@redhat.com
  # @case_id OCP-11281
  Scenario: Automatic set to false without ConfigChangeController on the DeploymentConfig
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/build-deploy-without-configchange.json"
    And I replace lines in "build-deploy-without-configchange.json":
      | "automatic": true | "automatic": false |
    When I process and create "build-deploy-without-configchange.json"
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    And I wait for the steps to pass:
    """
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | lastTriggeredImage |
    And the output should not contain:
      | "latestVersion": 1 |
    """
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :imagestreamimage clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build finishes
    When I get project imagestream named "origin-ruby-sample" as JSON
    And evaluation of `@result[:parsed]['status']['tags'][0]['items']` is stored in the :imagestreamitems clipboard
    And the expression should be true> cb.imagestreamitems.length == 2
    When I get project dc named "frontend" as JSON
    Then the output should not contain:
      | "latestVersion": 1 |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :sed_imagestreamimage clipboard
    And the expression should be true> cb.imagestreamimage == cb.sed_imagestreamimage

  # @author yinzhou@redhat.com
  # @case_id OCP-11221
  Scenario: Scale up when deployment running
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I run the :deploy client command with:
      | deployment_config | deployment-example |
      | latest            |                    |
    Then the step should succeed
    Then I run the :scale client command with:
      | resource | deploymentconfig   |
      | name     | deployment-example |
      | replicas | 2                  |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I get project dc named "deployment-example" as JSON
    Then the expression should be true> @result[:parsed]['spec']['replicas'] == 2

  # @author qwang@redhat.com
  # @case_id OCP-12356
  Scenario: configchange triggers deploy automatically
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    Given status becomes :succeeded of exactly 1 pods labeled:
      | name=hello-openshift |
    When I run the :env client command with:
      | resource | dc/hooks                   |
      | e        | MYSQL_PASSWORD=update12345 |
    Then the step should succeed
    When I get project dc named "hooks" as JSON
    Then the output should contain:
      | "latestVersion": 2 |
    Given I wait until number of replicas match "0" for replicationController "hooks-1"
    And I wait until number of replicas match "1" for replicationController "hooks-2"
    When I get project pod
    Then the output should match:
      | hooks-2.*Running |


  # @author mcurlej@redhat.com
  # @case_id OCP-11611
  Scenario: Could revert an application back to a previous deployment by 'oc rollout undo' command
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :env client command with:
      | resource | dc/hooks |
      | e        | TEST=123 |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :env client command with:
      | resource | dc/hooks |
      | list     | true     |
    Then the step should succeed
    And the output should contain "TEST=123"
    When I run the :rollout_undo client command with:
      | resource      | dc    |
      | resource_name | hooks |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :env client command with:
      | resource | dc/hooks |
      | list     | true     |
    Then the step should succeed
    And the output should not contain "TEST=123"
    When I run the :rollout_undo client command with:
      | resource      | dc    |
      | resource_name | hooks |
      | to_revision   | 2     |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :env client command with:
      | resource | dc/hooks |
      | list     | true     |
    Then the step should succeed
    And the output should contain "TEST=123"

  # @author mcurlej@redhat.com
  # @case_id OCP-11313
  Scenario: Check the status for deployment configs
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :get client command with:
      | resource      | dc    |
      | resource_name | hooks |
      | o             | json  |
    Then the step should succeed
    And evaluation of `@result[:parsed]['metadata']['generation']` is stored in the :prev_generation clipboard
    And evaluation of `@result[:parsed]['status']['observedGeneration']` is stored in the :prev_observed_generation clipboard
    When I run the :env client command with:
      | resource | dc/hooks |
      | e        | TEST=1   |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :get client command with:
      | resource      | dc    |
      | resource_name | hooks |
      | o             | json  |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['metadata']['generation'] - cb.prev_generation >= 1
    And the expression should be true> @result[:parsed]['status']['observedGeneration'] - cb.prev_observed_generation >= 1
    And the expression should be true> @result[:parsed]['status']['observedGeneration'] >= @result[:parsed]['metadata']['generation']

  # @author yinzhou@redhat.com
  # @case_id OCP-10916
  Scenario: Support endpoints of Deployment in OpenShift
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/extensions/deployment.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
    Then the step should succeed
    And the output should contain:
      | hello-openshift |
    When I run the :patch client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","ports":[{"containerPort":80}]}]}}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deployment                |
      | resource_name | hello-openshift           |
      | template      | {{.metadata.annotations}} |
    Then the step should succeed
    And the output should contain:
      | deployment.kubernetes.io/revision:2 |
    When I run the :delete client command with:
      | object_type       | deployment      |
      | object_name_or_id | hello-openshift |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I get project pods
    Then the step should succeed
    And the output should not contain "Terminating"
    And the output should not contain "Running"
    """
    When I get project rs
    Then the step should succeed
    And the output should not contain "hello-openshift.*"

  # @author yinzhou@redhat.com
  # @case_id OCP-11326
  @smoke
  Scenario: Support verbs of Deployment in OpenShift
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/extensions/deployment.yaml |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 2               |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deployment         |
      | resource_name | hello-openshift    |
      | template      | {{.spec.replicas}} |
    Then the output should match "2"
    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 1               |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deployment         |
      | resource_name | hello-openshift    |
      | template      | {{.spec.replicas}} |
    Then the output should match "1"
    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | deployment/hello-openshift |
      | e        | key=value                  |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | o             | yaml            |
    And the expression should be true> @result[:parsed]['metadata']['annotations']['deployment.kubernetes.io/revision'] == "1"
    And the expression should be true> @result[:parsed]['spec']['paused'] == true
    And the expression should be true> @result[:parsed]['spec']['template']['spec']['containers'][0]['env'].include?({"name"=>"key", "value"=>"value"})
    When I run the :env client command with:
      | resource | pods |
      | all      | true |
      | list     | true |
    And the output should not contain:
      | key=value      |
    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deployment                |
      | resource_name | hello-openshift           |
      | template      | {{.metadata.annotations}} |
    Then the step should succeed
    And the output should contain:
      | deployment.kubernetes.io/revision:2 |
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I run the :env client command with:
      | resource | pods |
      | all      | true |
      | list     | true |
    And the output should contain:
      | key=value |
    """
    When I run the :get client command with:
      | resource      | deployment                |
      | resource_name | hello-openshift           |
      | template      | {{.metadata.annotations}} |
    Then the step should succeed
    And the output should contain:
      | deployment.kubernetes.io/revision:2 |

  # @author mcurlej@redhat.com
  # @case_id OCP-12079
  Scenario: View the history of rollouts for a specific deployment config
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I run the :env client command with:
      | resource | dc/deployment-example |
      | e        | TEST=1                |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I run the :rollout_history client command with:
      | resource      | dc                 |
      | resource_name | deployment-example |
    Then the step should succeed
    And the output should contain:
      | image change  |
      | config change |
    When I run the :rollout_history client command with:
      | resource      | dc                 |
      | resource_name | deployment-example |
      | revision      | 2                  |
    Then the step should succeed
    And the output should match:
      | revision     |
      | Labels:      |
      | Containers:  |
      | Annotations: |

  # @author pruan@redhat.com
  # @case_id OCP-11973
  Scenario: Support MinReadySeconds in DC
    Given I have a project
    And evaluation of `60` is stored in the :min_ready_seconds clipboard
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc532415/min_ready.yaml
    Then the step should succeed
    And 20 seconds have passed
    And the expression should be true> dc('minreadytest').unavailable_replicas(user: user) == 2
    And 60 seconds have passed
    And the expression should be true> dc('minreadytest').available_replicas(user: user) == 2

  # @author mcurlej@redhat.com
  # @case_id OCP-10902
  @smoke
  Scenario: Auto cleanup old RCs
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc532411/history-limit-dc.yaml |
    Then the step should succeed
    When I run the steps 3 times:
    """
    When I run the :env client command with:
      | resource | dc/history-limit |
      | e        | TEST#{cb.i}=1    |
    Then the step should succeed
    And I wait until the status of deployment "history-limit" becomes :complete
    """
    When I run the :rollback client command with:
      | deployment_name | history-limit |
      | to_version      | 1             |
    Then the step should fail
    And the output should contain:
      | couldn't find deployment for rollback  |
    When I run the :env client command with:
      | resource | dc/history-limit |
      | e        | TEST4=4          |
    Then the step should succeed
    And I wait until the status of deployment "history-limit" becomes :complete
    And I wait for the steps to pass:
    """
    When I get project rc
    Then the output should not contain "history-limit-2"
    """

  # @author mcurlej@redhat.com
  # @case_id OCP-11812
  Scenario: Pausing and Resuming a Deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :rollout_pause client command with:
      | resource | dc    |
      | name     | hooks |
    Then the step should succeed
    When I get project dc named "hooks" as YAML
    Then the step should succeed
    And the output should match "paused:\s+?true"
    When I run the :env client command with:
      | resource | dc/hooks |
      | e        | TEST=123 |
    Then the step should succeed
    When I run the :env client command with:
      | resource | rc/hooks-1 |
      | list     | true       |
    Then the step should succeed
    And the output should not contain "TEST=123"
    When I get project rc as YAML
    Then the step should succeed
    # Check if that no new rc was created if the dc is paused
    And the output should not contain "hooks-2"
    When I run the :rollout_resume client command with:
      | resource | dc    |
      | name     | hooks |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :env client command with:
      | resource | rc/hooks-2 |
      | list     | true       |
    Then the step should succeed
    And the output should contain "TEST=123"


  # @author yinzhou@redhat.com
  # @case_id OCP-9973 OCP-9974
  Scenario Outline: custom deployment for Recreate/Rolling strategy
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/<file> |
    Then the step should succeed
    And I run the :logs client command with:
      | f             | true                 |
      | resource_name | dc/custom-deployment |
    Then the output should contain:
      | Reached 50% |
      | Halfway     |
      | Success     |
      | Finished    |
    Examples:
      | file                 |
      | custom-rolling.yaml  |
      | custom-recreate.yaml |


  # @author yinzhou@redhat.com
  # @case_id OCP-10973
  @admin
  Scenario: Should show deployment conditions correctly
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-ignores-deployer.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | database                                 |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "NewReplicationControllerCreated"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/testhook.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "NewReplicationControllerAvailable"
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When  I run the :deploy client command with:
      | deployment_config | hooks |
      | cancel            |       |
    And I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "ProgressDeadlineExceeded"
    """
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml"
    Then the step should succeed
    And I replace lines in "myquota.yaml":
      | replicationcontrollers: "30" | replicationcontrollers: "1" |
    When I run the :create admin command with:
      | f | myquota.yaml        |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "ReplicationControllerCreateError"

  # @author yinzhou@redhat.com
  # @case_id OCP-10967
  Scenario: Deployment config with automatic=false in ICT
    #Given the master version >= "3.4"
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/application-template-with-resources.json"
    And I replace lines in "application-template-with-resources.json":
      |"automatic": true|"automatic": false|
    When I process and create "application-template-with-resources.json"
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    And 20 seconds have passed
    When I get project dc named "frontend" as JSON
    And the output should not contain:
      | lastTriggeredImage |
      | "latestVersion": 1 |
    When I run the :deploy client command with:
      | deployment_config | frontend |
      | latest            |          |
    Then the step should fail
    And the output should contain:
      | oc rollout latest |
    When I run the :rollout_latest client command with:
      | resource | frontend |
    Then the step should succeed
    And I wait until the status of deployment "frontend" becomes :complete
    When I get project dc named "frontend" as JSON
    And evaluation of `dc.last_image_for_trigger(user: user, type: 'ImageChange')` is stored in the :imagestreamimage clipboard
    Then the output should contain:
      | lastTriggeredImage     |
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build finishes
    When I get project imagestream named "origin-ruby-sample" as JSON
    And evaluation of `image_stream('origin-ruby-sample').tag_items(user: user)` is stored in the :imagestreamitems clipboard
    And the expression should be true> cb.imagestreamitems.length == 2
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | "latestVersion": 1 |
    And evaluation of `dc.last_image_for_trigger(user: user, type: 'ImageChange')` is stored in the :sed_imagestreamimage clipboard
    And the expression should be true> cb.imagestreamimage == cb.sed_imagestreamimage
    When I run the :deploy client command with:
      | deployment_config | frontend |
      | latest            |          |
    Then the step should succeed
    And I wait until the status of deployment "frontend" becomes :complete
    When I get project dc named "frontend" as JSON
    And evaluation of `dc.last_image_for_trigger(user: user, type: 'ImageChange')` is stored in the :imagestreamimage2 clipboard
    And the expression should be true> cb.imagestreamimage == cb.imagestreamimage2
    When I run the :rollout_latest client command with:
      | resource | frontend |
    Then the step should succeed
    And I wait until the status of deployment "frontend" becomes :complete
    When I get project dc named "frontend" as JSON
    And evaluation of `dc.last_image_for_trigger(user: user, type: 'ImageChange')` is stored in the :imagestreamimage3 clipboard
    And the expression should be true> cb.imagestreamimage != cb.imagestreamimage3

  # @author yinzhou@redhat.com
  # @case_id OCP-11834
  Scenario: Paused deployments shouldn't update the image to template
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    When I process and create "application-template-stibuild.json"
    Then the step should succeed
    When I run the :rollout_pause client command with:
      | resource | dc       |
      | name     | frontend |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | "availableReplicas": 0 |
      | "latestVersion": 0     |


  # @author yinzhou@redhat.com
  # @case_id OCP-14336
  @admin
  Scenario: Show deployment conditions correctly 
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-ignores-deployer.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | database                                 |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "NewReplicationControllerCreated"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/testhook.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "NewReplicationControllerAvailable"
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When  I run the :deploy client command with:
      | deployment_config | hooks |
      | cancel            |       |
    And I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "RolloutCancelled"
    """
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml"
    Then the step should succeed
    And I replace lines in "myquota.yaml":
      | replicationcontrollers: "30" | replicationcontrollers: "1" |
    When I run the :create admin command with:
      | f | myquota.yaml        |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "ReplicationControllerCreateError"


  # @author azagayno@redhat.com
  # @case_id OCP-12217
  Scenario: Proportionally scale - Scale up deployment succeed in unpause and pause
    Given I have a project

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/hello-deployment-1.yaml |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 10 |
      | current   | 10 |
      | updated   | 10 |
      | available | 10 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 10 |
      | current  | 10 |
      | ready    | 10 |

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 20              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 20 |
      | current   | 20 |
      | updated   | 20 |
      | available | 20 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 20 |
      | current  | 20 |
      | ready    | 20 |

    When I run the :patch client command with:
      | resource      | deployment                                                                                                           |
      | resource_name | hello-openshift                                                                                                      |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","image":"docker.io/aosqe/hello-openshift"}]}}}} |
    Then the step should succeed

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 30              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 30 |
      | current   | 30 |
      | updated   | 30 |
      | available | 30 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 30 |
      | current  | 30 |
      | ready    | 30 |

    When I run the :patch client command with:
      | resource      | deployment                                                                                     |
      | resource_name | hello-openshift                                                                                |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","image":"not-exist"}]}}}} |
    Then the step should succeed

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 40              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 40 |
      | current   | 43 |
      | updated   |  7 |
      | available | 36 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 7 |
      | current  | 7 |
      | ready    | 0 |

    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 60              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 60 |
      | current   | 63 |
      | updated   | 10 |
      | available | 53 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 10 |
      | current  | 10 |
      | ready    |  0 |

    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 60 |
      | current   | 63 |
      | updated   | 10 |
      | available | 53 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 10 |
      | current  | 10 |
      | ready    |  0 |

  # @author chuyu@redhat.com
  # @case_id OCP-15167
  Scenario: Pod referencing image streams directly
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15167/example-pod.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-pod" pod is deleted
    When I run the :set_image_lookup client command with:
      | image_stream | app |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15167/example-pod.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-pod |

  # @author chuyu@redhat.com
  # @case_id OCP-15174
  Scenario: Requesting dereference on an entire object for Pod
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15167/example-pod.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-pod" pod is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15167/example-pod-annotation.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-pod |

  # @author chuyu@redhat.com
  # @case_id OCP-15168
  Scenario: Job referencing image streams directly
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15168/example-job.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-job" job is deleted
    When I run the :set_image_lookup client command with:
      | image_stream | app |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15168/example-job.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-job |

  # @author chuyu@redhat.com
  # @case_id OCP-15179
  Scenario: Requesting dereference on an entire object for Job
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15168/example-job.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-job" job is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15168/example-job-annotation.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-job |

  # @author chuyu@redhat.com
  # @case_id OCP-15169
  Scenario: Replicasets referencing image streams directly
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15169/example-rs.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-rs" replicaset is deleted
    When I run the :set_image_lookup client command with:
      | image_stream | app |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15169/example-rs.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-rs |

  # @author chuyu@redhat.com
  # @case_id OCP-15180
  Scenario: Requesting dereference on an entire object for Replicaset
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15169/example-rs.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-rs" replicaset is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15169/example-rs-annotation.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-rs |

  # @author chuyu@redhat.com
  # @case_id OCP-15170
  Scenario: ReplicationController referencing image streams directly
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15170/example-rc.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-rc" replicationcontroller is deleted
    When I run the :set_image_lookup client command with:
      | image_stream | app |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15170/example-rc.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | name=example-rc |

  # @author chuyu@redhat.com
  # @case_id OCP-15181
  Scenario:  Requesting dereference on an entire object for ReplicationController
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15170/example-rc.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-rc" replicationcontroller is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15170/example-rc-annotation.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | name=example-rc |

  # @author chuyu@redhat.com
  # @case_id OCP-15153
  Scenario: Imagestream updates triggering on Kubernetes Deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15153/deployment-example.yaml |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | example:latest                  |
    Then the step should succeed
    When I run the :set_triggers client command with:
      | resource   | deploy/deployment-example |
      | from_image | example:latest            |
      | containers | web                       |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=deployment-example |
    And the expression should be true>  pod.props[:containers][0]['image'] == "openshift/deployment-example@sha256:c505b916f7e5143a356ff961f2c21aee40fbd2cd906c1e3feeb8d5e978da284b"
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v2 |
      | dest        | example:latest                  |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=deployment-example |
    And the expression should be true>  pod.props[:containers][0]['image'] == "openshift/deployment-example@sha256:1318f08b141aa6a4cdca8c09fe8754b6c9f7802f8fc24e4e39ebf93e9d58472b"

  # @author chuyu@redhat.com
  # @case_id OCP-15155
  Scenario: Kubernetes Deployment referencing image streams directly
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :set_image_lookup client command with:
      | image_stream | app |
    Then the step should succeed
    When I run the :run client command with:
      | name      | app                |
      | generator | deployment/v1beta1 |
      | image     | app:v1             |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | run=app |
    And the expression should be true>  pod.props[:containers][0]['image'] == "openshift/deployment-example@sha256:c505b916f7e5143a356ff961f2c21aee40fbd2cd906c1e3feeb8d5e978da284b"
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v2 |
      | dest        | app:v2                          |
    Then the step should succeed
    When I run the :set_image client command with:
      | source    | docker     |
      | type_name | deploy/app |
      | keyval    | app=app:v2 |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | run=app |
    And the expression should be true>  pod.props[:containers][0]['image'] == "openshift/deployment-example@sha256:1318f08b141aa6a4cdca8c09fe8754b6c9f7802f8fc24e4e39ebf93e9d58472b"

  # @author chuyu@redhat.com
  # @case_id OCP-15156
  Scenario: Requesting dereference on an entire object for Kubernetes Deployment
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :run client command with:
      | name      | app                |
      | generator | deployment/v1beta1 |
      | image     | app:v1             |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    When I run the :set_image_lookup client command with:
      | deployment | deployment/app |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deployment                                     |
      | resource_name | app                                            |
      | o             | jsonpath={.spec.template.metadata.annotations} |
    Then the step should succeed
    And the output should match "alpha.image.policy.openshift.io/resolve-names"
    Given status becomes :running of 1 pods labeled:
      | run=app |
